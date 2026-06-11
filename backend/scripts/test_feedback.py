import sys
from pathlib import Path

# Ensure `backend/` is on sys.path so `app` package imports work
repo_root = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(repo_root))

from fastapi.testclient import TestClient
from app.main import app


def run_tests():
    client = TestClient(app)

    print('GET /feedback (initial)')
    r = client.get('/feedback')
    print(r.status_code, r.json())

    print('POST /emails/1/feedback')
    r = client.post('/emails/1/feedback', json={'corrected_category': 'Normal'})
    print(r.status_code, r.json())

    print('GET /feedback (after)')
    r = client.get('/feedback')
    print(r.status_code, r.json())


if __name__ == '__main__':
    run_tests()
