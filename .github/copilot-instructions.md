# Copilot Instructions for Xolmis Mobile

These instructions define how Copilot should work in this repository.

## Priority order
1. Follow direct user request.
2. Follow `AGENTS.md` as the project source of truth.
3. Follow this file for practical execution rules.

## Mandatory workflow
- Read relevant files before editing.
- Keep changes scoped to the requested behavior.
- Reuse existing patterns before creating new abstractions.
- Explain trade-offs when proposing structural changes.

## Architecture guardrails
- Respect layer boundaries: `screens/` -> `providers/` -> `data/daos/` -> `data/models/`.
- Do not access SQLite directly from screens/widgets.
- For schema updates, keep `DatabaseHelper` versioning and migrations aligned.
- For inventory lifecycle changes, review `lib/main_screen.dart` timer resume flow.

## Localization and generated code
- Add new user-visible text to `lib/l10n/*.arb`.
- Regenerate localization output; do not hand-edit files in `lib/generated/`.
- Avoid editing generated or platform build artifacts unless explicitly requested.

## Code style and quality
- Prefer small, composable methods over large procedural blocks.
- Add Dartdoc to new public APIs in providers, services, DAOs, and models.
- Keep naming consistent with existing feature vocabulary.
- Avoid new dependencies unless justified by a clear project need.

## Data integrity and IO
- Preserve export/import envelope compatibility in `lib/utils/export_utils.dart`.
- Keep backup/restore behavior aligned with image file path handling.
- Prefer extending `utils/` helpers rather than duplicating logic in UI files.

## Validation expectations
- Run `flutter analyze`.
- Run focused tests for touched behavior.
- If localization changed, regenerate localization output.
- Mention what was validated and what was not validated.

## Definition of done
- Requested behavior is implemented without regressions in related flows.
- Architecture boundaries are preserved.
- Localization and docs are updated when needed.
- Changes are easy to review and reason about.

