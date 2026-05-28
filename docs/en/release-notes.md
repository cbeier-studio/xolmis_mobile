# Release notes

This section documents the changes, new features, and improvements introduced in each version of **Xolmis Mobile**. Release notes help users understand what has been added, modified, or planned for future updates.

## v1.0 (release date)

Initial release of Xolmis Mobile.

### New features

- Multiple inventory types, including qualitative lists, timed lists, interval lists, Mackinnon lists, banding, transects, point counts, and detection-based methods.  
- Species accumulation charts for individual inventories and for selected inventories.  
- Field Journal module with formatted notes.  
- Nests module with revisions, eggs, images, and automatic field number generation.  
- Specimens module with pending/archived categories and image attachments.  
- Weather and vegetation data entry for inventories.  
- Add and edit species notes, POI notes, and inventory details.  
- Add custom species names not found in the taxonomy list.  
- Multi‑selection for deleting or exporting inventories, nests, and specimens.  
- Filters for inventories, nests, specimens, and field journal entries.  
- Action suggestions when lists or screens are empty (experimental).  
- Option to set the initial module shown at app startup.  
- Backup and restore system for all data and images.  
- Export options: CSV, Excel (experimental), JSON, KML, Plain text (notes), and Markdown (notes).  
- Import inventories, nests, specimens, and notes from JSON.  
- Observer abbreviation required and used to generate IDs and field numbers.  
- Ability to generate inventory IDs automatically.  

### Enhancements

- Major performance improvements across inventories and nests (~90% faster).  
- Refactored statistics screens with new charts and metrics.  
- Improved sorting menus, long‑press menus, and search bars.  
- Highlighting of selected items and first species occurrences in reports.  
- Improved species list behavior, including within/outside sample separation.  
- Better handling of simultaneous inventories and synchronization rules.  
- Improved layout for larger displays and refined About screen with sponsors.  
- Improved CSV formatting, number formatting options, and coordinate precision.  
- Enhanced reminders for missing vegetation or weather data.  
- Preloading species names at startup for faster search.  
- More consistent error and warning messages.  
- Temporary file and database cleanup on app start.
- Updated **[Clements taxonomy](https://www.birds.cornell.edu/clementschecklist/)** to v2025, ensuring alignment with the latest ornithological classification.

### Fixes

- Numerous fixes to timers, including unexpected finishes and reset issues.  
- Corrected species list updates, deletions, and synchronization behavior.  
- Fixed issues with Mackinnon lists, interval lists, and automatic finishing.  
- Resolved problems with saving fields, autocompletion, and null values.  
- Fixed blank screens after deletions and UI update issues.  
- Corrected locality saving, POI table creation, and ID/field number generation.  
- Fixed weather data saving, CSV export null checks, and field journal sorting.  
- Improved GPS error handling with fallback options.  
- Fixed bugs in nest revisions, egg counts, and specimen handling.  
- Numerous UI fixes, including dark mode issues and navigation problems.

### Technical updates

- Updated **Flutter** to v3.44 (development framework).  
- Updated **Dart** to v3.12 (programming language).
- Migrated to new Flutter components (`MenuAnchor`, `SearchAnchor`).  
- Removed deprecated dependencies (e.g., `workmanager`).  
- Refactored internal code structure and background operation methods.  
- Improved database handling, temporary paths, and export/backup consistency.  
- Added iOS/iPadOS support and improved cross‑platform behavior.

## What's next

Planned features for upcoming releases:

- Multi-observer inventories.  
- Bird banding captures and morphometry.  
- Parental care in nests.  
- Spot-mapping method in inventories.  

*[CSV]: Comma Separated Values
*[JSON]: JavaScript Object Notation
*[KML]: Keyhole Markeup Language
*[POI]: Point of Interest
