# AGENTS.md

## Quick orientation
- `lib/main.dart` wires the app manually: initialize SQLite (`DatabaseHelper`), construct every DAO/provider, preload species names, then pass everything through `MultiProvider`.
- `lib/main_screen.dart` is the top-level shell. It owns navigation between the five feature areas: inventories, nests, specimens, field journal, and statistics.
- Core persistence is local-first SQLite via `sqflite`; schema lives in `lib/data/database/database_helper.dart` (current DB version: `22`). Most user data is offline and stored locally.

## Architecture that matters
- Feature pattern is `screens/` → `providers/` → `data/daos/` → `data/models/`. Example: `lib/screens/specimen/specimens_screen.dart` uses `SpecimenProvider`, which delegates to `SpecimenDao`, which maps `Specimen` objects to SQLite.
- `Inventory` is the most stateful model. In `lib/data/models/inventory.dart` it owns timer logic, pause/resume bookkeeping, auto-finish rules, and local notifications. Changes to inventory timing usually span model + provider + `main_screen.dart` resume logic.
- Providers are long-lived and injected as values, not recreated per screen. `InventoryProvider.fetchInventories()` intentionally merges DB rows into existing in-memory objects so active timers/notifiers survive refreshes.
- Cross-table imports are transaction-based in DAOs. `InventoryDao.importInventory()` inserts the inventory plus species, POIs, vegetation, and weather in one transaction.
- Images are file-backed plus DB-indexed. The `images` table stores absolute file paths; `backup_utils.dart` zips the DB and those image files together.

## Project-specific conventions
- Localized strings use `S.of(context)` / `S.current` from `lib/generated/l10n.dart`; enums map to user-facing labels in `lib/core/core_consts.dart`.
- Do not hand-edit generated localization files under `lib/generated/` or `lib/generated/intl/`.
- Species autocomplete data is asset-driven, not remote. `loadSpeciesSearchData()` reads `assets/checklists/species_data_<country>.json` based on `SharedPreferences['user_country']`.
- Settings in `lib/screens/settings/settings_screen.dart` drive behavior across the app: observer acronym, country checklist, export number formatting, default durations, reminders, theme.
- Many flows show errors via persistent `SnackBar`s rather than dialogs; preserve that style when extending existing screens.
- Responsive layout uses shared breakpoints from `lib/core/core_consts.dart`: tablet `600`, desktop `840`, side sheet width `360`.

## Import/export and external integrations
- JSON import/export uses a shared envelope from `lib/utils/export_utils.dart`: `{source, schema, schemaVersion, records}` with `source == 'Xolmis Mobile'`.
- Schemas are feature-specific (`inventories`, `nests`, `specimens`). Keep envelope compatibility if you add fields.
- Backup/restore is ZIP-based (`lib/utils/backup_utils.dart`), not just raw DB copy; it must keep image files in sync with DB paths.
- Species taxonomy updates are asset-driven migrations. `lib/services/species_update_service.dart` applies `assets/updates/species_update_<year>.json` on startup when `kCurrentSpeciesUpdateVersion` increases.
- Platform permissions are already declared for notifications, location, camera, and media access in `android/app/src/main/AndroidManifest.xml` and `ios/Runner/Info.plist`.

## Working rules for agents
- Before changing persistence, inspect both `DatabaseHelper._createTables` and `_upgradeTables`; schema changes must update both.
- When touching inventory lifecycle code, also inspect `_resumeAllActiveTimers()` in `lib/main_screen.dart`; foreground/background recovery is part of the feature.
- Prefer extending existing utils (`export_utils.dart`, `import_utils.dart`, `backup_utils.dart`, `utils.dart`) instead of duplicating file/permission/share logic inside screens.
- Preserve the provider/DAO split: screens should not talk to SQLite directly.
- If you add user-facing text, update the ARB files in `lib/l10n/` and regenerate localization output instead of editing generated Dart.

## Validation commands
- Install/refresh deps: `flutter pub get`
- Run static analysis: `flutter analyze`
- Run the existing asset integrity test: `flutter test test/checklists_integrity_test.dart`
- Launch locally: `flutter run`

## Current repo realities
- `flutter analyze` currently reports many pre-existing infos/warnings, including generated localization files and async-context lint noise; do not assume a clean analyzer baseline.
- The most meaningful existing automated check is `test/checklists_integrity_test.dart`, which verifies every supported-country species checklist asset exists and has the expected JSON structure.

