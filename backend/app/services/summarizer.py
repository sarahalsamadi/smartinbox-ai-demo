"""Simple one-line summaries for the SmartInbox AI demo."""

import re

MAX_SUMMARY_LENGTH = 120
SENTENCE_RE = re.compile(r"(?<=[.!?])\s+")
WHITESPACE_RE = re.compile(r"\s+")


def generate_summary(subject: str, body: str) -> str:
    """Generate a concise one-line summary from the first meaningful sentence."""
    clean_body = normalize_whitespace(body)
    clean_subject = normalize_whitespace(subject)

    for sentence in SENTENCE_RE.split(clean_body):
        sentence = normalize_whitespace(sentence)
        if is_meaningful(sentence):
            return truncate(sentence)

    if clean_body:
        return truncate(clean_body)
    if clean_subject:
        return truncate(clean_subject)
    return "No meaningful content found."


def normalize_whitespace(text: str) -> str:
    return WHITESPACE_RE.sub(" ", text or "").strip()


def is_meaningful(sentence: str) -> bool:
    return len(sentence) >= 20 and any(character.isalpha() for character in sentence)


def truncate(text: str, max_length: int = MAX_SUMMARY_LENGTH) -> str:
    text = normalize_whitespace(text)
    if len(text) <= max_length:
        return text
    return text[: max_length - 3].rstrip() + "..."
