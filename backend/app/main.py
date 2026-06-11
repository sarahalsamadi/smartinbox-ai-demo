import json
from pathlib import Path

from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware

from .services.classifier import classify_email
from .services.ml_classifier import (
    classify_email_ml,
    get_model_path,
    get_sklearn_version,
    is_model_loaded,
)
from .services.summarizer import generate_summary, normalize_whitespace

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


def load_emails() -> list[dict[str, object]]:
    if SAMPLE_EMAILS_PATH.exists():
        with SAMPLE_EMAILS_PATH.open("r", encoding="utf-8") as sample_file:
            return json.load(sample_file)
    return MOCK_EMAILS


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