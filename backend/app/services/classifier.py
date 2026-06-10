"""Rule-based email classification for the SmartInbox AI demo."""

IMPORTANT_KEYWORDS = {
    "urgent",
    "asap",
    "immediately",
    "action required",
    "meeting",
    "deadline",
    "approval",
    "password",
    "security",
    "account",
    "contract",
}

IGNORED_KEYWORDS = {
    "newsletter",
    "promotion",
    "advertisement",
    "marketing",
    "unsubscribe",
    "offer",
    "discount",
}


def classify_email(subject: str, body: str) -> dict[str, float | str]:
    """Classify an email into Important, Normal, or Ignored."""
    text = f"{subject or ''} {body or ''}".lower()
    important_hits = sum(1 for keyword in IMPORTANT_KEYWORDS if keyword in text)
    ignored_hits = sum(1 for keyword in IGNORED_KEYWORDS if keyword in text)

    if important_hits > ignored_hits and important_hits > 0:
        return {
            "category": "Important",
            "confidence": round(min(0.98, 0.78 + important_hits * 0.04), 2),
        }

    if ignored_hits > 0:
        return {
            "category": "Ignored",
            "confidence": round(min(0.95, 0.74 + ignored_hits * 0.05), 2),
        }

    return {"category": "Normal", "confidence": 0.66}
