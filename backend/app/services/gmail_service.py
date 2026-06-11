import json
import logging
from pathlib import Path
from typing import Optional, Tuple, List

from google_auth_oauthlib.flow import Flow
from google.oauth2.credentials import Credentials
from googleapiclient.discovery import build

from ..services.summarizer import generate_summary
from ..services.ml_classifier import classify_email_ml

logger = logging.getLogger(__name__)

SCOPES = [
    "https://www.googleapis.com/auth/gmail.readonly",
]


def _data_dir() -> Path:
    return Path(__file__).resolve().parents[2] / "data"


def init_gmail_storage() -> None:
    d = _data_dir()
    d.mkdir(parents=True, exist_ok=True)
    tokens = d / "gmail_tokens.json"
    if not tokens.exists():
        tokens.write_text("{}", encoding="utf-8")
    msgs = d / "gmail_messages.json"
    if not msgs.exists():
        msgs.write_text("[]", encoding="utf-8")


def _client_secrets_path() -> Path:
    return _data_dir() / "gmail_client_secret.json"


def _tokens_path() -> Path:
    return _data_dir() / "gmail_tokens.json"


def _messages_path() -> Path:
    return _data_dir() / "gmail_messages.json"


def _read_tokens() -> dict:
    p = _tokens_path()
    try:
        return json.loads(p.read_text(encoding="utf-8") or "{}")
    except Exception:
        return {}


def _write_tokens(data: dict) -> None:
    p = _tokens_path()
    p.write_text(json.dumps(data, indent=2), encoding="utf-8")


def _credentials_from_stored() -> Optional[Credentials]:
    data = _read_tokens()
    if not data:
        return None
    try:
        creds = Credentials(
            token=data.get("token"),
            refresh_token=data.get("refresh_token"),
            token_uri=data.get("token_uri", "https://oauth2.googleapis.com/token"),
            client_id=data.get("client_id"),
            client_secret=data.get("client_secret"),
            scopes=data.get("scopes", SCOPES),
        )
        return creds
    except Exception:
        return None


def get_authorize_url(backend_base: str = "http://localhost:8000") -> Tuple[str, str]:
    """Return (authorization_url, state). Ensure a client secret JSON file exists at data/gmail_client_secret.json."""
    secrets = _client_secrets_path()
    if not secrets.exists():
        raise FileNotFoundError(f"Client secrets not found at {secrets}. Place your OAuth client_secret JSON there.")

    redirect_uri = f"{backend_base.rstrip('/')}/gmail/exchange"
    flow = Flow.from_client_secrets_file(str(secrets), scopes=SCOPES, redirect_uri=redirect_uri)
    auth_url, state = flow.authorization_url(access_type="offline", include_granted_scopes="true")
    # Save state for later verification (optional)
    _write_tokens({**_read_tokens(), "oauth_state": state})
    return auth_url, state


def exchange_code(code: str, backend_base: str = "http://localhost:8000") -> dict:
    secrets = _client_secrets_path()
    if not secrets.exists():
        raise FileNotFoundError("Client secrets missing")
    redirect_uri = f"{backend_base.rstrip('/')}/gmail/exchange"
    flow = Flow.from_client_secrets_file(str(secrets), scopes=SCOPES, redirect_uri=redirect_uri)
    flow.fetch_token(code=code)
    creds: Credentials = flow.credentials
    data = {
        "token": creds.token,
        "refresh_token": creds.refresh_token,
        "token_uri": creds.token_uri,
        "client_id": creds.client_id,
        "client_secret": creds.client_secret,
        "scopes": creds.scopes,
    }
    _write_tokens(data)
    return data


def get_status() -> dict:
    creds = _credentials_from_stored()
    if not creds:
        return {"connected": False}
    try:
        service = build("gmail", "v1", credentials=creds)
        profile = service.users().getProfile(userId="me").execute()
        email = profile.get("emailAddress")
        return {"connected": True, "email": email}
    except Exception as e:
        logger.exception("Failed to get Gmail status: %s", e)
        return {"connected": False, "error": str(e)}


def _load_messages() -> List[dict]:
    p = _messages_path()
    try:
        return json.loads(p.read_text(encoding="utf-8") or "[]")
    except Exception:
        return []


def _write_messages(items: List[dict]) -> None:
    p = _messages_path()
    p.write_text(json.dumps(items, indent=2), encoding="utf-8")


def fetch_and_store_messages(max_results: int = 50) -> dict:
    """Fetch recent Gmail messages and store them to backend/data/gmail_messages.json. Returns summary."""
    creds = _credentials_from_stored()
    if not creds:
        raise RuntimeError("No stored Gmail credentials")
    service = build("gmail", "v1", credentials=creds)
    msgs = []
    try:
        resp = service.users().messages().list(userId="me", maxResults=max_results).execute()
        items = resp.get("messages", [])
        existing = _load_messages()
        existing_by_gid = {m.get("gmail_id"): m for m in existing}
        # determine next local id
        existing_ids = [m.get("id") for m in existing if isinstance(m.get("id"), int)]
        next_id = max(existing_ids) + 1 if existing_ids else 1000

        added = 0
        for it in items:
            gid = it.get("id")
            if gid in existing_by_gid:
                continue
            # fetch full message
            msg = service.users().messages().get(userId="me", id=gid, format="full").execute()
            payload = msg.get("payload", {})
            headers = payload.get("headers", [])
            subject = ""
            sender = ""
            for h in headers:
                name = h.get("name", "")
                if name.lower() == "subject":
                    subject = h.get("value", "")
                if name.lower() == "from":
                    sender = h.get("value", "")

            # attempt to extract body
            body = msg.get("snippet", "")
            # classify and summarize
            try:
                ml = classify_email_ml(subject, body)
                category = ml.get("category")
                confidence = ml.get("confidence")
            except Exception:
                from ..services.classifier import classify_email as simple_classify

                res = simple_classify(subject, body)
                category = res.get("category")
                confidence = res.get("confidence")

            summary = generate_summary(subject, body)

            local = {
                "id": next_id,
                "gmail_id": gid,
                "sender": sender,
                "subject": subject,
                "body": body,
                "category": category,
                "confidence": confidence,
                "summary": summary,
            }
            existing.append(local)
            existing_by_gid[gid] = local
            next_id += 1
            added += 1

        _write_messages(existing)
        return {"fetched": len(items), "added": added}
    except Exception as e:
        logger.exception("Failed to fetch Gmail messages: %s", e)
        raise
