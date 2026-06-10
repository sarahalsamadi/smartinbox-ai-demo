import json
from pathlib import Path

from fastapi import FastAPI

from .services.classifier import classify_email
from .services.summarizer import generate_summary

app = FastAPI(
    title="SmartInbox AI Demo",
    description="Demo backend for mock email classification and summaries.",
    version="0.1.0",
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


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok", "project": "SmartInbox AI Demo"}


@app.get("/emails")
def list_emails() -> list[dict[str, object]]:
    return [enrich_email(email) for email in load_emails()]


@app.get("/stats")
def stats() -> dict[str, int]:
    emails = list_emails()
    return {
        "total": len(emails),
        "important": count_category(emails, "Important"),
        "normal": count_category(emails, "Normal"),
        "ignored": count_category(emails, "Ignored"),
    }


@app.get("/categories")
def categories() -> dict[str, list[str]]:
    return {"categories": CATEGORIES}


def load_emails() -> list[dict[str, object]]:
    if SAMPLE_EMAILS_PATH.exists():
        with SAMPLE_EMAILS_PATH.open("r", encoding="utf-8") as sample_file:
            return json.load(sample_file)
    return MOCK_EMAILS


def enrich_email(email: dict[str, object]) -> dict[str, object]:
    subject = str(email.get("subject") or "")
    body = str(email.get("body") or "")
    classification = classify_email(subject, body)

    return {
        **email,
        "category": classification["category"],
        "confidence": classification["confidence"],
        "summary": generate_summary(subject, body),
    }


def count_category(emails: list[dict[str, object]], category: str) -> int:
    return sum(1 for email in emails if email.get("category") == category)
