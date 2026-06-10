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
sys.path.insert(0, str(BACKEND_ROOT))

from app.services.classifier import classify_email  # noqa: E402
from app.services.summarizer import generate_summary  # noqa: E402

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

HEADER_LINE_RE = re.compile(
    r"^(from|to|cc|bcc|subject|date|sent|received|message-id|mime-version|"
    r"content-type|content-transfer-encoding|x-[\w-]+):",
    re.IGNORECASE,
)
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


def extract_rows() -> list[dict[str, Any]]:
    if not SOURCE_CSV.exists():
        raise FileNotFoundError(f"Dataset not found: {SOURCE_CSV}")

    records = []
    with SOURCE_CSV.open("r", encoding="utf-8", errors="replace", newline="") as csv_file:
        reader = csv.DictReader(csv_file)
        for index, row in enumerate(islice(reader, ROW_LIMIT), start=1):
            raw_message = row.get("message") or row.get("Message") or ""
            sender, subject, body = parse_message(raw_message, row)
            classification = classify_email(subject, body)
            records.append(
                {
                    "id": index,
                    "sender": sender,
                    "subject": subject,
                    "body": body,
                    "category": classification["category"],
                    "confidence": classification["confidence"],
                    "summary": generate_summary(subject, body),
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
