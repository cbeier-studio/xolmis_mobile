# Xolmis Mobile

Xolmis Mobile is designed for fieldwork, enabling researchers and citizen scientists to record ornithological data directly on their mobile devices. Collect ornithological data such as bird lists and counts, nest monitoring and collected specimens. Use it as your digital field notebook.

> [!WARNING]
> This project is in the early stages of development, so expect bugs and breaking changes.

> [!NOTE]
> :dove: _Xolmis_ is a genus of Neotropical passerines. Today it is represented by two species: [_Xolmis irupero_](https://www.wikiaves.com.br/wiki/noivinha) and [_Xolmis velatus_](https://www.wikiaves.com.br/wiki/noivinha-branca).

## Features

Here is a list of the main features:

- [x] Creation of bird lists, without repeating species. Types available:
  - [x] Free Qualitative List.
  - [x] Timed Qualitative List.
  - [x] Interval Qualitative List.
  - [x] Mackinnon List.
  - [x] Transect Count.
  - [x] Point Count.
  - [x] Banding.
  - [x] Casual observation.
- [x] Creation of detection (bird individuals or groups) lists, allowing to repeat species (e.g. using Distance method). Types available:
  - [x] Detection Transect.
  - [x] Detection Point Count.
  - [ ] Spot mapping.
- [x] Use the location services of the device to collect points of interest for species.
- [x] Collect vegetation data (Alianza del Pastizal protocols) within a list.
- [x] Collect weather data within a list.
- [x] Record nests and eggs data.
  - [ ] Record parental care on nests.
- [x] Record specimens collected.
- [x] Export data to CSV, Excel or JSON files.
- [x] Export geographical coordinates to KML file.
- [x] Field journal and notes.
- [ ] Collect quali-quantitative data of captured birds.
- [x] Attach images to the data (vegetation, nests, and specimens).
- [x] Integration with Xolmis desktop (via text files).
- [x] Statistics view.
- [x] Backup and restore data.

## Important project details

- **Local-first app**: Xolmis Mobile stores user data locally in SQLite (`sqflite`), so core field workflows work offline.
- **Five main modules**: inventories, nests, specimens, field journal, and statistics.
- **Image-aware backups**: backups are ZIP-based and include both the database and attached image files.
- **Country-based species data**: autocomplete/checklists are loaded from bundled JSON assets by selected country.
- **Localized interface**: user-facing strings are translated and managed via localization files.

## Xolmis Desktop integration

Xolmis Mobile is designed to interoperate with [**Xolmis Desktop**](https://github.com/cbeier-studio/Xolmis) by exporting/importing structured files.

- Data can be exported from mobile (CSV, Excel, JSON, KML, and feature-specific text files) and consumed in desktop workflows.
- JSON export/import uses a shared envelope structure to keep compatibility across modules and versions.
- Main transferable records include inventories, nests, specimens, and related observations.
- This interoperability allows a practical workflow: collect data in the field with mobile devices, then continue analysis and curation on desktop.

> [!TIP]
> When possible, prefer JSON export/import for richer structure and better long-term compatibility between mobile and desktop projects.

## Data safety and portability

- Use backup/restore regularly to keep database records and linked images synchronized.
- Prefer feature export before large migrations or app reinstallation.
- Keep generated files organized per project/campaign to simplify desktop ingestion.

## Technology stack

- **Flutter**: Cross-platform mobile development framework for iOS and Android.
- **SQLite**: Local database for structured data storage.
- **Dart**: Programming language used in Flutter.
- **GitHub**: Version control and collaboration platform.

## How to contribute

You can create [pull requests](https://github.com/cbeier-studio/xolmis_mobile/pulls) directly and give feedback using the [GitHub Issues](https://github.com/cbeier-studio/xolmis_mobile/issues). All suggestions, bugs reported and general issues are much appreciated.

See the [Developer Wiki](https://github.com/cbeier-studio/xolmis_mobile/wiki) for more details.

## Acknowledgements

Xolmis is developed to support ornithological research, conservation, and citizen science.  
We thank all contributors, institutions, and communities engaged in bird monitoring and ecological studies.
Special thanks to our sponsors!

### Platinum Sponsor

[![Alianza del Pastizal - Platinum Sponsor](/assets/alianza_del_pastizal_logo.png)](http://www.alianzadelpastizal.org.br)