# SmartInbox AI Demo

A lightweight demo that classifies emails, collects user feedback, and supports retraining.

## Project Overview

SmartInbox AI Demo is a demonstration project that showcases:
- A FastAPI backend that serves email data, accepts user feedback, and performs ML retraining.
- A Flutter frontend that displays an inbox UI, lets users correct categories, and shows evaluation metrics.

## Architecture

- Backend: `backend/` (FastAPI, SQLite feedback store, scikit-learn model persisted with joblib)
- Frontend: `frontend/` (Flutter app that consumes the backend API)
- Datasets: `datasets/` (local development fixtures)

## Features

- Rule-based and ML-based email classification
- Summaries for emails
- Persisted user feedback (SQLite)
- Background retraining using feedback
- Evaluation dashboard with confusion matrix and per-class metrics

## Screenshots

Add screenshots to `docs/screenshots/` and update this section with image links. Example images to include:
- Inbox view
- Email detail + feedback actions
- Evaluation dashboard (confusion matrix)

## Installation (Overview)

Prerequisites:
- Python 3.10+ (backend)
- pip
- Flutter SDK (frontend)
- Git

Clone the repo:

```bash
git clone https://github.com/your-org/smartinbox-ai-demo.git
cd smartinbox-ai-demo
```

## Backend Setup

Create a virtual environment and install dependencies, then start the API:

```bash
cd backend
python -m venv .venv
# Windows
.venv\Scripts\activate
# Unix
# source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Notes:
- The first startup initializes a local SQLite database at `backend/data/feedback.db`.
- Retrained models are saved to `backend/ml/models/email_classifier.joblib` and retrain metadata to `backend/data/retrain_meta.json`.

## Frontend Setup

Open the Flutter app and run it (e.g., Chrome for web development):

```bash
cd frontend
flutter pub get
flutter run -d chrome
```

If you run the frontend on a device not hosted at `localhost`, update the API base URL in `frontend/lib/core/api_client.dart`.

## Retraining Workflow

- Users submit corrections in the UI.
- Corrections are persisted to SQLite via the backend `/emails/{id}/feedback` endpoint.
- A developer or user can trigger retraining via the Settings screen (sends `POST /retrain`), which spawns a background process that retrains the ML model using saved feedback.
- Retrain progress is not streamed; status is indicated by `202 Accepted` and the retrain metadata file (`backend/data/retrain_meta.json`) is updated when complete.

## Feedback Workflow

- Feedback is sent from the frontend to the backend (`POST /emails/{id}/feedback`).
- View saved feedback at `GET /feedback` and delete a record with `DELETE /feedback/{id}`.

## Evaluation Dashboard

- The Evaluation screen calls `GET /evaluation` to display:
  - Total samples
  - Accuracy against weak labels
  - Confusion matrix (labels + matrix)
  - Per-class precision/recall/F1/support
  - Feedback count and last retrained timestamp

## API Reference

See `API_REFERENCE.md` for a complete list of endpoints and examples.


---

If anything in this guide is out of date, please open an issue or update the documentation files in the repo.