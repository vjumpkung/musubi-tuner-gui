# Repository Guidelines

## Project Structure & Module Organization

This workspace contains two independent applications (and nested Git repositories):

- `musubi-tuner-gui-frontend/`: React 19, TypeScript, Vite, and Tailwind. Application code lives in `src/`; reusable UI is under `src/components/`, API clients under `src/api/`, hooks under `src/hooks/`, and static files under `public/`.
- `musubi-tuner-gui-backend/`: FastAPI application code in `app/`, pytest coverage in `tests/`, and download helpers in `scripts/`. Runtime state belongs in ignored `data/`. Production frontend assets are generated into ignored `web/`.

Keep API contract changes synchronized across both applications. Consult each subproject's `README.md` and `AGENTS.md` for local details.

## Build, Test, and Development Commands

Run commands from the relevant subproject directory.

- `pnpm install`: install frontend dependencies.
- `pnpm dev`: start Vite; `/api` proxies to `http://127.0.0.1:8000` by default.
- `pnpm build`: type-check and build the frontend into the backend's `web/` directory.
- `pnpm format:check` / `pnpm format`: check or apply Prettier formatting.
- `uv sync --dev`: create the Python environment and install backend development dependencies.
- `uv run uvicorn app.main:app --host 0.0.0.0 --port 8000 --workers 1`: run the API. Keep one worker because the in-process queue runner must not execute jobs twice.
- `uv run pytest`: run the backend test suite.

## Coding Style & Naming Conventions

Frontend code uses four spaces, single quotes, no semicolons, a 100-column limit, and Prettier-managed import/Tailwind ordering. Use PascalCase for React components and camelCase for hooks/functions; retain established lowercase component filenames. Python follows four-space PEP 8 style, snake_case modules/functions, PascalCase classes, type hints, and focused async FastAPI handlers.

## Testing Guidelines

Backend tests use pytest, pytest-asyncio (`asyncio_mode = "auto"`), and HTTPX. Name files `test_<feature>.py` and tests `test_<behavior>`. Add regression tests for API, queue, dataset, or command-building changes. No frontend test runner or coverage threshold is configured; at minimum run `pnpm build` and manually verify changed flows.

## Commit & Pull Request Guidelines

Existing frontend history favors short, imperative subjects; the newest commit uses a Conventional Commit prefix (`feat:`). Prefer `feat:`, `fix:`, `test:`, or `docs:` with a focused subject. Keep frontend and backend commits scoped to their respective repositories. Pull requests should explain behavior and verification, link relevant issues, flag configuration/API changes, and include screenshots for visible UI work. Never commit `.env`, `data/`, `web/`, virtual environments, or `node_modules/`.
