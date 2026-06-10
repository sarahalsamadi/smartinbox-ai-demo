"""Extract a small local Enron sample for the SmartInbox AI demo."""

from __future__ import annotations

import csv
import json
import re
import sys
from email import policy
from email.parser import Parser
from html import unescape
from itertools import islice
from pathlib import Path
from typing import Any


PROJECT_ROOT = Path(__file__).resolve().parents[2]
BACKEND_ROOT = Path(__file__).resolve().parents[1]
SOURCE_CSV = PROJECT_ROOT / "datasets" / "emails.csv"
OUTPUT_JSON = BACKEND_ROOT / "data" / "enron_sample.json"
ROW_LIMIT = 100

MAX_FIELD_SIZE = sys.maxsize
while True:
    try:
        csv.field_size_limit(MAX_FIELD_SIZE)
        break
    except OverflowError:
        MAX_FIELD_SIZE //= 10

IMPORTANT_KEYWORDS = {
    "urgent",
    "asap",
    "immediately",
    "important",
    "deadline",
    "action required",
    "security",
    "password",
    "legal",
    "board",
    "meeting",
    "approval",
    "contract",
}

IGNORED_KEYWORDS = {
    "newsletter",
    "unsubscribe",
    "promotion",
    "promo",
    "offer",
    "discount",
    "marketing",
    "advertisement",
    "click here",
    "subscription",
}

HEADER_LINE_RE = re.compile(
    r"^(from|to|cc|bcc|subject|date|sent|received|message-id|mime-version|"
    r"content-type|content-transfer-encoding|x-[\w-]+):",
    re.IGNORECASE,
)
SENTENCE_RE = re.compile(r"(?<=[.!?])\s+")
TAG_RE = re.compile(r"<[^>]+>")
WHITESPACE_RE = re.compile(r"\s+")


def parse_message(raw_message: str, row: dict[str, str]) -> tuple[str, str, str]:
    """Return sender, subject, and plain text body from an Enron CSV row."""
    message = Parser(policy=policy.default).parsestr(raw_message or "")

    sender = (
        message.get("From")
        or row.get("sender")
        or row.get("from")
        or row.get("From")
        or "unknown@example.com"
    )
    subject = (
        message.get("Subject")
        or row.get("subject")
        or row.get("Subject")
        or "(no subject)"
    )

    body = ""
    if message.is_multipart():
        body_part = message.get_body(preferencelist=("plain",))
        if body_part is not None:
            body = body_part.get_content()
    else:
        payload = message.get_payload(decode=True)
        if isinstance(payload, bytes):
            charset = message.get_content_charset() or "utf-8"
            body = payload.decode(charset, errors="replace")
        else:
            body = str(message.get_payload() or "")

    if not body:
        body = row.get("body") or row.get("Body") or raw_message

    return clean_text(sender), clean_text(subject), clean_body(body)


def clean_body(text: str) -> str:
    text = unescape(text or "")
    text = TAG_RE.sub(" ", text)

    cleaned_lines = []
    for line in text.splitlines():
        stripped = line.strip()
        if not stripped or HEADER_LINE_RE.match(stripped):
            continue
        if stripped.startswith(">"):
            stripped = stripped.lstrip("> ").strip()
        cleaned_lines.append(stripped)

    return clean_text(" ".join(cleaned_lines))


def clean_text(text: str) -> str:
    return WHITESPACE_RE.sub(" ", text or "").strip()


def classify_email(subject: str, body: str) -> tuple[str, float]:
    text = f"{subject} {body}".lower()
    important_hits = sum(1 for keyword in IMPORTANT_KEYWORDS if keyword in text)
    ignored_hits = sum(1 for keyword in IGNORED_KEYWORDS if keyword in text)

    if important_hits > ignored_hits and important_hits > 0:
        return "Important", min(0.98, 0.78 + important_hits * 0.04)
    if ignored_hits > 0:
        return "Ignored", min(0.95, 0.74 + ignored_hits * 0.05)
    return "Normal", 0.66


def summarize(body: str) -> str:
    sentences = SENTENCE_RE.split(body)
    for sentence in sentences:
        sentence = clean_text(sentence)
        if len(sentence) >= 20:
            return truncate(sentence)
    return truncate(body) if body else "No meaningful body text found."


def truncate(text: str, max_length: int = 160) -> str:
    text = clean_text(text)
    if len(text) <= max_length:
        return text
    return text[: max_length - 3].rstrip() + "..."


def extract_rows() -> list[dict[str, Any]]:
    if not SOURCE_CSV.exists():
        raise FileNotFoundError(f"Dataset not found: {SOURCE_CSV}")

    records = []
    with SOURCE_CSV.open("r", encoding="utf-8", errors="replace", newline="") as csv_file:
        reader = csv.DictReader(csv_file)
        for index, row in enumerate(islice(reader, ROW_LIMIT), start=1):
            raw_message = row.get("message") or row.get("Message") or ""
            sender, subject, body = parse_message(raw_message, row)
            category, confidence = classify_email(subject, body)
            records.append(
                {
                    "id": index,
                    "sender": sender,
                    "subject": subject,
                    "body": body,
                    "category": category,
                    "confidence": round(confidence, 2),
                    "summary": summarize(body),
                }
            )

    return records


def main() -> None:
    records = extract_rows()
    OUTPUT_JSON.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT_JSON.write_text(
        json.dumps(records, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    print(f"Wrote {len(records)} records to {OUTPUT_JSON}")


if __name__ == "__main__":
    main()
