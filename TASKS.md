# SmartInbox AI Tasks

## Phase 1: Planning

- [x] Create `PROJECT_PLAN.md`.
- [x] Create `PROJECT_STRUCTURE.md`.
- [x] Create `TASKS.md`.
- [x] Document that datasets are local-only and must not be committed.
- [x] Document that Gmail integration and model training are out of scope for now.

## Phase 2: Backend Foundation

- [ ] Create the FastAPI package under `backend/app/`.
- [ ] Add `backend/app/main.py`.
- [ ] Add a `GET /health` endpoint.
- [ ] Add backend configuration in `backend/app/core/config.py`.
- [ ] Add Pydantic schemas for emails and analysis results.
- [ ] Add backend dependency files such as `requirements.txt`.
- [ ] Add initial backend tests.

## Phase 3: Dataset Access

- [ ] Implement a local Enron CSV loader.
- [ ] Normalize email fields into a clean internal email model.
- [ ] Add pagination for local email browsing.
- [ ] Add basic search and category filter support.
- [ ] Add tiny synthetic fixtures for tests.
- [ ] Confirm no raw dataset rows are committed.

## Phase 4: Demo AI Logic

- [ ] Implement a rule-based classifier for Critical, Normal, Review, and Ignored.
- [ ] Implement a simple summarizer for short summaries.
- [ ] Add an analysis service that combines classification and summarization.
- [ ] Add tests for expected classification behavior.
- [ ] Add tests for summary length and empty-input handling.

## Phase 5: API Endpoints

- [ ] Add `GET /emails`.
- [ ] Add `GET /emails/{email_id}`.
- [ ] Add `POST /emails/classify`.
- [ ] Add `POST /emails/summarize`.
- [ ] Add `POST /emails/analyze`.
- [ ] Document request and response shapes.

## Phase 6: Flutter Foundation

- [ ] Create or initialize the Flutter app under `frontend/`.
- [ ] Add frontend app configuration.
- [ ] Add API client service for the FastAPI backend.
- [ ] Add email and analysis models.
- [ ] Add basic widget tests.

## Phase 7: Flutter Demo Screens

- [ ] Build the inbox list screen.
- [ ] Add category filter controls.
- [ ] Add category counts.
- [ ] Build the email detail screen.
- [ ] Display generated summaries.
- [ ] Display classification labels.
- [ ] Add loading, empty, and error states.

## Phase 8: Local Demo Polish

- [ ] Add backend run instructions.
- [ ] Add frontend run instructions.
- [ ] Add a local demo runbook.
- [ ] Verify a clean clone works when datasets are supplied locally.
- [ ] Review repository status to confirm datasets remain untracked.
