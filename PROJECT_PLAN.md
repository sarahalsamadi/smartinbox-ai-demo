# SmartInbox AI Project Plan

## Overview

SmartInbox AI is a demo application that classifies local email content into four priority buckets:

- Critical
- Normal
- Review
- Ignored

It also generates short summaries for each email. The project is intentionally limited to a local, demo-only workflow. It will not integrate with Gmail, train custom models, or commit dataset files.

## Goals

- Build a FastAPI backend that exposes email ingestion, classification, summarization, and demo data endpoints.
- Build a Flutter frontend that lets a user browse emails by category and inspect generated summaries.
- Use the local Enron Email Dataset as the primary demo email source.
- Keep the Arabic XL-Sum files available locally for later summarization experiments, without adding model training in this phase.
- Maintain a repository structure that separates backend, frontend, local datasets, documentation, tests, and operational configuration.

## Non-Goals

- No Gmail, Outlook, or live mailbox integration.
- No model training or fine-tuning.
- No production authentication, billing, tenant isolation, or deployment hardening.
- No committed dataset files, generated model artifacts, API keys, or local environment files.
- No long-term database requirement unless needed for a later demo phase.

## Architecture

The demo should use a simple client-server architecture:

1. The Flutter app calls the FastAPI backend over HTTP.
2. The backend loads email samples from local dataset files or preprocessed local demo outputs.
3. A classification service assigns each email to one of the supported categories.
4. A summarization service returns a short, user-friendly summary.
5. The API returns structured JSON to the Flutter frontend.

The first implementation can use deterministic rules and lightweight heuristics so the end-to-end experience works before any model integration exists. Later phases can replace those internal services with model-backed implementations without changing the public API contract.

## Backend Plan

The FastAPI backend should be organized around clear service boundaries:

- API routers for HTTP endpoints.
- Schemas for request and response models.
- Services for classification, summarization, and dataset access.
- Core configuration for environment variables and application settings.
- Tests that validate API behavior and service logic.

Recommended initial endpoints:

- `GET /health`
- `GET /emails`
- `GET /emails/{email_id}`
- `POST /emails/classify`
- `POST /emails/summarize`
- `POST /emails/analyze`

The `analyze` endpoint should return both the category and summary for a single email. The list endpoints can support filters such as category, search query, and pagination.

## Frontend Plan

The Flutter frontend should present the demo as an inbox-style application:

- Inbox list with category filters.
- Category counts for Critical, Normal, Review, and Ignored.
- Email detail screen with subject, sender, body preview, category, and summary.
- Manual analysis action for demo emails.
- Clear loading, empty, and error states.

The frontend should communicate only with the FastAPI backend. Dataset parsing and AI-like logic should remain server-side.

## Dataset Strategy

Dataset files must remain local in the `datasets/` directory and must never be committed.

Current local datasets:

- `datasets/emails.csv`
- `datasets/arabic_train.jsonl`
- `datasets/arabic_test.jsonl`
- `datasets/arabic_val.jsonl`

The repository should keep ignoring raw dataset files. If examples are needed later, create tiny synthetic fixtures that do not contain real dataset rows.

## Implementation Phases

### Phase 1: Planning and Repository Setup

- Create project planning documentation.
- Define the intended directory structure.
- Confirm local datasets are excluded by `.gitignore`.
- Establish the first implementation backlog.

### Phase 2: Backend Skeleton

- Create a FastAPI application structure.
- Add health check and basic configuration.
- Define Pydantic schemas for email, classification, summary, and analysis responses.
- Add initial tests for the health endpoint and service boundaries.

### Phase 3: Local Demo Data Pipeline

- Add a local-only dataset loader for Enron email samples.
- Add pagination and basic search/filter behavior.
- Avoid committing dataset-derived outputs unless they are synthetic and tiny.

### Phase 4: Demo Classification and Summarization

- Implement rule-based classification for the four categories.
- Implement simple extractive summaries for demo purposes.
- Add tests for predictable classification and summarization behavior.

### Phase 5: Flutter Demo Interface

- Create the Flutter app structure.
- Implement inbox list, category filters, email detail, and analysis display.
- Connect the app to the FastAPI API.
- Add basic widget tests for key screens.

### Phase 6: Demo Polish

- Improve loading, empty, and error states.
- Add sample screenshots or a short demo guide if needed.
- Validate the app can run locally from a clean clone with datasets supplied separately.

## Risks and Mitigations

- Dataset size may slow local reads. Mitigation: use pagination, sampling, and optional local cache files that remain ignored.
- Real emails may contain sensitive content. Mitigation: do not commit dataset rows or screenshots containing real email bodies.
- Classification quality may be limited without model training. Mitigation: clearly frame rule-based logic as demo behavior and keep service interfaces replaceable.
- Frontend and backend contracts may drift. Mitigation: keep response schemas explicit and add focused API tests.
