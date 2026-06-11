# API Reference

This document describes the HTTP API provided by the backend service (`backend/app/main.py`). All endpoints return JSON and are served under the server root (e.g., `http://localhost:8000`).

## Health

- Method: GET
- Path: `/health`
- Description: Basic health check.
- Response:

```json
{ "status": "ok", "project": "SmartInbox AI Demo" }
```

## Emails

- Method: GET
- Path: `/emails`
- Query parameters:
  - `category` (optional): filter by category (`Important`, `Normal`, `Ignored`)
  - `search` (optional): case-insensitive substring search over sender, subject, body, summary
  - `classifier` (optional, default `rules`): `rules` or `ml`
  - `limit` (optional): page size (1-100)
  - `offset` (optional): page offset
- Response: paginated list of email list items

- Method: GET
- Path: `/emails/{email_id}`
- Description: Fetch a single email detail object by id.

- Method: POST
- Path: `/emails/{email_id}/feedback`
- Description: Submit a user-corrected category for an email.
- Request body:

```json
{ "corrected_category": "Important" }
```

- Response: the stored feedback record (includes `id`, `email_id`, `predicted_category`, `corrected_category`, `corrected_at`).

## Feedback management

- Method: GET
- Path: `/feedback`
- Description: List saved feedback records.
- Response: `{ "total": N, "items": [...] }`

- Method: DELETE
- Path: `/feedback/{record_id}`
- Description: Delete a saved feedback record by id.
- Response: `{ "deleted": true }`

## Retraining

- Method: POST
- Path: `/retrain`
- Description: Trigger an asynchronous retrain job that loads saved feedback and trains the ML model. Returns `202 Accepted` with `{ "status": "started" }`.

## Stats and categories

- Method: GET
- Path: `/stats`
- Query params: `search` optional
- Description: Returns counts: total, important, normal, ignored.

- Method: GET
- Path: `/categories`
- Description: Returns the list of supported categories.

## Debug / Model info

- Method: GET
- Path: `/debug/model`
- Description: Returns whether a model is loaded, path to the model, and sklearn version.
- Response example:

```json
{
  "model_loaded": true,
  "classifier": "ml",
  "sklearn_version": "1.2.2",
  "model_path": "backend/ml/models/email_classifier.joblib"
}
```

## Evaluation

- Method: GET
- Path: `/evaluation`
- Description: Compute evaluation metrics comparing ML predictions to weak labels in the sample dataset. Response includes:
  - `total_samples`
  - `accuracy_against_weak_labels`
  - `matching_predictions`, `different_predictions`
  - `class_distribution` (counts by ML prediction)
  - `feedback_count`
  - `last_retrained_at`
  - `confusion_matrix`: `{ "labels": [...], "matrix": [[...]] }`
  - `per_class`: mapping category -> { precision, recall, f1, support }

- Method: GET
- Path: `/evaluation/differences`
- Query params: `limit` (optional)
- Description: Return examples where the rule-based and ML predictions differ.
- Response: `{ "total": N, "items": [ { id, sender, subject, preview, rule_category, ml_category, ml_confidence } ] }`

## Gmail Integration (optional)

- Method: GET
- Path: `/gmail/authorize`
- Description: Returns an OAuth2 authorization URL that a user can open to grant the app access to their Gmail inbox. The server expects a redirect URI of the form `http://localhost:8000/gmail/exchange`.
- Response: `{ "url": "https://accounts.google.com/..", "state": "..." }`

- Method: POST
- Path: `/gmail/exchange`
- Description: Exchange an authorization code for OAuth2 tokens and store them server-side. Request body: `{ "code": "<auth-code>" }`.

- Method: GET
- Path: `/gmail/status`
- Description: Returns connection status and account email, e.g. `{ "connected": true, "email": "user@example.com" }`.

- Method: POST
- Path: `/gmail/sync`
- Description: Trigger a background sync to fetch recent Gmail messages and save them to `backend/data/gmail_messages.json`. Returns `202 Accepted` with `{ "status": "started" }`.

- Method: GET
- Path: `/gmail/messages`
- Description: List stored Gmail messages saved locally. Useful for debugging.


## Notes

- All timestamps are ISO-8601 UTC strings.
- Categories are: `Important`, `Normal`, `Ignored`.
- Retrain is implemented as a background process and returns immediately with `202`.

For more implementation details, consult `backend/app/main.py` and the service modules under `backend/app/services/`.
