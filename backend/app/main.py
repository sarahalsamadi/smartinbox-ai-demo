import json
from pathlib import Path

from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from datetime import datetime
import subprocess
import sys
import importlib.util
from .services.feedback_store import init_db, add_feedback as db_add_feedback, list_feedback as db_list_feedback, delete_feedback as db_delete_feedback
# Gmail integration is optional — only import if Google libraries are installed
GMAIL_AVAILABLE = False
GMAIL_DISABLED_REASON = "Gmail integration is not configured in demo mode"
if importlib.util.find_spec("google_auth_oauthlib") and importlib.util.find_spec("googleapiclient"):
    try:
        from .services.gmail_service import (
            init_gmail_storage,
            get_authorize_url,
            exchange_code,
            get_status as gmail_get_status,
            fetch_and_store_messages,
        )
        GMAIL_AVAILABLE = True
    except Exception:
        GMAIL_AVAILABLE = False
else:
    GMAIL_AVAILABLE = False
from fastapi import BackgroundTasks

from .services.classifier import classify_email
from .services.ml_classifier import (
    classify_email_ml,
    get_model_path,
    get_sklearn_version,
    is_model_loaded,
)
from .services.summarizer import generate_summary, normalize_whitespace
from collections import Counter
from sklearn.metrics import confusion_matrix, precision_recall_fscore_support

app = FastAPI(
    title="SmartInbox AI Demo",
    description="Demo backend for mock email classification and summaries.",
    version="0.1.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origin_regex=r"http://localhost:\d+",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

MOCK_EMAILS = [
    {
        "id": 1,
        "sender": "ceo@example.com",
        "subject": "Urgent: board meeting update",
        "body": "Please review the attached agenda before today's board meeting.",
        "category": "Important",
        "confidence": 0.94,
        "summary": "Board meeting agenda requires review today.",
    },
    {
        "id": 2,
        "sender": "team@example.com",
        "subject": "Weekly project notes",
        "body": "Here are the notes from this week's product sync and next steps.",
        "category": "Normal",
        "confidence": 0.82,
        "summary": "Weekly sync notes and next steps shared.",
    },
    {
        "id": 3,
        "sender": "newsletter@example.com",
        "subject": "June productivity newsletter",
        "body": "Read our latest tips, articles, and product updates for June.",
        "category": "Ignored",
        "confidence": 0.88,
        "summary": "General newsletter with June updates.",
    },
    {
        "id": 4,
        "sender": "security@example.com",
        "subject": "Password reset confirmation",
        "body": "Your account password was reset successfully. Contact support if this was not you.",
        "category": "Important",
        "confidence": 0.91,
        "summary": "Password reset confirmation may require attention.",
    },
    {
        "id": 5,
        "sender": "hr@example.com",
        "subject": "Office schedule reminder",
        "body": "This is a reminder about the updated office schedule for next week.",
        "category": "Normal",
        "confidence": 0.79,
        "summary": "Updated office schedule reminder for next week.",
    },
]

SAMPLE_EMAILS_PATH = Path(__file__).resolve().parents[1] / "data" / "enron_sample.json"
CATEGORIES = ["Important", "Normal", "Ignored"]
PREVIEW_MAX_LENGTH = 180


@app.on_event("startup")
def _startup_initialize_db() -> None:
    init_db()
    # initialize gmail storage files only when Gmail integration is available
    if GMAIL_AVAILABLE:
        try:
            init_gmail_storage()
        except Exception:
            pass


class FeedbackPayload(BaseModel):
    corrected_category: str


class GmailCodePayload(BaseModel):
    code: str


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok", "project": "SmartInbox AI Demo"}


@app.get("/emails")
def list_emails(
    category: str | None = None,
    search: str | None = None,
    classifier: str = Query(default="rules", pattern="^(rules|ml)$"),
    limit: int = Query(default=100, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
) -> dict[str, object]:
    emails = filter_emails(
        get_enriched_emails(classifier=classifier),
        category=category,
        search=search,
    )
    emails = sort_emails(emails)
    page_items = emails[offset : offset + limit]

    return {
        "total": len(emails),
        "limit": limit,
        "offset": offset,
        "items": [to_email_list_item(email) for email in page_items],
    }


@app.get("/emails/{email_id}")
def get_email(email_id: int) -> dict[str, object]:
    for email in get_enriched_emails():
        if email.get("id") == email_id:
            return to_email_detail(email)
    raise HTTPException(status_code=404, detail="Email not found")


@app.post("/emails/{email_id}/feedback", status_code=201)
def post_email_feedback(email_id: int, payload: FeedbackPayload) -> dict[str, object]:
    """Store a user-corrected category for an email (in-memory).

    Request body: { "corrected_category": "Important" | "Normal" | "Ignored" }
    """
    corrected = payload.corrected_category
    if corrected not in CATEGORIES:
        allowed = ", ".join(CATEGORIES)
        raise HTTPException(status_code=400, detail=f"Invalid corrected_category. Allowed: {allowed}")

    # Find the email and current predicted category
    predicted = None
    for email in get_enriched_emails():
        if email.get("id") == email_id:
            predicted = email.get("category")
            break
    if predicted is None:
        raise HTTPException(status_code=404, detail="Email not found")

    corrected_at = datetime.utcnow().isoformat() + "Z"
    record = db_add_feedback(email_id, predicted, corrected, corrected_at)
    return record


@app.get("/feedback")
def list_feedback() -> dict[str, object]:
    items = db_list_feedback()
    return {"total": len(items), "items": items}


@app.delete("/feedback/{record_id}")
def delete_feedback(record_id: int) -> dict[str, object]:
    deleted = db_delete_feedback(record_id)
    if not deleted:
        raise HTTPException(status_code=404, detail="Feedback record not found")
    return {"deleted": True}


@app.post("/retrain", status_code=202)
def retrain_model(background_tasks: BackgroundTasks) -> dict[str, object]:
    """Trigger a background retraining job that uses saved feedback to retrain the ML model."""
    # Spawn a separate process to avoid blocking the server
    script_path = Path(__file__).resolve().parents[1] / "ml" / "retrain_with_feedback.py"
    try:
        # Use sys.executable to ensure the same Python interpreter
        subprocess.Popen([sys.executable, str(script_path)], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to start retrain job: {e}")
    return {"status": "started"}


@app.get("/stats")
def stats(search: str | None = None) -> dict[str, int]:
    emails = filter_emails(get_enriched_emails(), search=search)
    return {
        "total": len(emails),
        "important": count_category(emails, "Important"),
        "normal": count_category(emails, "Normal"),
        "ignored": count_category(emails, "Ignored"),
    }


@app.get("/categories")
def categories() -> dict[str, list[str]]:
    return {"categories": CATEGORIES}


@app.get("/debug/model")
def debug_model() -> dict[str, object]:
    return {
        "model_loaded": is_model_loaded(),
        "classifier": "ml",
        "sklearn_version": get_sklearn_version(),
        "model_path": get_model_path(),
    }


@app.get("/gmail/authorize")
def gmail_authorize(backend_base: str | None = None) -> dict[str, object]:
    """Return an authorization URL the user can open to grant access to the demo app."""
    if not GMAIL_AVAILABLE:
        return {"enabled": False, "reason": GMAIL_DISABLED_REASON}
    base = backend_base or "http://localhost:8000"
    try:
        url, state = get_authorize_url(base)
        return {"url": url, "state": state}
    except FileNotFoundError as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/gmail/exchange")
def gmail_exchange(payload: GmailCodePayload) -> dict[str, object]:
    """Exchange an OAuth2 code for tokens and store them server-side."""
    if not GMAIL_AVAILABLE:
        return {"enabled": False, "reason": GMAIL_DISABLED_REASON}
    try:
        data = exchange_code(payload.code)
        return {"status": "ok", "data": data}
    except FileNotFoundError as e:
        raise HTTPException(status_code=500, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to exchange code: {e}")


@app.get("/gmail/status")
def gmail_status() -> dict[str, object]:
    if not GMAIL_AVAILABLE:
        return {"enabled": False, "reason": GMAIL_DISABLED_REASON}
    return gmail_get_status()


@app.post("/gmail/sync", status_code=202)
def gmail_sync(background_tasks: BackgroundTasks, max_results: int = Query(default=50, ge=1, le=500)) -> dict[str, object]:
    """Trigger background sync to fetch recent Gmail messages and store them locally."""
    if not GMAIL_AVAILABLE:
        return {"enabled": False, "reason": GMAIL_DISABLED_REASON}
    try:
        background_tasks.add_task(fetch_and_store_messages, max_results)
        return {"status": "started"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/gmail/messages")
def gmail_messages() -> dict[str, object]:
    if not GMAIL_AVAILABLE:
        return {"enabled": False, "reason": GMAIL_DISABLED_REASON}
    dpath = Path(__file__).resolve().parents[1] / "data" / "gmail_messages.json"
    if not dpath.exists():
        return {"total": 0, "items": []}
    try:
        with dpath.open("r", encoding="utf-8") as f:
            items = json.load(f)
        return {"total": len(items), "items": items}
    except Exception:
        raise HTTPException(status_code=500, detail="Failed to read stored Gmail messages")



@app.get("/evaluation")
def evaluation() -> dict[str, object]:
    """Return evaluation metrics comparing ML predictions to the weak labels in the dataset.

    Metrics:
      - total_samples
      - accuracy_against_weak_labels
      - matching_predictions
      - different_predictions
      - class_distribution (ML predictions)
      - feedback_count
      - last_retrained_at (if available)
    """
    emails = load_emails()
    total = len(emails)
    if total == 0:
        return {
            "total_samples": 0,
            "accuracy_against_weak_labels": 0.0,
            "matching_predictions": 0,
            "different_predictions": 0,
            "class_distribution": {},
            "feedback_count": len(db_list_feedback()),
            "last_retrained_at": None,
        }

    # Collect true labels and ML predictions
    y_true = []
    y_pred = []
    distribution = Counter()
    for item in emails:
        subject = str(item.get("subject") or "")
        body = str(item.get("body") or "")
        weak_label = item.get("category")
        ml_res = classify_email_ml(subject, body)
        ml_cat = ml_res.get("category")
        y_true.append(weak_label)
        y_pred.append(ml_cat)
        distribution[ml_cat] += 1

    # Basic accuracy vs weak labels
    matching = sum(1 for t, p in zip(y_true, y_pred) if t == p)
    different = total - matching
    accuracy = round(matching / total, 4) if total > 0 else 0.0

    # Confusion matrix and per-class precision/recall/f1
    try:
        labels = CATEGORIES
        cm = confusion_matrix(y_true, y_pred, labels=labels).tolist()
        precisions, recalls, f1s, supports = precision_recall_fscore_support(y_true, y_pred, labels=labels, zero_division=0)
        per_class = {}
        for i, lbl in enumerate(labels):
            per_class[lbl] = {
                "precision": round(float(precisions[i]), 4),
                "recall": round(float(recalls[i]), 4),
                "f1": round(float(f1s[i]), 4),
                "support": int(supports[i]),
            }
    except Exception:
        cm = []
        per_class = {}

    # read retrain metadata if available
    meta_path = Path(__file__).resolve().parents[1] / "data" / "retrain_meta.json"
    last_retrained_at = None
    if meta_path.exists():
        try:
            with meta_path.open("r", encoding="utf-8") as mf:
                meta = json.load(mf)
                last_retrained_at = meta.get("last_retrained_at")
        except Exception:
            last_retrained_at = None

    return {
        "total_samples": total,
        "accuracy_against_weak_labels": accuracy,
        "matching_predictions": matching,
        "different_predictions": different,
        "class_distribution": dict(distribution),
        "feedback_count": len(db_list_feedback()),
        "last_retrained_at": last_retrained_at,
        "confusion_matrix": {"labels": CATEGORIES, "matrix": cm},
        "per_class": per_class,
    }


@app.get("/evaluation/differences")
def evaluation_differences(limit: int = 100) -> dict[str, object]:
    """Return examples where rule-based and ML predictions differ.

    Query parameter `limit` caps the number of examples returned.
    """
    emails = load_emails()
    diffs = []
    for item in emails:
        subject = str(item.get("subject") or "")
        body = str(item.get("body") or "")
        rule_res = classify_email(subject, body)
        ml_res = classify_email_ml(subject, body)
        rule_cat = rule_res.get("category")
        ml_cat = ml_res.get("category")
        if rule_cat != ml_cat:
            diffs.append(
                {
                    "id": item.get("id"),
                    "sender": item.get("sender"),
                    "subject": item.get("subject"),
                    "preview": (str(item.get("body") or "")[:160] + "...") if item.get("body") else "",
                    "rule_category": rule_cat,
                    "ml_category": ml_cat,
                    "ml_confidence": ml_res.get("confidence"),
                }
            )
            if len(diffs) >= limit:
                break

    return {"total": len(diffs), "items": diffs}


def load_emails() -> list[dict[str, object]]:
    emails: list[dict[str, object]] = []
    # load stored Gmail messages first (if any)
    gmail_path = Path(__file__).resolve().parents[1] / "data" / "gmail_messages.json"
    if gmail_path.exists():
        try:
            with gmail_path.open("r", encoding="utf-8") as gf:
                gm = json.load(gf)
                if isinstance(gm, list):
                    emails.extend(gm)
        except Exception:
            pass

    # then load sample dataset or fallback mocks
    if SAMPLE_EMAILS_PATH.exists():
        with SAMPLE_EMAILS_PATH.open("r", encoding="utf-8") as sample_file:
            emails.extend(json.load(sample_file))
    else:
        emails.extend(MOCK_EMAILS)

    return emails


def get_enriched_emails(classifier: str = "rules") -> list[dict[str, object]]:
    return [enrich_email(email, classifier=classifier) for email in load_emails()]


def enrich_email(email: dict[str, object], classifier: str = "rules") -> dict[str, object]:
    subject = str(email.get("subject") or "")
    body = str(email.get("body") or "")

    if classifier == "ml":
        classification = classify_email_ml(subject, body)
    else:
        classification = classify_email(subject, body)

    return {
        **email,
        "category": classification["category"],
        "confidence": classification["confidence"],
        "summary": generate_summary(subject, body),
    }


def to_email_list_item(email: dict[str, object]) -> dict[str, object]:
    return {
        "id": email.get("id"),
        "sender": email.get("sender"),
        "subject": email.get("subject"),
        "category": email.get("category"),
        "confidence": email.get("confidence"),
        "summary": email.get("summary"),
        "preview": generate_preview(str(email.get("body") or "")),
    }


def to_email_detail(email: dict[str, object]) -> dict[str, object]:
    return {
        "id": email.get("id"),
        "sender": email.get("sender"),
        "subject": email.get("subject"),
        "body": email.get("body"),
        "category": email.get("category"),
        "confidence": email.get("confidence"),
        "summary": email.get("summary"),
    }


def generate_preview(body: str) -> str:
    preview = normalize_whitespace(body)
    if len(preview) <= PREVIEW_MAX_LENGTH:
        return preview
    return preview[: PREVIEW_MAX_LENGTH - 3].rstrip() + "..."


def filter_emails(
    emails: list[dict[str, object]],
    category: str | None = None,
    search: str | None = None,
) -> list[dict[str, object]]:
    if category is not None and category not in CATEGORIES:
        allowed_values = ", ".join(CATEGORIES)
        raise HTTPException(
            status_code=400,
            detail=f"Invalid category. Allowed values: {allowed_values}",
        )

    filtered = emails

    if category:
        filtered = [email for email in filtered if email.get("category") == category]

    search_text = normalize_search(search)
    if search_text:
        filtered = [email for email in filtered if matches_search(email, search_text)]

    return filtered


def sort_emails(emails: list[dict[str, object]]) -> list[dict[str, object]]:
    priority_order = {
        "Important": 0,
        "Normal": 1,
        "Ignored": 2,
    }

    return sorted(
        emails,
        key=lambda email: (
            priority_order.get(str(email.get("category")), 99),
            -float(email.get("confidence") or 0),
            int(email.get("id") or 0),
        ),
    )


def matches_search(email: dict[str, object], search_text: str) -> bool:
    searchable_fields = ("sender", "subject", "body", "summary")
    return any(search_text in str(email.get(field) or "").lower() for field in searchable_fields)


def normalize_search(search: str | None) -> str:
    return (search or "").strip().lower()


def count_category(emails: list[dict[str, object]], category: str) -> int:
    return sum(1 for email in emails if email.get("category") == category)