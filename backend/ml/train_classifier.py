"""Train a baseline Logistic Regression classifier for email classification."""

import json
from pathlib import Path
import joblib
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import LogisticRegression
from sklearn.pipeline import Pipeline
from sklearn.metrics import classification_report, accuracy_score

# Paths
ML_DIR = Path(__file__).resolve().parent
BACKEND_ROOT = ML_DIR.parent
DATA_PATH = BACKEND_ROOT / "data" / "enron_sample.json"
MODEL_DIR = ML_DIR / "models"
MODEL_PATH = MODEL_DIR / "email_classifier.joblib"

def train() -> None:
    if not DATA_PATH.exists():
        print(f"Error: Dataset not found at {DATA_PATH}")
        print("Please run backend/scripts/extract_enron_sample.py first.")
        return

    print(f"Loading data from {DATA_PATH}...")
    with DATA_PATH.open("r", encoding="utf-8") as f:
        data = json.load(f)

    print(f"Loaded {len(data)} email records.")

    texts = []
    labels = []
    for item in data:
        # Combine subject and body
        subject = item.get("subject", "")
        body = item.get("body", "")
        text = f"{subject}\n{body}"
        texts.append(text)
        labels.append(item.get("category", "Normal"))

    print("Building pipeline (TF-IDF + Logistic Regression)...")
    pipeline = Pipeline([
        ("vectorizer", TfidfVectorizer(stop_words="english", lowercase=True, max_features=1000)),
        ("classifier", LogisticRegression(class_weight="balanced", random_state=42))
    ])

    print("Training model...")
    pipeline.fit(texts, labels)

    # Evaluate on training data
    predictions = pipeline.predict(texts)
    accuracy = accuracy_score(labels, predictions)
    print(f"Training accuracy: {accuracy:.4f}")
    print("\nClassification Report:")
    print(classification_report(labels, predictions))

    # Save the model
    MODEL_DIR.mkdir(parents=True, exist_ok=True)
    print(f"Saving model to {MODEL_PATH}...")
    joblib.dump(pipeline, MODEL_PATH)
    print("Model saved successfully!")

if __name__ == "__main__":
    train()
