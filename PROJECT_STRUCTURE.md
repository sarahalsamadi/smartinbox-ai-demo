# SmartInbox AI Project Structure

## Intended Repository Layout

```text
smartinbox-ai-demo/
  backend/
    app/
      __init__.py
      main.py
      api/
        __init__.py
        routes/
          __init__.py
          health.py
          emails.py
      core/
        __init__.py
        config.py
      schemas/
        __init__.py
        email.py
        analysis.py
      services/
        __init__.py
        classifier.py
        summarizer.py
        dataset_loader.py
      utils/
        __init__.py
        text.py
    tests/
      test_health.py
      test_classifier.py
      test_summarizer.py
    requirements.txt
    README.md

  frontend/
    lib/
      main.dart
      app.dart
      core/
        config.dart
        http_client.dart
      models/
        email.dart
        analysis.dart
      services/
        inbox_api.dart
      screens/
        inbox_screen.dart
        email_detail_screen.dart
      widgets/
        category_filter.dart
        email_list_item.dart
        summary_panel.dart
    test/
      widget_test.dart
    pubspec.yaml
    README.md

  datasets/
    emails.csv
    arabic_train.jsonl
    arabic_test.jsonl
    arabic_val.jsonl

  docs/
    api_contract.md
    demo_runbook.md

  PROJECT_PLAN.md
  PROJECT_STRUCTURE.md
  TASKS.md
  .gitignore
```

## Current Repository Notes

The repository already contains these top-level folders:

- `backend/`
- `frontend/`
- `datasets/`

The dataset files are local-only and ignored by Git. The backend and frontend folders can be expanded in later implementation phases without moving the local datasets.

## Backend Responsibilities

The backend should own:

- Reading local demo emails.
- Normalizing raw email records into API-safe objects.
- Classifying emails as Critical, Normal, Review, or Ignored.
- Producing short summaries.
- Returning stable JSON responses for the Flutter app.

The backend should not own:

- Gmail integration.
- Model training.
- Production user management.
- Committed copies of raw datasets.

## Frontend Responsibilities

The frontend should own:

- Presenting an inbox-style demo experience.
- Calling backend API endpoints.
- Showing category filters and counts.
- Displaying summaries and classification results.
- Handling loading, empty, and error states.

The frontend should not parse raw dataset files directly.

## Dataset Responsibilities

The `datasets/` folder is for local development input only.

Rules:

- Keep raw dataset files out of Git.
- Do not commit `emails.csv`.
- Do not commit Arabic XL-Sum JSONL files.
- Do not commit generated files derived from real dataset rows unless they are explicitly anonymized or synthetic.
- Use tiny synthetic fixtures under backend tests if repeatable tests need sample data.

## Documentation Responsibilities

Planning and coordination documents live at the repository root:

- `PROJECT_PLAN.md`: architecture, goals, non-goals, and phases.
- `PROJECT_STRUCTURE.md`: intended folder layout and ownership boundaries.
- `TASKS.md`: implementation backlog.

Future operational documents can live under `docs/`, such as:

- API contract notes.
- Local setup guide.
- Demo runbook.
