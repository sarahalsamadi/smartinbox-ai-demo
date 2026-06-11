"""Machine Learning-based email classification for the SmartInbox AI demo."""

import logging
from pathlib import Path
import joblib

# Fallback classifier
from .classifier import classify_email

logger = logging.getLogger(__name__)

# Paths
SERVICES_DIR = Path(__file__).resolve().parent
BACKEND_ROOT = SERVICES_DIR.parents[1]
MODEL_PATH = BACKEND_ROOT / "ml" / "models" / "email_classifier.joblib"

# Load the model globally
_MODEL = None
try:
    if MODEL_PATH.exists():
        _MODEL = joblib.load(MODEL_PATH)
        logger.info(f"Loaded ML classifier model from {MODEL_PATH}")
    else:
        logger.warning(f"ML classifier model not found at {MODEL_PATH}. Will fallback to rule-based classification.")
except Exception as e:
    logger.error(f"Failed to load ML classifier model from {MODEL_PATH}: {e}. Will fallback to rule-based classification.")


def classify_email_ml(subject: str, body: str) -> dict[str, float | str]:
    """Classify an email using the trained ML model, falling back to rules if the model is missing."""
    global _MODEL
    
    # Reload attempt if not loaded yet (in case model was generated after server start)
    if _MODEL is None:
        try:
            if MODEL_PATH.exists():
                _MODEL = joblib.load(MODEL_PATH)
                logger.info(f"Loaded ML classifier model dynamically from {MODEL_PATH}")
        except Exception as e:
            logger.error(f"Dynamic model load failed: {e}")

    if _MODEL is None:
        # Fallback to rule-based classification
        return classify_email(subject, body)

    try:
        # Combine subject and body exactly as in training
        text = f"{subject or ''}\n{body or ''}"
        
        # Predict category
        category = _MODEL.predict([text])[0]
        
        # Get probability/confidence
        probabilities = _MODEL.predict_proba([text])[0]
        classes = _MODEL.classes_
        
        # Find index of the predicted class to get its confidence
        class_idx = list(classes).index(category)
        confidence = round(float(probabilities[class_idx]), 2)
        
        return {
            "category": str(category),
            "confidence": confidence,
        }
    except Exception as e:
        logger.error(f"Error during ML classification: {e}. Falling back to rule-based.")
        return classify_email(subject, body)
