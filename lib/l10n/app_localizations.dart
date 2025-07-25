import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('pt'),
    Locale('pt', 'BR'),
  ];

  /// No description provided for @inventories.
  ///
  /// In en, this message translates to:
  /// **'Inventories'**
  String get inventories;

  /// No description provided for @nests.
  ///
  /// In en, this message translates to:
  /// **'Nests'**
  String get nests;

  /// Titles and messages about specimens
  ///
  /// In en, this message translates to:
  /// **'{howMany, plural, one{Specimen} other{Specimens}}'**
  String specimens(int howMany);

  /// Field journal option in navigation drawer
  ///
  /// In en, this message translates to:
  /// **'Field journal'**
  String get fieldJournal;

  /// Titles and messages about field journal entries
  ///
  /// In en, this message translates to:
  /// **'{howMany, plural, one{Journal entry} other{Journal entries}}'**
  String journalEntries(int howMany);

  /// Settings title and button label
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// General section in settings
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// Appearance option in settings
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// Title of dialog to select the app mode
  ///
  /// In en, this message translates to:
  /// **'Select the mode'**
  String get selectMode;

  /// Light mode name
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get lightMode;

  /// Dark mode name
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get darkMode;

  /// System theme name
  ///
  /// In en, this message translates to:
  /// **'System theme'**
  String get systemMode;

  /// Observer option in settings
  ///
  /// In en, this message translates to:
  /// **'Observer (abbreviation)'**
  String get observerSetting;

  /// Title of dialog to inform observer abbreviation
  ///
  /// In en, this message translates to:
  /// **'Observer'**
  String get observer;

  /// Label of text field to inform observer abbreviation
  ///
  /// In en, this message translates to:
  /// **'Observer abbreviation'**
  String get observerAbbreviation;

  /// Cancel button label
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Save button label
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Simultaneous inventories option in settings
  ///
  /// In en, this message translates to:
  /// **'Simultaneous inventories'**
  String get simultaneousInventories;

  /// Titles and messages about inventories
  ///
  /// In en, this message translates to:
  /// **'{howMany, plural, one{inventory} other{inventories}}'**
  String inventory(int howMany);

  /// Message showing how many inventories were found
  ///
  /// In en, this message translates to:
  /// **'{howMany, plural, one{inventory found} other{inventories found}}'**
  String inventoryFound(int howMany);

  /// Mackinnon lists option in settings
  ///
  /// In en, this message translates to:
  /// **'Mackinnon lists'**
  String get mackinnonLists;

  /// How many species per list in settings screen
  ///
  /// In en, this message translates to:
  /// **'{howMany, plural, one{1 species} other{{howMany} species}} per list'**
  String speciesPerList(int howMany);

  /// Title of dialog to inform the number of species per Mackinnon list
  ///
  /// In en, this message translates to:
  /// **'Species per list'**
  String get speciesPerListTitle;

  /// Point counts option in settings
  ///
  /// In en, this message translates to:
  /// **'Point counts'**
  String get pointCounts;

  /// Title of dialog to inform inventory duration in minutes
  ///
  /// In en, this message translates to:
  /// **'Duration (min)'**
  String get durationMin;

  /// Time duration in minutes in settings screen
  ///
  /// In en, this message translates to:
  /// **'{howMany, plural, one{1 minute} other{{howMany} minutes}} of duration'**
  String inventoryDuration(int howMany);

  /// Timed qualitative lists option in settings
  ///
  /// In en, this message translates to:
  /// **'Timed qualitative lists'**
  String get timedQualitativeLists;

  /// Interval qualitative lists option in settings
  ///
  /// In en, this message translates to:
  /// **'Interval qualitative lists'**
  String get intervaledQualitativeLists;

  /// Format numbers option in settings
  ///
  /// In en, this message translates to:
  /// **'Format numbers'**
  String get formatNumbers;

  /// About the app option in settings
  ///
  /// In en, this message translates to:
  /// **'About the app'**
  String get about;

  /// Danger zone in settings
  ///
  /// In en, this message translates to:
  /// **'Danger zone'**
  String get dangerZone;

  /// Delete app data option in settings
  ///
  /// In en, this message translates to:
  /// **'Delete the app data'**
  String get deleteAppData;

  /// Description of the action to delete all app data
  ///
  /// In en, this message translates to:
  /// **'All data will be erased. Use with caution! This action cannot be undone.'**
  String get deleteAppDataDescription;

  /// Title of dialog to confirm app data deletion
  ///
  /// In en, this message translates to:
  /// **'Delete data'**
  String get deleteData;

  /// Message asking user for confirmation before delete all app data
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete all app data? This action cannot be undone.'**
  String get deleteDataMessage;

  /// Delete button label
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Message informing user that the data was successfully deleted
  ///
  /// In en, this message translates to:
  /// **'App data deleted successfully!'**
  String get dataDeleted;

  /// OK button label
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// Message shown when the limit of simultaneous inventories defined in settings is reached
  ///
  /// In en, this message translates to:
  /// **'Limit of simultaneous inventories reached.'**
  String get simultaneousLimitReached;

  /// Sort by time option in inventories list
  ///
  /// In en, this message translates to:
  /// **'Sort by Time'**
  String get sortByTime;

  /// Sort by name option in inventories list
  ///
  /// In en, this message translates to:
  /// **'Sort by Name'**
  String get sortByName;

  /// Sort ascending option in inventories list
  ///
  /// In en, this message translates to:
  /// **'Sort ascending'**
  String get sortAscending;

  /// Sort descending option in inventories list
  ///
  /// In en, this message translates to:
  /// **'Sort descending'**
  String get sortDescending;

  /// Hint text in inventories search field
  ///
  /// In en, this message translates to:
  /// **'Find inventories...'**
  String get findInventories;

  /// Segmented button label to filter for active inventories or nests
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// Segmented button label to filter for finished inventories
  ///
  /// In en, this message translates to:
  /// **'Finished'**
  String get finished;

  /// Text shown when no inventories found
  ///
  /// In en, this message translates to:
  /// **'No inventories found.'**
  String get noInventoriesFound;

  /// Delete inventory option in bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Delete inventory'**
  String get deleteInventory;

  /// Title of dialog for confirm record deletion
  ///
  /// In en, this message translates to:
  /// **'Confirm delete'**
  String get confirmDelete;

  /// Message asking user confirmation to delete record
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {howMany, plural, one{{gender, select, male{this} female{this} other{this}}} other{{gender, select, male{these} female{these} other{these}}}} {what}?'**
  String confirmDeleteMessage(int howMany, String gender, String what);

  /// Title of dialog to confirm finishing an inventory
  ///
  /// In en, this message translates to:
  /// **'Confirm finish'**
  String get confirmFinish;

  /// Message asking confirmation to finish an inventory
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to finish this inventory?'**
  String get confirmFinishMessage;

  /// Message asking confirmation to finish an inventory automatically
  ///
  /// In en, this message translates to:
  /// **'Inventory automatically finished. Do you want to keep active or finish this inventory?'**
  String get confirmAutoFinishMessage;

  /// Finish button label
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finish;

  /// Keep running button label
  ///
  /// In en, this message translates to:
  /// **'Keep active'**
  String get keepRunning;

  /// Title of dialog when adding new inventory
  ///
  /// In en, this message translates to:
  /// **'New inventory'**
  String get newInventory;

  /// How many species the inventory have
  ///
  /// In en, this message translates to:
  /// **'{howMany, plural, zero{species} one{species} other{species}}'**
  String speciesCount(int howMany);

  /// Pause button hint
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// Resume button hint
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// Export button hint
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get export;

  /// Menu option to export one record
  ///
  /// In en, this message translates to:
  /// **'Export {what}'**
  String exportWhat(String what);

  /// Export all button hint
  ///
  /// In en, this message translates to:
  /// **'Export all'**
  String get exportAll;

  /// Menu option to export all records
  ///
  /// In en, this message translates to:
  /// **'Export all {what}'**
  String exportAllWhat(String what);

  /// Menu option to finish the inventory
  ///
  /// In en, this message translates to:
  /// **'Finish inventory'**
  String get finishInventory;

  /// Auxiliary label informing that the field is required
  ///
  /// In en, this message translates to:
  /// **'* required'**
  String get requiredField;

  /// Inventory type field label
  ///
  /// In en, this message translates to:
  /// **'Inventory type'**
  String get inventoryType;

  /// Validation message shown when the inventory type field is empty
  ///
  /// In en, this message translates to:
  /// **'Please, select an inventory type'**
  String get selectInventoryType;

  /// Inventory ID field label
  ///
  /// In en, this message translates to:
  /// **'Inventory ID'**
  String get inventoryId;

  /// Title of dialog to generate an inventory ID
  ///
  /// In en, this message translates to:
  /// **'Generate ID'**
  String get generateId;

  /// Field label asking the inventory site name or abbreviation to generate the ID
  ///
  /// In en, this message translates to:
  /// **'Site name or abbreviation'**
  String get siteAbbreviation;

  /// Auxiliary label informing that the field is optional
  ///
  /// In en, this message translates to:
  /// **'* optional'**
  String get optional;

  /// Validation message shown when the inventory ID is empty
  ///
  /// In en, this message translates to:
  /// **'Please, insert an ID for the inventory'**
  String get insertInventoryId;

  /// Time duration field label
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// Field suffix and messages containing duration of time
  ///
  /// In en, this message translates to:
  /// **'{howMany, plural, one{minute} other{minutes}}'**
  String minutes(int howMany);

  /// Validation message shown when duration is empty
  ///
  /// In en, this message translates to:
  /// **'Insert a duration'**
  String get insertDuration;

  /// Max number of species field label
  ///
  /// In en, this message translates to:
  /// **'Max species'**
  String get maxSpecies;

  /// Validation message shown when the max of species field is empty
  ///
  /// In en, this message translates to:
  /// **'Insert the max of species'**
  String get insertMaxSpecies;

  /// Validation message shown when the max of species is lower than five
  ///
  /// In en, this message translates to:
  /// **'Must be equal or higher than 5'**
  String get mustBeBiggerThanFive;

  /// Start inventory button label
  ///
  /// In en, this message translates to:
  /// **'Start inventory'**
  String get startInventory;

  /// Message shown when the informed inventory ID already exists
  ///
  /// In en, this message translates to:
  /// **'This inventory ID already exists.'**
  String get inventoryIdAlreadyExists;

  /// Message shown if an error occurred while inserting an inventory
  ///
  /// In en, this message translates to:
  /// **'Error inserting inventory'**
  String get errorInsertingInventory;

  /// Title of report option to show species by inventory
  ///
  /// In en, this message translates to:
  /// **'Species by inventory'**
  String get reportSpeciesByInventory;

  /// Total species field label
  ///
  /// In en, this message translates to:
  /// **'Total Species'**
  String get totalSpecies;

  /// Total individuals field label
  ///
  /// In en, this message translates to:
  /// **'Total Individuals'**
  String get totalIndividuals;

  /// Title of report option to show species accumulation curve
  ///
  /// In en, this message translates to:
  /// **'Species accumulation curve'**
  String get speciesAccumulationCurve;

  /// Species accumulated field label
  ///
  /// In en, this message translates to:
  /// **'Species accumulated'**
  String get speciesAccumulated;

  /// Time in minutes field label
  ///
  /// In en, this message translates to:
  /// **'Time (10 minutes intervals)'**
  String get timeMinutes;

  /// Species counted field label
  ///
  /// In en, this message translates to:
  /// **'Species counted'**
  String get speciesCounted;

  /// Individuals counted field label
  ///
  /// In en, this message translates to:
  /// **'Individuals counted'**
  String get individualsCounted;

  /// Close button label
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// Refresh button hint
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refreshList;

  /// Message shown when there is no data to show
  ///
  /// In en, this message translates to:
  /// **'No data available.'**
  String get noDataAvailable;

  /// Button label to clear the selection
  ///
  /// In en, this message translates to:
  /// **'Clear selection'**
  String get clearSelection;

  /// Message shown when importing an inventory
  ///
  /// In en, this message translates to:
  /// **'Importing inventory...'**
  String get importingInventory;

  /// Message shown when an inventory is imported successfully
  ///
  /// In en, this message translates to:
  /// **'Inventory imported successfully!'**
  String get inventoryImportedSuccessfully;

  /// Message shown when an inventory import failed
  ///
  /// In en, this message translates to:
  /// **'Inventory import failed.'**
  String get inventoryImportFailed;

  /// Message shown when no file is selected to import
  ///
  /// In en, this message translates to:
  /// **'No file selected.'**
  String get noFileSelected;

  /// Import button label
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get import;

  /// Message shown when an error occurred while importing an inventory
  ///
  /// In en, this message translates to:
  /// **'Error importing inventory.'**
  String get errorImportingInventory;

  /// Vegetation data title or label
  ///
  /// In en, this message translates to:
  /// **'Vegetation data'**
  String get vegetationData;

  /// Herbs section label in vegetation data
  ///
  /// In en, this message translates to:
  /// **'Herbs'**
  String get herbs;

  /// Distribution field label
  ///
  /// In en, this message translates to:
  /// **'Distribution'**
  String get distribution;

  /// Proportion field label
  ///
  /// In en, this message translates to:
  /// **'Proportion'**
  String get proportion;

  /// Average height field label
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get height;

  /// Shrubs section label in vegetation data
  ///
  /// In en, this message translates to:
  /// **'Shrubs'**
  String get shrubs;

  /// Trees section label in vegetation data
  ///
  /// In en, this message translates to:
  /// **'Trees'**
  String get trees;

  /// Notes field label
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// Validation message shown when proportion field is empty
  ///
  /// In en, this message translates to:
  /// **'Insert proportion'**
  String get insertProportion;

  /// Validation message shown when height field is empty
  ///
  /// In en, this message translates to:
  /// **'Insert height'**
  String get insertHeight;

  /// Message shown when an error occurred while saving a vegetation record
  ///
  /// In en, this message translates to:
  /// **'Error saving vegetation data'**
  String get errorSavingVegetation;

  /// Weather data title or label
  ///
  /// In en, this message translates to:
  /// **'Weather data'**
  String get weatherData;

  /// Cloud cover field label
  ///
  /// In en, this message translates to:
  /// **'Cloud cover'**
  String get cloudCover;

  /// Precipitation field label
  ///
  /// In en, this message translates to:
  /// **'Precipitation'**
  String get precipitation;

  /// Validation message shown when the precipitation field is empty
  ///
  /// In en, this message translates to:
  /// **'Select precipitation'**
  String get selectPrecipitation;

  /// Temperature field label
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get temperature;

  /// Wind speed field label
  ///
  /// In en, this message translates to:
  /// **'Wind speed'**
  String get windSpeed;

  /// Validation message shown when the wind speed is out of range
  ///
  /// In en, this message translates to:
  /// **'Must be between 0 and 12 bft'**
  String get windSpeedRangeError;

  /// Message shown when an error occurred while saving a weather record
  ///
  /// In en, this message translates to:
  /// **'Error saving weather data'**
  String get errorSavingWeather;

  /// Tabs and messages about species
  ///
  /// In en, this message translates to:
  /// **'{howMany, plural, one{Species} other{Species}}'**
  String species(int howMany);

  /// Abbreviation of species in labels and edits
  ///
  /// In en, this message translates to:
  /// **'{howMany, plural, one{sp.} other{spp.}}'**
  String speciesAcronym(int howMany);

  /// Vegetation tab
  ///
  /// In en, this message translates to:
  /// **'Vegetation'**
  String get vegetation;

  /// Weather tab
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get weather;

  /// Message shown when an error occurred while getting the GPS location
  ///
  /// In en, this message translates to:
  /// **'Error getting location.'**
  String get errorGettingLocation;

  /// Point of interest abbreviation in labels
  ///
  /// In en, this message translates to:
  /// **'POI'**
  String get poi;

  /// Species information expandable list title
  ///
  /// In en, this message translates to:
  /// **'Species information'**
  String get speciesInfo;

  /// Species info showing individuals count for the species in the actual list
  ///
  /// In en, this message translates to:
  /// **'Count'**
  String get count;

  /// Species info showing the record time for the species in the actual list
  ///
  /// In en, this message translates to:
  /// **'Record time'**
  String get recordTime;

  /// Messages and labels about individuals
  ///
  /// In en, this message translates to:
  /// **'{howMany, plural, one{individual} other{individuals}}'**
  String individual(int howMany);

  /// Species info for when the species was added after the inventory was finished
  ///
  /// In en, this message translates to:
  /// **'Out of the sample'**
  String get outOfSample;

  /// Species info for when the species was added while the inventory was active
  ///
  /// In en, this message translates to:
  /// **'Within the sample'**
  String get withinSample;

  /// Message shown when no POI was found
  ///
  /// In en, this message translates to:
  /// **'No POI found.'**
  String get noPoiFound;

  /// New POI button hint
  ///
  /// In en, this message translates to:
  /// **'New POI'**
  String get newPoi;

  /// Menu option to delete POI
  ///
  /// In en, this message translates to:
  /// **'Delete POI'**
  String get deletePoi;

  /// Decrease individuals count button hint
  ///
  /// In en, this message translates to:
  /// **'Decrease individuals count'**
  String get decreaseIndividuals;

  /// Increase individuals count button hint
  ///
  /// In en, this message translates to:
  /// **'Increase individuals count'**
  String get increaseIndividuals;

  /// Add POI button hint
  ///
  /// In en, this message translates to:
  /// **'Add POI'**
  String get addPoi;

  /// Title of dialog to edit the number of individuals of a species
  ///
  /// In en, this message translates to:
  /// **'Edit count'**
  String get editCount;

  /// Individuals count field label
  ///
  /// In en, this message translates to:
  /// **'Individuals count'**
  String get individualsCount;

  /// Menu option to delete a vegetation record
  ///
  /// In en, this message translates to:
  /// **'Delete vegetation record'**
  String get deleteVegetation;

  /// Message shown when the vegetation list is empty
  ///
  /// In en, this message translates to:
  /// **'No vegetation records.'**
  String get noVegetationFound;

  /// Weather record label used in messages
  ///
  /// In en, this message translates to:
  /// **'weather record'**
  String get weatherRecord;

  /// Message shown when the weather list is empty
  ///
  /// In en, this message translates to:
  /// **'No weather records.'**
  String get noWeatherFound;

  /// Menu option to delete a weather record
  ///
  /// In en, this message translates to:
  /// **'Delete weather record'**
  String get deleteWeather;

  /// Text hint in the nest search field
  ///
  /// In en, this message translates to:
  /// **'Find nests...'**
  String get findNests;

  /// Segmented button label for filter of inactive nests
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// Message shown when the nests list is empty
  ///
  /// In en, this message translates to:
  /// **'No nests found.'**
  String get noNestsFound;

  /// Messages and labels about nests
  ///
  /// In en, this message translates to:
  /// **'{howMany, plural, one{nest} other{nests}}'**
  String nest(int howMany);

  /// New nest dialog title
  ///
  /// In en, this message translates to:
  /// **'New nest'**
  String get newNest;

  /// Menu option to delete a nest
  ///
  /// In en, this message translates to:
  /// **'Delete nest'**
  String get deleteNest;

  /// Title of dialog to confirm nest fate
  ///
  /// In en, this message translates to:
  /// **'Confirm fate'**
  String get confirmFate;

  /// Nest fate field label
  ///
  /// In en, this message translates to:
  /// **'Nest fate *'**
  String get nestFate;

  /// Error message when inactivating nest
  ///
  /// In en, this message translates to:
  /// **'Error inactivating nest: {errorMessage}'**
  String errorInactivatingNest(String errorMessage);

  /// Nest revision messages, tabs and labels
  ///
  /// In en, this message translates to:
  /// **'{howMany, plural, one{Revision} other{Revisions}}'**
  String revision(int howMany);

  /// Egg messages, tabs and labels
  ///
  /// In en, this message translates to:
  /// **'{howMany, plural, one{Egg} other{Eggs}}'**
  String egg(int howMany);

  /// Nest information expandable list title
  ///
  /// In en, this message translates to:
  /// **'Nest information'**
  String get nestInfo;

  /// Time found field label
  ///
  /// In en, this message translates to:
  /// **'Date and time found'**
  String get timeFound;

  /// Locality field label
  ///
  /// In en, this message translates to:
  /// **'Locality'**
  String get locality;

  /// Nest support field label
  ///
  /// In en, this message translates to:
  /// **'Nest support'**
  String get nestSupport;

  /// Height above ground field label
  ///
  /// In en, this message translates to:
  /// **'Height above ground'**
  String get heightAboveGround;

  /// Male field label
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// Female field label
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// Nest helpers field label
  ///
  /// In en, this message translates to:
  /// **'Nest helpers'**
  String get helpers;

  /// Message shown when the eggs list is empty
  ///
  /// In en, this message translates to:
  /// **'No eggs recorded.'**
  String get noEggsFound;

  /// Menu option to delete an egg
  ///
  /// In en, this message translates to:
  /// **'Delete egg'**
  String get deleteEgg;

  /// Message shown when the nest revision list is empty
  ///
  /// In en, this message translates to:
  /// **'No revisions recorded.'**
  String get noRevisionsFound;

  /// Menu option to delete a nest revision
  ///
  /// In en, this message translates to:
  /// **'Delete nest revision'**
  String get deleteRevision;

  /// Nest owner section label
  ///
  /// In en, this message translates to:
  /// **'Host'**
  String get host;

  /// Nidoparasite section label
  ///
  /// In en, this message translates to:
  /// **'Nidoparasite'**
  String get nidoparasite;

  /// Nestling messages and labels
  ///
  /// In en, this message translates to:
  /// **'{howMany, plural, one{Nestling} other{Nestlings}}'**
  String nestling(int howMany);

  /// Add egg dialog title
  ///
  /// In en, this message translates to:
  /// **'Add egg'**
  String get addEgg;

  /// Field number field label
  ///
  /// In en, this message translates to:
  /// **'Field number'**
  String get fieldNumber;

  /// Validation message shown when the field number is empty
  ///
  /// In en, this message translates to:
  /// **'Insert the field number'**
  String get insertFieldNumber;

  /// Validation message shown when the species is empty
  ///
  /// In en, this message translates to:
  /// **'Select a species'**
  String get selectSpecies;

  /// Egg shape field label
  ///
  /// In en, this message translates to:
  /// **'Egg shape'**
  String get eggShape;

  /// Width field label
  ///
  /// In en, this message translates to:
  /// **'Width'**
  String get width;

  /// Length field label
  ///
  /// In en, this message translates to:
  /// **'Length'**
  String get length;

  /// Weight field label
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get weight;

  /// Message shown when an egg already exists with the same field number
  ///
  /// In en, this message translates to:
  /// **'An egg with this field number already exists.'**
  String get errorEggAlreadyExists;

  /// Message shown when an error occurred while saving an egg
  ///
  /// In en, this message translates to:
  /// **'Error saving egg.'**
  String get errorSavingEgg;

  /// Validation message shown when locality name is empty
  ///
  /// In en, this message translates to:
  /// **'Please, insert locality name'**
  String get insertLocality;

  /// Validation message shown when nest support is empty
  ///
  /// In en, this message translates to:
  /// **'Please, insert nest support'**
  String get insertNestSupport;

  /// Message shown when a nest already exists with the same field number
  ///
  /// In en, this message translates to:
  /// **'A nest with this field number already exists.'**
  String get errorNestAlreadyExists;

  /// Message shown when an error occurred while saving a nest
  ///
  /// In en, this message translates to:
  /// **'Error saving nest.'**
  String get errorSavingNest;

  /// New nest revision dialog title
  ///
  /// In en, this message translates to:
  /// **'Nest revision'**
  String get nestRevision;

  /// Nest status field label
  ///
  /// In en, this message translates to:
  /// **'Nest status'**
  String get nestStatus;

  /// Nest phase field label
  ///
  /// In en, this message translates to:
  /// **'Nest phase'**
  String get nestPhase;

  /// Philornis larvae present field label
  ///
  /// In en, this message translates to:
  /// **'Philornis larvae present'**
  String get philornisLarvaePresent;

  /// Message shown when an error occurred while saving a nest revision
  ///
  /// In en, this message translates to:
  /// **'Error saving nest revision.'**
  String get errorSavingRevision;

  /// Text hint in the specimen search field
  ///
  /// In en, this message translates to:
  /// **'Find specimens...'**
  String get findSpecimens;

  /// Message shown when the specimens list is empty
  ///
  /// In en, this message translates to:
  /// **'No specimen collected.'**
  String get noSpecimenCollected;

  /// New specimen dialog title
  ///
  /// In en, this message translates to:
  /// **'New specimen'**
  String get newSpecimen;

  /// Menu option to delete a specimen
  ///
  /// In en, this message translates to:
  /// **'Delete specimen'**
  String get deleteSpecimen;

  /// Specimen type field label
  ///
  /// In en, this message translates to:
  /// **'Specimen type'**
  String get specimenType;

  /// Message shown when a specimen already exists with the same field number
  ///
  /// In en, this message translates to:
  /// **'A specimen with this field number already exists.'**
  String get errorSpecimenAlreadyExists;

  /// Message shown when an error occurred while saving a specimen
  ///
  /// In en, this message translates to:
  /// **'Error saving specimen.'**
  String get errorSavingSpecimen;

  /// Images titles, messages and labels
  ///
  /// In en, this message translates to:
  /// **'{howMany, plural, one{Image} other{Images}}'**
  String images(int howMany);

  /// Message shown when the images list is empty
  ///
  /// In en, this message translates to:
  /// **'No images found.'**
  String get noImagesFound;

  /// Add image dialog title
  ///
  /// In en, this message translates to:
  /// **'Add image'**
  String get addImage;

  /// Gallery button label
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// Camera button label
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// Message shown when the permission was denied
  ///
  /// In en, this message translates to:
  /// **'Permission denied.'**
  String get permissionDenied;

  /// Message shown when the permission was denied permanently
  ///
  /// In en, this message translates to:
  /// **'Permission denied permanently.'**
  String get permissionDeniedPermanently;

  /// Menu option to share an image
  ///
  /// In en, this message translates to:
  /// **'Share image'**
  String get shareImage;

  /// Menu option to edit the image notes
  ///
  /// In en, this message translates to:
  /// **'Edit image notes'**
  String get editImageNotes;

  /// Menu option to delete an image
  ///
  /// In en, this message translates to:
  /// **'Delete image'**
  String get deleteImage;

  /// Edit notes dialog title
  ///
  /// In en, this message translates to:
  /// **'Edit notes'**
  String get editNotes;

  /// Image details dialog title
  ///
  /// In en, this message translates to:
  /// **'Image details'**
  String get imageDetails;

  /// Message when inventory was exported
  ///
  /// In en, this message translates to:
  /// **'{howMany, plural, one{Inventory exported!} other{Inventories exported!}}'**
  String inventoryExported(int howMany);

  /// Subject when exporting inventories
  ///
  /// In en, this message translates to:
  /// **'{howMany, plural, one{Inventory data} other{Inventories data}}'**
  String inventoryData(int howMany);

  /// Error message when exporting inventories
  ///
  /// In en, this message translates to:
  /// **'Error exporting {howMany, plural, one{inventory} other{inventories}}: {errorMessage}'**
  String errorExportingInventory(int howMany, String errorMessage);

  /// Message when nest was exported
  ///
  /// In en, this message translates to:
  /// **'{howMany, plural, one{Nest exported!} other{Nests exported!}}'**
  String nestExported(int howMany);

  /// Subject when exporting nest
  ///
  /// In en, this message translates to:
  /// **'{howMany, plural, one{Nest data} other{Nests data}}'**
  String nestData(int howMany);

  /// Error message when exporting nests
  ///
  /// In en, this message translates to:
  /// **'Error exporting {howMany, plural, one{nest} other{nests}}: {errorMessage}'**
  String errorExportingNest(int howMany, String errorMessage);

  /// Message when specimen was exported
  ///
  /// In en, this message translates to:
  /// **'{howMany, plural, one{Specimen exported!} other{Specimens exported!}}'**
  String specimenExported(int howMany);

  /// Subject when exporting specimen
  ///
  /// In en, this message translates to:
  /// **'{howMany, plural, one{Specimen data} other{Specimens data}}'**
  String specimenData(int howMany);

  /// Error message when exporting specimens
  ///
  /// In en, this message translates to:
  /// **'Error exporting {howMany, plural, one{specimen} other{specimens}}: {errorMessage}'**
  String errorExportingSpecimen(int howMany, String errorMessage);

  /// Hint in the species' search field
  ///
  /// In en, this message translates to:
  /// **'Find species'**
  String get findSpecies;

  /// Add species dialog title and text hint in find species field
  ///
  /// In en, this message translates to:
  /// **'Add species'**
  String get addSpecies;

  /// Menu option to delete a species
  ///
  /// In en, this message translates to:
  /// **'Delete species'**
  String get deleteSpecies;

  /// Menu option to add notes to a species
  ///
  /// In en, this message translates to:
  /// **'Species notes'**
  String get speciesNotes;

  /// Message shown when the species list is empty
  ///
  /// In en, this message translates to:
  /// **'No species recorded'**
  String get noSpeciesFound;

  /// Species name field label
  ///
  /// In en, this message translates to:
  /// **'Species name'**
  String get speciesName;

  /// Message shown when a species is already in the list
  ///
  /// In en, this message translates to:
  /// **'Species already added to the list'**
  String get errorSpeciesAlreadyExists;

  /// Menu option to add species to the sample
  ///
  /// In en, this message translates to:
  /// **'Add to the sample'**
  String get addSpeciesToSample;

  /// Menu option to remove species from the sample
  ///
  /// In en, this message translates to:
  /// **'Remove from the sample'**
  String get removeSpeciesFromSample;

  /// Menu option to reactivate a finished inventory
  ///
  /// In en, this message translates to:
  /// **'Reactivate inventory'**
  String get reactivateInventory;

  /// Dialog title when a Mackinnon list was finished
  ///
  /// In en, this message translates to:
  /// **'List finished'**
  String get listFinished;

  /// Message asking user to take action when a Mackinnon list was finished
  ///
  /// In en, this message translates to:
  /// **'The list reached the maximum of species. Do you want to start the next list or finish now?'**
  String get listFinishedMessage;

  /// Button caption to start the next Mackinnon list
  ///
  /// In en, this message translates to:
  /// **'Start next list'**
  String get startNextList;

  /// Menu option to edit a specimen
  ///
  /// In en, this message translates to:
  /// **'Edit specimen'**
  String get editSpecimen;

  /// Menu option to edit a nest
  ///
  /// In en, this message translates to:
  /// **'Edit nest'**
  String get editNest;

  /// Menu option to edit a nest revision
  ///
  /// In en, this message translates to:
  /// **'Edit nest revision'**
  String get editNestRevision;

  /// Menu option to edit an egg
  ///
  /// In en, this message translates to:
  /// **'Edit egg'**
  String get editEgg;

  /// Menu option to edit a weather record
  ///
  /// In en, this message translates to:
  /// **'Edit weather'**
  String get editWeather;

  /// Menu option to edit a vegetation record
  ///
  /// In en, this message translates to:
  /// **'Edit vegetation'**
  String get editVegetation;

  /// Menu option to edit an inventory ID
  ///
  /// In en, this message translates to:
  /// **'Edit ID'**
  String get editInventoryId;

  /// Title of dialog to confirm deletion of species in other inventories
  ///
  /// In en, this message translates to:
  /// **'Delete species'**
  String get confirmDeleteSpecies;

  /// Message of dialog to confirm deletion of species in other inventories
  ///
  /// In en, this message translates to:
  /// **'Do you want to delete {speciesName} from other active inventories?'**
  String confirmDeleteSpeciesMessage(String speciesName);

  /// Affirmative button label
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// Negative button label
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// New journal entry screen title and button hint
  ///
  /// In en, this message translates to:
  /// **'New journal entry'**
  String get newJournalEntry;

  /// Menu option to sort by last modified date
  ///
  /// In en, this message translates to:
  /// **'Sort by Last Modified Time'**
  String get sortByLastModified;

  /// Menu option to sort by title text
  ///
  /// In en, this message translates to:
  /// **'Sort by Title'**
  String get sortByTitle;

  /// Field journal search bar hint
  ///
  /// In en, this message translates to:
  /// **'Find journal entries'**
  String get findJournalEntries;

  /// Text displayed when the field journal list is empty
  ///
  /// In en, this message translates to:
  /// **'No journal entries found'**
  String get noJournalEntriesFound;

  /// Title field label
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// Validation message for title field
  ///
  /// In en, this message translates to:
  /// **'Insert a title for the journal entry'**
  String get insertTitle;

  /// Message shown when an error occurred while saving a journal entry
  ///
  /// In en, this message translates to:
  /// **'Error saving the field journal entry'**
  String get errorSavingJournalEntry;

  /// Menu option to delete a field journal entry
  ///
  /// In en, this message translates to:
  /// **'Delete journal entry'**
  String get deleteJournalEntry;

  /// Menu option to edit a field journal entry
  ///
  /// In en, this message translates to:
  /// **'Edit journal entry'**
  String get editJournalEntry;

  /// Title for statistics screen and labels
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// Message shown when no species is selected in statistics
  ///
  /// In en, this message translates to:
  /// **'Select a species to show the statistics'**
  String get selectSpeciesToShowStats;

  /// Per species section title in statistics
  ///
  /// In en, this message translates to:
  /// **'Per species'**
  String get perSpecies;

  /// Total of records card title in statistics
  ///
  /// In en, this message translates to:
  /// **'Total of records'**
  String get totalRecords;

  /// Records per month card title in statistics
  ///
  /// In en, this message translates to:
  /// **'Records per month'**
  String get recordsPerMonth;

  /// Records per year card title in statistics
  ///
  /// In en, this message translates to:
  /// **'Records per year'**
  String get recordsPerYear;

  /// Add coordinates button hint
  ///
  /// In en, this message translates to:
  /// **'Add coordinates'**
  String get addCoordinates;

  /// Recorded species card title in statistics
  ///
  /// In en, this message translates to:
  /// **'recorded species'**
  String get recordedSpecies;

  /// Top 10 most recorded species card title in statistics
  ///
  /// In en, this message translates to:
  /// **'Top 10 most recorded species'**
  String get topTenSpecies;

  /// Survey hours card title in statistics
  ///
  /// In en, this message translates to:
  /// **'survey hours'**
  String get surveyHours;

  /// Average survey hours card title in statistics
  ///
  /// In en, this message translates to:
  /// **'survey hours per inventory'**
  String get averageSurveyHours;

  /// Pending segmented button label in specimens
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// Archived segmented button label in specimens
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get archived;

  /// Menu option to archive a specimen
  ///
  /// In en, this message translates to:
  /// **'Archive specimen'**
  String get archiveSpecimen;

  /// Male name or ID field hint
  ///
  /// In en, this message translates to:
  /// **'Male name or ID'**
  String get maleNameOrId;

  /// Female name or ID field hint
  ///
  /// In en, this message translates to:
  /// **'Female name or ID'**
  String get femaleNameOrId;

  /// Helpers names or IDs field hint
  ///
  /// In en, this message translates to:
  /// **'Helpers names or IDs'**
  String get helpersNamesOrIds;

  /// Plant species or support type field hint
  ///
  /// In en, this message translates to:
  /// **'Plant species or support type'**
  String get plantSpeciesOrSupportType;

  /// Description of the format numbers option in settings
  ///
  /// In en, this message translates to:
  /// **'Uncheck this to format numbers with point as decimal separator'**
  String get formatNumbersDescription;

  /// Select all menu and button label
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get selectAll;

  /// Message shown when exporting data
  ///
  /// In en, this message translates to:
  /// **'Exporting...'**
  String get exporting;

  /// Message shown when there is no data to export
  ///
  /// In en, this message translates to:
  /// **'No data to export.'**
  String get noDataToExport;

  /// Message shown when exporting data
  ///
  /// In en, this message translates to:
  /// **'Exporting, please wait...'**
  String get exportingPleaseWait;

  /// Error title
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get errorTitle;

  /// No description provided for @precipitationNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get precipitationNone;

  /// No description provided for @precipitationFog.
  ///
  /// In en, this message translates to:
  /// **'Fog'**
  String get precipitationFog;

  /// No description provided for @precipitationMist.
  ///
  /// In en, this message translates to:
  /// **'Mist'**
  String get precipitationMist;

  /// No description provided for @precipitationDrizzle.
  ///
  /// In en, this message translates to:
  /// **'Drizzle'**
  String get precipitationDrizzle;

  /// No description provided for @precipitationRain.
  ///
  /// In en, this message translates to:
  /// **'Rain'**
  String get precipitationRain;

  /// No description provided for @distributionNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get distributionNone;

  /// No description provided for @distributionRare.
  ///
  /// In en, this message translates to:
  /// **'Rare'**
  String get distributionRare;

  /// No description provided for @distributionFewSparseIndividuals.
  ///
  /// In en, this message translates to:
  /// **'Few sparse individuals'**
  String get distributionFewSparseIndividuals;

  /// No description provided for @distributionOnePatch.
  ///
  /// In en, this message translates to:
  /// **'One patch'**
  String get distributionOnePatch;

  /// No description provided for @distributionOnePatchFewSparseIndividuals.
  ///
  /// In en, this message translates to:
  /// **'One patch and isolated individuals'**
  String get distributionOnePatchFewSparseIndividuals;

  /// No description provided for @distributionManySparseIndividuals.
  ///
  /// In en, this message translates to:
  /// **'Many sparse individuals'**
  String get distributionManySparseIndividuals;

  /// No description provided for @distributionOnePatchManySparseIndividuals.
  ///
  /// In en, this message translates to:
  /// **'Patch and many isolated individuals'**
  String get distributionOnePatchManySparseIndividuals;

  /// No description provided for @distributionFewPatches.
  ///
  /// In en, this message translates to:
  /// **'Few patches'**
  String get distributionFewPatches;

  /// No description provided for @distributionFewPatchesSparseIndividuals.
  ///
  /// In en, this message translates to:
  /// **'Few patches and isolated individuals'**
  String get distributionFewPatchesSparseIndividuals;

  /// No description provided for @distributionManyPatches.
  ///
  /// In en, this message translates to:
  /// **'Many equidistant patches'**
  String get distributionManyPatches;

  /// No description provided for @distributionManyPatchesSparseIndividuals.
  ///
  /// In en, this message translates to:
  /// **'Many patches and scattered individuals'**
  String get distributionManyPatchesSparseIndividuals;

  /// No description provided for @distributionHighDensityIndividuals.
  ///
  /// In en, this message translates to:
  /// **'Isolated individuals in high density'**
  String get distributionHighDensityIndividuals;

  /// No description provided for @distributionContinuousCoverWithGaps.
  ///
  /// In en, this message translates to:
  /// **'Continuous with gaps'**
  String get distributionContinuousCoverWithGaps;

  /// No description provided for @distributionContinuousDenseCover.
  ///
  /// In en, this message translates to:
  /// **'Continuous and dense'**
  String get distributionContinuousDenseCover;

  /// No description provided for @distributionContinuousDenseCoverWithEdge.
  ///
  /// In en, this message translates to:
  /// **'Continuous with edge between strata'**
  String get distributionContinuousDenseCoverWithEdge;

  /// No description provided for @inventoryFreeQualitative.
  ///
  /// In en, this message translates to:
  /// **'Free Qualitative List'**
  String get inventoryFreeQualitative;

  /// No description provided for @inventoryTimedQualitative.
  ///
  /// In en, this message translates to:
  /// **'Timed Qualitative List'**
  String get inventoryTimedQualitative;

  /// No description provided for @inventoryIntervalQualitative.
  ///
  /// In en, this message translates to:
  /// **'Interval Qualitative List'**
  String get inventoryIntervalQualitative;

  /// No description provided for @inventoryMackinnonList.
  ///
  /// In en, this message translates to:
  /// **'Mackinnon List'**
  String get inventoryMackinnonList;

  /// No description provided for @inventoryTransectionCount.
  ///
  /// In en, this message translates to:
  /// **'Transection Count'**
  String get inventoryTransectionCount;

  /// No description provided for @inventoryPointCount.
  ///
  /// In en, this message translates to:
  /// **'Point Count'**
  String get inventoryPointCount;

  /// No description provided for @inventoryBanding.
  ///
  /// In en, this message translates to:
  /// **'Banding'**
  String get inventoryBanding;

  /// No description provided for @inventoryCasual.
  ///
  /// In en, this message translates to:
  /// **'Casual Observation'**
  String get inventoryCasual;

  /// No description provided for @eggShapeSpherical.
  ///
  /// In en, this message translates to:
  /// **'Spherical'**
  String get eggShapeSpherical;

  /// No description provided for @eggShapeElliptical.
  ///
  /// In en, this message translates to:
  /// **'Elliptical'**
  String get eggShapeElliptical;

  /// No description provided for @eggShapeOval.
  ///
  /// In en, this message translates to:
  /// **'Oval'**
  String get eggShapeOval;

  /// No description provided for @eggShapePyriform.
  ///
  /// In en, this message translates to:
  /// **'Pyriform'**
  String get eggShapePyriform;

  /// No description provided for @eggShapeConical.
  ///
  /// In en, this message translates to:
  /// **'Conical'**
  String get eggShapeConical;

  /// No description provided for @eggShapeBiconical.
  ///
  /// In en, this message translates to:
  /// **'Biconical'**
  String get eggShapeBiconical;

  /// No description provided for @eggShapeCylindrical.
  ///
  /// In en, this message translates to:
  /// **'Cylindrical'**
  String get eggShapeCylindrical;

  /// No description provided for @eggShapeLongitudinal.
  ///
  /// In en, this message translates to:
  /// **'Longitudinal'**
  String get eggShapeLongitudinal;

  /// No description provided for @nestStageUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get nestStageUnknown;

  /// No description provided for @nestStageBuilding.
  ///
  /// In en, this message translates to:
  /// **'Building'**
  String get nestStageBuilding;

  /// No description provided for @nestStageLaying.
  ///
  /// In en, this message translates to:
  /// **'Laying'**
  String get nestStageLaying;

  /// No description provided for @nestStageIncubating.
  ///
  /// In en, this message translates to:
  /// **'Incubating'**
  String get nestStageIncubating;

  /// No description provided for @nestStageHatching.
  ///
  /// In en, this message translates to:
  /// **'Hatching'**
  String get nestStageHatching;

  /// No description provided for @nestStageNestling.
  ///
  /// In en, this message translates to:
  /// **'Nestling'**
  String get nestStageNestling;

  /// No description provided for @nestStageInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get nestStageInactive;

  /// No description provided for @nestStatusUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get nestStatusUnknown;

  /// No description provided for @nestStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get nestStatusActive;

  /// No description provided for @nestStatusInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get nestStatusInactive;

  /// No description provided for @nestFateUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get nestFateUnknown;

  /// No description provided for @nestFateLost.
  ///
  /// In en, this message translates to:
  /// **'Lost'**
  String get nestFateLost;

  /// No description provided for @nestFateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get nestFateSuccess;

  /// No description provided for @specimenWholeCarcass.
  ///
  /// In en, this message translates to:
  /// **'Whole carcass'**
  String get specimenWholeCarcass;

  /// No description provided for @specimenPartialCarcass.
  ///
  /// In en, this message translates to:
  /// **'Partial carcass'**
  String get specimenPartialCarcass;

  /// No description provided for @specimenNest.
  ///
  /// In en, this message translates to:
  /// **'Nest'**
  String get specimenNest;

  /// No description provided for @specimenBones.
  ///
  /// In en, this message translates to:
  /// **'Bones'**
  String get specimenBones;

  /// No description provided for @specimenEgg.
  ///
  /// In en, this message translates to:
  /// **'Egg'**
  String get specimenEgg;

  /// No description provided for @specimenParasites.
  ///
  /// In en, this message translates to:
  /// **'Parasites'**
  String get specimenParasites;

  /// No description provided for @specimenFeathers.
  ///
  /// In en, this message translates to:
  /// **'Feathers'**
  String get specimenFeathers;

  /// No description provided for @specimenBlood.
  ///
  /// In en, this message translates to:
  /// **'Blood'**
  String get specimenBlood;

  /// No description provided for @specimenClaw.
  ///
  /// In en, this message translates to:
  /// **'Claw'**
  String get specimenClaw;

  /// No description provided for @specimenSwab.
  ///
  /// In en, this message translates to:
  /// **'Swab'**
  String get specimenSwab;

  /// No description provided for @specimenTissues.
  ///
  /// In en, this message translates to:
  /// **'Tissues'**
  String get specimenTissues;

  /// No description provided for @specimenFeces.
  ///
  /// In en, this message translates to:
  /// **'Feces'**
  String get specimenFeces;

  /// No description provided for @specimenRegurgite.
  ///
  /// In en, this message translates to:
  /// **'Regurgite'**
  String get specimenRegurgite;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'pt':
      {
        switch (locale.countryCode) {
          case 'BR':
            return AppLocalizationsPtBr();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
