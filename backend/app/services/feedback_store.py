import sqlite3
from pathlib import Path
from typing import List, Dict, Any

SERVICES_DIR = Path(__file__).resolve().parent
BACKEND_ROOT = SERVICES_DIR.parents[1]
DATA_DIR = BACKEND_ROOT / "data"
DB_PATH = DATA_DIR / "feedback.db"


def init_db() -> None:
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(DB_PATH)
    try:
        cur = conn.cursor()
        cur.execute(
            """
            CREATE TABLE IF NOT EXISTS feedback (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                email_id INTEGER NOT NULL,
                predicted_category TEXT NOT NULL,
                corrected_category TEXT NOT NULL,
                corrected_at TEXT NOT NULL
            )
            """
        )
        conn.commit()
    finally:
        conn.close()


def add_feedback(email_id: int, predicted_category: str, corrected_category: str, corrected_at: str) -> Dict[str, Any]:
    conn = sqlite3.connect(DB_PATH)
    try:
        cur = conn.cursor()
        cur.execute(
            "INSERT INTO feedback (email_id, predicted_category, corrected_category, corrected_at) VALUES (?, ?, ?, ?)",
            (email_id, predicted_category, corrected_category, corrected_at),
        )
        conn.commit()
        rowid = cur.lastrowid
        cur.execute("SELECT id, email_id, predicted_category, corrected_category, corrected_at FROM feedback WHERE id = ?", (rowid,))
        row = cur.fetchone()
        if row:
            return {
                "id": row[0],
                "email_id": row[1],
                "predicted_category": row[2],
                "corrected_category": row[3],
                "corrected_at": row[4],
            }
        return {}
    finally:
        conn.close()


def list_feedback() -> List[Dict[str, Any]]:
    conn = sqlite3.connect(DB_PATH)
    try:
        cur = conn.cursor()
        cur.execute("SELECT id, email_id, predicted_category, corrected_category, corrected_at FROM feedback ORDER BY id ASC")
        rows = cur.fetchall()
        return [
            {
                "id": r[0],
                "email_id": r[1],
                "predicted_category": r[2],
                "corrected_category": r[3],
                "corrected_at": r[4],
            }
            for r in rows
        ]
    finally:
        conn.close()


def delete_feedback(record_id: int) -> bool:
    conn = sqlite3.connect(DB_PATH)
    try:
        cur = conn.cursor()
        cur.execute("DELETE FROM feedback WHERE id = ?", (record_id,))
        conn.commit()
        return cur.rowcount > 0
    finally:
        conn.close()
