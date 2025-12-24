# Changelog

## 1.0.3

### New features

* Added action suggestions when a list is empty (experimental).
* Added action suggestions in the inventory details screen (experimental).
* Added Observer field to inventories, nests, specimens and field journal.

### Improvements

* Refactored and expanded statistics screens.
* Standardized error and warning messages.

### Bug fixes

* Fixed screen going blank after deleting an item.
* Fixed Mackinnon lists not finishing properly.
* Fixed issue that did not save informed values in fields with autocompletion.

## 1.0.2

### New Features

* New types of inventories: detection transect and point count.
* Field journal.
* Statistics view.
* Backup and restore data.
* Export to Excel file (experimental).
* Export inventory POIs to KML file (experimental).
* Add and edit details of an inventory.
* Set an inventory as discarded (experimental).
* Add and edit notes of species' POIs.
* Import inventories, nests or specimens from JSON file.
* Add location coordinates to a journal entry.
* Report screen to compare species between lists.
* Species accumulation chart in inventory details.
* Species accumulation chart for selected inventories.
* Chart comparing the number of species between inventories.
* Now the user can select the country of species search (Argentina, Brazil, Paraguay and Uruguay available, more countries to come).

### Improvements

* Specimens divided into pending and archived categories.
* Setting to disable number formatting when exporting CSV files.
* Configurable reminders to add vegetation and/or weather data when finishing an inventory.
* Sort menus refactored and improved.
* Refactored long press menus to accommodate more options.
* Now the species count is separated in within and outside sample for inventories.
* Species accumulation curve of selected inventories now shows two lines: all accumulated species and species within sample only.
* Changed icon of export options to reflect better their function.
* Set initial individuals count to 1 when a species is added to a quantitative list.
* Do not allow to inactivate a nest without revisions.
* Do not allow to add inventories, nests, or specimens without setting the observer abbreviation.
* Improve screen layout on larger displays.
* Added refresh button to inventories, nests and specimens lists when they are empty.
* About screen refactored, with the addition of sponsors.
* Search bar moved to the screen header.
* Update species names to Clements/eBird taxonomy version 2025.

### Technical/Dependencies

* iOS and iPadOS support.
* Upgraded to Flutter 3.38 and Dart 3.10.
* Migrated `PopupMenuButton` and `showMenu` to `MenuAnchor`.
* Replaced `showSearch` for `SearchAnchor`.
* Removed `workmanager` dependency.

### Bug Fixes

* Fixed issue that were finishing timed inventories unexpectedly.
* The species list of an inventory was not updated properly after adding or removing species.
* The numeric fields now accept only the expected digits and decimal separator.
* Better formatting of exported CSV files.
* Increase precision of coordinates in exported CSV files.
* Enhanced the error treatment when getting location with the device's GPS, giving options to enter coordinates manually or just ignore it.
* Enhanced null check in CSV export.
* Fixed issue that could prevent weather data to be saved.
* Fixed field journal sorting.
* Now inventory locality is correctly saved.
* Fixed inventory import when discarded field is null.
* Fixed inventory ID editing.

## 1.0.1

### New Features

* New type of list: time interval qualitative list.
* Added option to edit species notes.
* Editing records is now possible.
* Added sorting options to lists, nests and specimens.
* Multiselect lists, nests and specimens to export or to delete.
* Added search bars to lists, nests and specimens.
* Attach images from gallery or camera to vegetation, nest revision, egg, and specimen records.
* Tap on individuals count to edit its value in the species list.
* Added option to add a species not found in the species' suggestions lists.
* Added observer abbreviation to the settings and now nests, eggs and specimens generate field numbers.
* Added an option to generate a list ID.
* Export nest and specimens data to CSV.

### Improvements

* Enhanced form validation processes.
* The timer interval for the lists has been increased to conserve resources.
* Reduce the frequency of data loading from the database to conserve resources.
* Preload the list of species names when the application starts.
* Revamped settings screen.
* Changed navigation to a drawer in compact displays.
* The list will show a notification when automatically finished.
* To manage simultaneous lists, settings can be adjusted to limit their number.
* When deleting a species, ask if the user wants to delete it from other active lists.

### Technical/Dependencies

* Revised the method to maintain the app's operation in the background.

### Bug Fixes

* Resolved an issue where tab content was not displayed.
* Corrected a bug that occurred while loading the list of nest revisions.
* Accurate display of eggs and nestlings quantities in the nest revisions list.
* Addressed problems associated with Mackinnon lists.
* Resolved the issue where the elapsed time would not reset upon adding a new species to the list.
* The stopTimer method was called repeatedly when an inventory finished automatically.
* Fixed an issue that prevented to create the POIs table.
* Corrected the method for retrieving the next ID or field number to prevent duplication.
* Resolved an issue where the record ID was not loaded post-insertion.
* Implemented fixes for the dark mode user interface.
* Fixed bug where fields were saved empty in the database.
* Fixed the delete record option not working.
* Fixed other minor bugs.

## 1.0.0

### New Features

* Added banding and casual observation to list types.
* Added weather data input for lists.
* Added nests and nest revisions input.
* Added collected specimens input.
* Added a settings screen and some preference values.
* Added an about screen with licenses info.
* Added options to export all lists and all nests to JSON file.
* Added option to delete the app data in settings.
* Added bottom sheet with options when long pressing an item.
* Adapted to bigger displays.
* Create species lists with or without timer.
* Synchronize species added between active lists.
* Export lists from history.
* Add vegetation data to lists.
* Add points of interest to species.
* Added notification sound when a timer finishes.
* Added more feedback to the user, specially in time consuming tasks.

### Technical/Dependencies

* Refactored code and folders structure.

### Bug Fixes

* Fixed a bug that prevented the species list to update.
* Fixed a bug in species search.
* Fixed a bug that reactivated a finished list after adding a species.
* Fixed some bugs related to the list timer.
* Fixed issue where timer stop after locking the screen.
* The UI is more responsive, fixed bugs that prevented the UI to update.
* Fixed a bug that adds species to active lists when added on a finished list.
* Many UI improvements and bugs fixed.
