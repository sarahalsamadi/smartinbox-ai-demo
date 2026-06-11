from pathlib import Path
import sys

# Ensure backend package is importable
repo_root = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(repo_root))

from fastapi.testclient import TestClient
from app.main import app
from app.services.feedback_store import init_db


def run_tests():
    # Ensure DB exists
    init_db()

    with TestClient(app) as client:
        print('GET /feedback (initial)')
        r = client.get('/feedback')
        print(r.status_code, r.json())

        print('POST /emails/1/feedback')
        r = client.post('/emails/1/feedback', json={'corrected_category': 'Important'})
        print(r.status_code, r.json())
        record = r.json()

        print('GET /feedback (after)')
        r = client.get('/feedback')
        print(r.status_code, r.json())

        print('DELETE /feedback/{id}')
        rid = record.get('id')
        if rid:
            r = client.delete(f'/feedback/{rid}')
            print(r.status_code, r.json())

        print('POST /retrain')
        r = client.post('/retrain')
        print(r.status_code, r.json())


if __name__ == '__main__':
    run_tests()
