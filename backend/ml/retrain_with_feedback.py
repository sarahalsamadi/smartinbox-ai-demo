"""Retrain the classifier using the original dataset augmented with user feedback stored in SQLite.

This script reads `backend/data/enron_sample.json` and `backend/data/feedback.db`, applies any
corrected labels from the feedback table (last correction wins), retrains the TF-IDF + LogisticRegression
pipeline, and saves the resulting model to `backend/ml/models/email_classifier.joblib`.
"""

import json
from pathlib import Path
import sqlite3
import joblib
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import LogisticRegression
from sklearn.pipeline import Pipeline
from sklearn.metrics import classification_report, accuracy_score


ML_DIR = Path(__file__).resolve().parent
BACKEND_ROOT = ML_DIR.parent
DATA_PATH = BACKEND_ROOT / "data" / "enron_sample.json"
DB_PATH = BACKEND_ROOT / "data" / "feedback.db"
MODEL_DIR = ML_DIR / "models"
MODEL_PATH = MODEL_DIR / "email_classifier.joblib"


def load_feedback_mapping():
    mapping = {}
    if not DB_PATH.exists():
        return mapping
    conn = sqlite3.connect(DB_PATH)
    try:
        cur = conn.cursor()
        cur.execute("SELECT email_id, corrected_category FROM feedback ORDER BY id ASC")
        rows = cur.fetchall()
        for email_id, corrected in rows:
            mapping[email_id] = corrected
    finally:
        conn.close()
    return mapping


def train():
    if not DATA_PATH.exists():
        print(f"Error: Dataset not found at {DATA_PATH}")
        return

    print(f"Loading data from {DATA_PATH}...")
    with DATA_PATH.open("r", encoding="utf-8") as f:
        data = json.load(f)

    print(f"Loaded {len(data)} email records.")

    feedback_map = load_feedback_mapping()
    if feedback_map:
        print(f"Applying {len(feedback_map)} user corrections from feedback DB.")

    texts = []
    labels = []
    missing_feedback_ids = []
    for item in data:
        email_id = item.get("id")
        subject = item.get("subject", "")
        body = item.get("body", "")
        text = f"{subject}\n{body}"
        texts.append(text)
        if email_id in feedback_map:
            labels.append(feedback_map[email_id])
        else:
            labels.append(item.get("category", "Normal"))

    # Note: feedback entries not present in the dataset are skipped (no text available)

    print("Building pipeline (TF-IDF + Logistic Regression)...")
    pipeline = Pipeline([
        ("vectorizer", TfidfVectorizer(stop_words="english", lowercase=True, max_features=1000)),
        ("classifier", LogisticRegression(class_weight="balanced", random_state=42))
    ])

    print("Training model with augmented labels...")
    pipeline.fit(texts, labels)

    # Evaluate on training data
    predictions = pipeline.predict(texts)
    accuracy = accuracy_score(labels, predictions)
    print(f"Training accuracy: {accuracy:.4f}")
    print("\nClassification Report:")
    print(classification_report(labels, predictions))

    MODEL_DIR.mkdir(parents=True, exist_ok=True)
    print(f"Saving model to {MODEL_PATH}...")
    joblib.dump(pipeline, MODEL_PATH)
    print("Model saved successfully!")


if __name__ == "__main__":
    train()
