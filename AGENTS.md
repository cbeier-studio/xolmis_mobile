# AGENTS.md

This file is the authoritative implementation guide for AI agents and contributors working in Xolmis Mobile.

## Mission and scope
- Preserve existing behavior first, then extend features.
- Keep the app local-first and offline-friendly.
- Prefer small, reviewable changes over broad refactors.
- Never rewrite architecture layers unless explicitly requested.

## Quick orientation
- `lib/main.dart` wires the app manually: initialize SQLite (`DatabaseHelper`), construct every DAO/provider, preload species names, then pass everything through `MultiProvider`.
- `lib/main_screen.dart` is the top-level shell. It owns navigation between the five feature areas: inventories, nests, specimens, field journal, and statistics.
- Core persistence is local-first SQLite via `sqflite`; schema lives in `lib/data/database/database_helper.dart` (current DB version: `23`). Most user data is offline and stored locally.

## Architecture that matters
- Feature pattern is `screens/` -> `providers/` -> `data/daos/` -> `data/models/`.
- Preserve layer boundaries:
  - screens/widgets: UI composition and user interaction.
  - providers: state orchestration and use-case flow.
  - daos: SQL and transaction boundaries.
  - models: domain data and model-specific logic.
- `Inventory` is the most stateful model. In `lib/data/models/inventory.dart` it owns timer logic, pause/resume bookkeeping, auto-finish rules, and local notifications. Changes to inventory timing usually span model + provider + `main_screen.dart` resume logic.
- Providers are long-lived and injected as values, not recreated per screen. `InventoryProvider.fetchInventories()` intentionally merges DB rows into existing in-memory objects so active timers/notifiers survive refreshes.
- Cross-table imports are transaction-based in DAOs. `InventoryDao.importInventory()` inserts the inventory plus species, POIs, vegetation, and weather in one transaction.
- Images are file-backed plus DB-indexed. The `images` table stores absolute file paths; `backup_utils.dart` zips the DB and those image files together.

## Project-specific conventions
- Localized strings use `S.of(context)` from `lib/generated/l10n.dart`; enums map to user-facing labels in `lib/core/core_consts.dart`.
- Do not hand-edit generated localization files under `lib/generated/`.
- Species autocomplete data is asset-driven, not remote. `loadSpeciesSearchData()` reads `assets/checklists/species_data_<country>.json` based on `SharedPreferences['user_country']`.
- Settings in `lib/screens/settings/settings_screen.dart` drive behavior across the app: observer initials, startup module (`kStartupModulePreferenceKey`), country checklist, export number formatting, default durations, reminders, theme.
- Field journal notes are rich-text Delta JSON strings (Fleather), not plain text. `AddJournalScreen` serializes notes with `jsonEncode(_notesController.document.toDelta().toList())`; editing paths decode via `ParchmentDocument.fromJson(...)`.
- Many flows show errors via persistent `SnackBar`s rather than dialogs; preserve that style when extending existing screens.
- Responsive layout uses shared breakpoints from `lib/core/core_consts.dart`: tablet `600`, desktop `840`, side sheet width `360`.

## Import/export and external integrations
- JSON import/export uses a shared envelope from `lib/utils/export_utils.dart`: `{source, schema, schemaVersion, records}` with `source == 'Xolmis Mobile'`.
- Schemas are feature-specific (`inventories`, `nests`, `specimens`). Keep envelope compatibility if you add fields.
- Backup/restore is ZIP-based (`lib/utils/backup_utils.dart`), not just raw DB copy; it must keep image files in sync with DB paths.
- Species taxonomy updates are asset-driven migrations. `lib/services/species_update_service.dart` applies `assets/updates/species_update_<year>.json` on startup when `kCurrentSpeciesUpdateVersion` increases.
- Platform permissions are already declared for notifications, location, camera, and media access in `android/app/src/main/AndroidManifest.xml` and `ios/Runner/Info.plist`.

## Working rules for agents

### 1) Before coding
- Read this file and the affected feature files end-to-end before editing.
- Search for existing utility/service/provider code before introducing new abstractions.
- If requirement is ambiguous, ask for clarification instead of guessing behavior.

### 2) During implementation
- Preserve the provider/DAO split: screens must not talk to SQLite directly.
- Before changing persistence, inspect `DatabaseHelper._createTables`, `_upgradeTables`, and `_createPerformanceIndexes`; schema/index changes must stay aligned with DB versioning and migrations.
- When touching inventory lifecycle code, also inspect `_resumeAllActiveTimers()` in `lib/main_screen.dart`; foreground/background recovery is part of the feature.
- Prefer extending existing utils (`export_utils.dart`, `import_utils.dart`, `backup_utils.dart`, `utils.dart`) instead of duplicating file/permission/share logic inside screens.
- Keep public method signatures stable unless change is explicitly requested.
- Add Dartdoc to new public classes and methods, especially in models, providers, services, and DAOs.

### 3) Localization and text
- Any new user-visible text must be added to `lib/l10n/*.arb`.
- Regenerate localization output after ARB changes; never hand-edit `lib/generated/`.
- Reuse existing wording style (short, clear, action-oriented labels and messages).

### 4) Documentation
- Code documentation written in **English** using Dart documentation comments.
- Substantial changes and bug fixes should be written in the `[Unreleased]` section of `CHANGELOG.md` file.

### 5) UI and UX consistency
- Reuse existing spacing, typography, and widgets where possible.
- Prefer persistent `SnackBar` for recoverable errors unless the existing flow uses dialogs.
- Keep responsive behavior aligned with breakpoints in `lib/core/core_consts.dart`.

### 6) Safety constraints
- Do not add new runtime dependencies without clear necessity.
- Do not commit secrets, absolute machine-specific paths, or temporary debug code.
- Do not modify generated artifacts unless regeneration is part of the task.

## Definition of done for AI-generated changes
- Behavior matches requested scope and does not silently alter unrelated flows.
- Database migrations are consistent and reversible by app update path.
- New strings are localized via ARB and generated localization is updated.
- Tests are added or updated when behavior changes.
- Static analysis and targeted tests were executed and results reviewed.
- Documentation was updated when introducing new conventions or flows.

## Validation commands
- Install/refresh deps: `flutter pub get`
- Run static analysis: `flutter analyze`
- Run checklist integrity test when related files were touched by your change: `flutter test test/checklists_integrity_test.dart`
- Run utils tests when modifying `lib/utils/`: `flutter test test/utils/utils_methods_test.dart`
- Run widget or feature tests touched by your change.
- Launch locally: `flutter run`
- Generate localization output after ARB changes: `flutter gen-l10n`

## Current repo realities
- `flutter analyze` currently reports many pre-existing infos/warnings, including generated localization files and async-context lint noise; do not assume a clean analyzer baseline.
- The supported-country species checklist automated check is `test/checklists_integrity_test.dart`, which verifies every checklist asset exists and has the expected JSON structure.
- The utils test suite in `test/utils/utils_methods_test.dart` covers species name matching, string formatting, and statistics logic.

