# SmartInbox AI Demo Backend

FastAPI backend for the SmartInbox AI demo.

## Scope

This phase provides only:

- `GET /health`
- `GET /emails`
- Five mock email records

It does not read datasets, use Gmail APIs, train models, or connect to a database.

## Categories

The backend returns only these category values:

| API value | Arabic label |
| --- | --- |
| Important | مهم |
| Normal | عادي |
| Ignored | مهمل |

The `Review` category is intentionally not used in this phase.

## Run Locally

```bash
pip install -r requirements.txt
uvicorn app.main:app --reload
```

The API will be available at `http://127.0.0.1:8000`.

## Endpoints

### `GET /health`

Returns:

```json
{"status": "ok", "project": "SmartInbox AI Demo"}
```

### `GET /emails`

Returns five mock email records with:

- `id`
- `sender`
- `subject`
- `body`
- `category`
- `confidence`
- `summary`
