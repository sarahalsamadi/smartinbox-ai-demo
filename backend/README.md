# SmartInbox AI Demo Backend

FastAPI backend for the SmartInbox AI demo.

## Scope

This phase provides:

- `GET /health`
- `GET /emails` supporting rules-based and ML-based classification.
- Ingestion of local email samples (`backend/data/enron_sample.json`).
- Baseline ML Classifier training pipeline (TF-IDF + Logistic Regression).
- Automated fallback to rules-based classifier if the ML model artifact is missing.

It does not integrate with live Gmail APIs, train deep learning models, or connect to a production database.

## Categories

The backend returns only these category values:

| API value | Arabic label |
| --- | --- |
| Important | مهم |
| Normal | عادي |
| Ignored | مهمل |

The `Review` category is intentionally not used in this phase.

## Run Locally

### 1. Install Dependencies
```bash
pip install -r requirements.txt
```

### 2. Train the ML Classifier (Optional)
To train the baseline Logistic Regression model on the local sample dataset:
```bash
python ml/train_classifier.py
```
This will fit the classifier and save the model pipeline to `backend/ml/models/email_classifier.joblib`.

### 3. Run FastAPI server
```bash
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

Returns email records with:

- `id`
- `sender`
- `subject`
- `body`
- `category`
- `confidence`
- `summary`

**Query Parameters:**

- `classifier`: Select between classification models. Options: `rules` or `ml` (default: `rules`).
  - `rules`: Keyword-based rules classifier.
  - `ml`: Baseline Logistic Regression model. If the trained model file is not found, the system falls back to rules-based predictions automatically.
- `category`: Filter emails by category (`Important`, `Normal`, `Ignored`).
- `search`: Filter emails by a text search query matching sender, subject, body, or summary.
- `limit`: Maximum number of records to return (default: `100`).
- `offset`: Number of records to skip (default: `0`).

### `GET /debug/model`

Returns the loading status and metadata of the machine learning classifier model:

```json
{
  "model_loaded": true,
  "classifier": "ml",
  "sklearn_version": "1.7.1",
  "model_path": "C:\\Users\\PYTHONIST\\Documents\\My_Github\\smartinbox-ai-demo\\backend\\ml\\models\\email_classifier.joblib"
}
```

