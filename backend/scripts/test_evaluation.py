from pathlib import Path
import sys

# Ensure backend package is importable
repo_root = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(repo_root))

from fastapi.testclient import TestClient
from app.main import app
from app.services.feedback_store import init_db, add_feedback


def run_tests():
    init_db()
    client = TestClient(app)

    print('GET /evaluation')
    r = client.get('/evaluation')
    print(r.status_code)
    print(r.json())

    print('GET /evaluation/differences')
    r = client.get('/evaluation/differences')
    print(r.status_code)
    print(r.json())

    # Add feedback and re-run evaluation to ensure feedback_count updates
    print('POST /emails/1/feedback')
    r = client.post('/emails/1/feedback', json={'corrected_category': 'Ignored'})
    print(r.status_code, r.json())

    print('GET /evaluation (after feedback)')
    r = client.get('/evaluation')
    print(r.status_code)
    print(r.json())


if __name__ == '__main__':
    run_tests()
