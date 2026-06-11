"""Machine Learning-based email classification for the SmartInbox AI demo."""

import logging
from pathlib import Path
import joblib
import sklearn

# Fallback classifier
from .classifier import classify_email

logger = logging.getLogger(__name__)

# Paths
SERVICES_DIR = Path(__file__).resolve().parent
BACKEND_ROOT = SERVICES_DIR.parents[1]
MODEL_PATH = BACKEND_ROOT / "ml" / "models" / "email_classifier.joblib"

# Load the model globally
_MODEL = None


def _load_model_if_needed() -> None:
    """Load the model pipeline dynamically if it is not already loaded."""
    global _MODEL
    if _MODEL is None:
        try:
            if MODEL_PATH.exists():
                _MODEL = joblib.load(MODEL_PATH)
                logger.info(f"Successfully loaded ML classifier model from {MODEL_PATH} (sklearn version: {sklearn.__version__})")
        except Exception as e:
            logger.error(f"Failed to load ML classifier model from {MODEL_PATH}: {e} (current sklearn version: {sklearn.__version__})")


# Run initial load attempt on module import
_load_model_if_needed()


def classify_email_ml(subject: str, body: str) -> dict[str, float | str]:
    """Classify an email using the trained ML model, falling back to rules if the model is missing."""
    _load_model_if_needed()

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


def is_model_loaded() -> bool:
    """Return True if the ML model is successfully loaded."""
    _load_model_if_needed()
    return _MODEL is not None


def get_sklearn_version() -> str:
    """Return the installed version of scikit-learn."""
    return sklearn.__version__


def get_model_path() -> str:
    """Return the path to the model file."""
    return str(MODEL_PATH)
