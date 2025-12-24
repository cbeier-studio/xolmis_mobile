// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get inventories => 'Inventories';

  @override
  String get nests => 'Nests';

  @override
  String specimens(int howMany) {
    String _temp0 = intl.Intl.pluralLogic(
      howMany,
      locale: localeName,
      other: 'Specimens',
      one: 'Specimen',
    );
    return '$_temp0';
  }

  @override
  String get fieldJournal => 'Field journal';

  @override
  String journalEntries(int howMany) {
    String _temp0 = intl.Intl.pluralLogic(
      howMany,
      locale: localeName,
      other: 'Journal entries',
      one: 'Journal entry',
    );
    return '$_temp0';
  }

  @override
  String get settings => 'Settings';

  @override
  String get general => 'General';

  @override
  String get appearance => 'Appearance';

  @override
  String get selectMode => 'Select the mode';

  @override
  String get lightMode => 'Light';

  @override
  String get darkMode => 'Dark';

  @override
  String get systemMode => 'System theme';

  @override
  String get observerSetting => 'Observer (abbreviation)';

  @override
  String get observer => 'Observer';

  @override
  String get observerAbbreviation => 'Observer abbreviation';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get simultaneousInventories => 'Simultaneous inventories';

  @override
  String inventory(int howMany) {
    String _temp0 = intl.Intl.pluralLogic(
      howMany,
      locale: localeName,
      other: 'inventories',
      one: 'inventory',
    );
    return '$_temp0';
  }

  @override
  String inventoryFound(int howMany) {
    String _temp0 = intl.Intl.pluralLogic(
      howMany,
      locale: localeName,
      other: 'inventories found',
      one: 'inventory found',
    );
    return '$_temp0';
  }

  @override
  String get mackinnonLists => 'Mackinnon lists';

  @override
  String speciesPerList(int howMany) {
    String _temp0 = intl.Intl.pluralLogic(
      howMany,
      locale: localeName,
      other: '$howMany species',
      one: '1 species',
    );
    return '$_temp0 per list';
  }

  @override
  String get speciesPerListTitle => 'Species per list';

  @override
  String get pointCounts => 'Point counts';

  @override
  String get durationMin => 'Duration (min)';

  @override
  String inventoryDuration(int howMany) {
    String _temp0 = intl.Intl.pluralLogic(
      howMany,
      locale: localeName,
      other: '$howMany minutes',
      one: '1 minute',
    );
    return '$_temp0';
  }

  @override
  String get timedQualitativeLists => 'Timed qualitative lists';

  @override
  String get intervaledQualitativeLists => 'Interval qualitative lists';

  @override
  String get formatNumbers => 'Format numbers';

  @override
  String get about => 'About the app';

  @override
  String get dangerZone => 'Danger zone';

  @override
  String get deleteAppData => 'Delete the app data';

  @override
  String get deleteAppDataDescription =>
      'All data will be erased. Use with caution! This action cannot be undone.';

  @override
  String get deleteData => 'Delete data';

  @override
  String get deleteDataMessage =>
      'Are you sure you want to delete all app data? This action cannot be undone.';

  @override
  String get delete => 'Delete';

  @override
  String get dataDeleted => 'App data deleted successfully!';

  @override
  String get ok => 'OK';

  @override
  String get simultaneousLimitReached =>
      'Limit of simultaneous inventories reached.';

  @override
  String get sortByTime => 'Sort by Time';

  @override
  String get sortByName => 'Sort by Name';

  @override
  String get sortAscending => 'Sort ascending';

  @override
  String get sortDescending => 'Sort descending';

  @override
  String get findInventories => 'Find inventories...';

  @override
  String get active => 'Active';

  @override
  String get finished => 'Finished';

  @override
  String get noInventoriesFound => 'No inventories found.';

  @override
  String get deleteInventory => 'Delete inventory';

  @override
  String get confirmDelete => 'Confirm delete';

  @override
  String confirmDeleteMessage(int howMany, String gender, String what) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'these',
      'female': 'these',
      'other': 'these',
    });
    String _temp1 = intl.Intl.selectLogic(gender, {
      'male': 'this',
      'female': 'this',
      'other': 'this',
    });
    String _temp2 = intl.Intl.pluralLogic(
      howMany,
      locale: localeName,
      other: '$_temp0',
      one: '$_temp1',
    );
    return 'Are you sure you want to delete $_temp2 $what?';
  }

  @override
  String get confirmFinish => 'Confirm finish';

  @override
  String confirmFinishMessage(String which) {
    return 'Are you sure you want to finish this inventory ($which)?';
  }

  @override
  String get confirmAutoFinishMessage =>
      'Inventory automatically finished. Do you want to keep active or finish this inventory?';

  @override
  String get finish => 'Finish';

  @override
  String get keepRunning => 'Keep active';

  @override
  String get newInventory => 'New inventory';

  @override
  String speciesCount(int howMany) {
    String _temp0 = intl.Intl.pluralLogic(
      howMany,
      locale: localeName,
      other: 'species',
      one: 'species',
      zero: 'species',
    );
    return '$_temp0';
  }

  @override
  String get pause => 'Pause';

  @override
  String get resume => 'Resume';

  @override
  String get export => 'Export';

  @override
  String exportWhat(String what) {
    return 'Export $what';
  }

  @override
  String get exportAll => 'Export all';

  @override
  String exportAllWhat(String what) {
    return 'Export all $what';
  }

  @override
  String get finishInventory => 'Finish inventory';

  @override
  String get requiredField => '* required';

  @override
  String get inventoryType => 'Inventory type';

  @override
  String get selectInventoryType => 'Please, select an inventory type';

  @override
  String get inventoryId => 'Inventory ID';

  @override
  String get generateId => 'Generate ID';

  @override
  String get siteAbbreviation => 'Site name or abbreviation';

  @override
  String get optional => '* optional';

  @override
  String get insertInventoryId => 'Please, insert an ID for the inventory';

  @override
  String get duration => 'Duration';

  @override
  String minutes(int howMany) {
    String _temp0 = intl.Intl.pluralLogic(
      howMany,
      locale: localeName,
      other: 'minutes',
      one: 'minute',
    );
    return '$_temp0';
  }

  @override
  String get insertDuration => 'Insert a duration';

  @override
  String get maxSpecies => 'Max species';

  @override
  String get insertMaxSpecies => 'Insert the max of species';

  @override
  String get mustBeBiggerThanFive => 'Must be equal or higher than 5';

  @override
  String get startInventory => 'Start inventory';

  @override
  String get inventoryIdAlreadyExists => 'This inventory ID already exists.';

  @override
  String get errorInsertingInventory => 'Error inserting inventory';

  @override
  String get reportSpeciesByInventory => 'Species by inventory';

  @override
  String get totalSpecies => 'Total Species';

  @override
  String get totalIndividuals => 'Total Individuals';

  @override
  String get speciesAccumulationCurve => 'Species accumulation';

  @override
  String get speciesAccumulated => 'Species accumulated';

  @override
  String get timeMinutes => 'Time (10 minutes intervals)';

  @override
  String get speciesCounted => 'Species counted';

  @override
  String get individualsCounted => 'Individuals counted';

  @override
  String get close => 'Close';

  @override
  String get refreshList => 'Refresh';

  @override
  String get noDataAvailable => 'No data available.';

  @override
  String get clearSelection => 'Clear selection';

  @override
  String get importingInventory => 'Importing inventory...';

  @override
  String get inventoryImportedSuccessfully =>
      'Inventory imported successfully!';

  @override
  String get inventoryImportFailed => 'Inventory import failed.';

  @override
  String get noFileSelected => 'No file selected.';

  @override
  String get import => 'Import';

  @override
  String get errorImportingInventory => 'Error importing inventory.';

  @override
  String get vegetationData => 'Vegetation data';

  @override
  String get herbs => 'Herbs';

  @override
  String get distribution => 'Distribution';

  @override
  String get proportion => 'Proportion';

  @override
  String get height => 'Height';

  @override
  String get shrubs => 'Shrubs';

  @override
  String get trees => 'Trees';

  @override
  String get notes => 'Notes';

  @override
  String get insertProportion => 'Insert proportion';

  @override
  String get insertHeight => 'Insert height';

  @override
  String get errorSavingVegetation => 'Error saving vegetation data';

  @override
  String get weatherData => 'Weather data';

  @override
  String get cloudCover => 'Cloud cover';

  @override
  String get precipitation => 'Precipitation';

  @override
  String get selectPrecipitation => 'Select precipitation';

  @override
  String get temperature => 'Temperature';

  @override
  String get windSpeed => 'Wind speed';

  @override
  String get windSpeedRangeError => 'Must be between 0 and 12 bft';

  @override
  String get errorSavingWeather => 'Error saving weather data';

  @override
  String species(int howMany) {
    String _temp0 = intl.Intl.pluralLogic(
      howMany,
      locale: localeName,
      other: 'Species',
      one: 'Species',
    );
    return '$_temp0';
  }

  @override
  String speciesAcronym(int howMany) {
    String _temp0 = intl.Intl.pluralLogic(
      howMany,
      locale: localeName,
      other: 'spp.',
      one: 'sp.',
    );
    return '$_temp0';
  }

  @override
  String get vegetation => 'Vegetation';

  @override
  String get weather => 'Weather';

  @override
  String get errorGettingLocation => 'Error getting location.';

  @override
  String get poi => 'POI';

  @override
  String get speciesInfo => 'Species information';

  @override
  String get count => 'Count';

  @override
  String get recordTime => 'Record time';

  @override
  String individual(int howMany) {
    String _temp0 = intl.Intl.pluralLogic(
      howMany,
      locale: localeName,
      other: 'individuals',
      one: 'individual',
    );
    return '$_temp0';
  }

  @override
  String get outOfSample => 'Out of the sample';

  @override
  String get withinSample => 'Within the sample';

  @override
  String get noPoiFound => 'No POI found.';

  @override
  String get newPoi => 'New POI';

  @override
  String get deletePoi => 'Delete POI';

  @override
  String get decreaseIndividuals => 'Decrease individuals count';

  @override
  String get increaseIndividuals => 'Increase individuals count';

  @override
  String get addPoi => 'Add POI';

  @override
  String get editCount => 'Edit count';

  @override
  String get individualsCount => 'Individuals count';

  @override
  String get deleteVegetation => 'Delete vegetation record';

  @override
  String get noVegetationFound => 'No vegetation records.';

  @override
  String get weatherRecord => 'weather record';

  @override
  String get noWeatherFound => 'No weather records.';

  @override
  String get deleteWeather => 'Delete weather record';

  @override
  String get findNests => 'Find nests...';

  @override
  String get inactive => 'Inactive';

  @override
  String get noNestsFound => 'No nests found.';

  @override
  String nest(int howMany) {
    String _temp0 = intl.Intl.pluralLogic(
      howMany,
      locale: localeName,
      other: 'nests',
      one: 'nest',
    );
    return '$_temp0';
  }

  @override
  String get newNest => 'New nest';

  @override
  String get deleteNest => 'Delete nest';

  @override
  String get confirmFate => 'Confirm fate';

  @override
  String get nestFate => 'Nest fate';

  @override
  String errorInactivatingNest(String errorMessage) {
    return 'Error inactivating nest: $errorMessage';
  }

  @override
  String revision(int howMany) {
    String _temp0 = intl.Intl.pluralLogic(
      howMany,
      locale: localeName,
      other: 'Revisions',
      one: 'Revision',
    );
    return '$_temp0';
  }

  @override
  String egg(int howMany) {
    String _temp0 = intl.Intl.pluralLogic(
      howMany,
      locale: localeName,
      other: 'Eggs',
      one: 'Egg',
    );
    return '$_temp0';
  }

  @override
  String get nestInfo => 'Nest information';

  @override
  String get timeFound => 'Date and time found';

  @override
  String get locality => 'Locality';

  @override
  String get nestSupport => 'Nest support';

  @override
  String get heightAboveGround => 'Height above ground';

  @override
  String get male => 'Male';

  @override
  String get female => 'Female';

  @override
  String get helpers => 'Nest helpers';

  @override
  String get noEggsFound => 'No eggs recorded.';

  @override
  String get deleteEgg => 'Delete egg';

  @override
  String get noRevisionsFound => 'No revisions recorded.';

  @override
  String get deleteRevision => 'Delete nest revision';

  @override
  String get host => 'Host';

  @override
  String get nidoparasite => 'Nidoparasite';

  @override
  String nestling(int howMany) {
    String _temp0 = intl.Intl.pluralLogic(
      howMany,
      locale: localeName,
      other: 'Nestlings',
      one: 'Nestling',
    );
    return '$_temp0';
  }

  @override
  String get addEgg => 'Add egg';

  @override
  String get fieldNumber => 'Field number';

  @override
  String get insertFieldNumber => 'Insert the field number';

  @override
  String get selectSpecies => 'Select a species';

  @override
  String get eggShape => 'Egg shape';

  @override
  String get width => 'Width';

  @override
  String get length => 'Length';

  @override
  String get weight => 'Weight';

  @override
  String get errorEggAlreadyExists =>
      'An egg with this field number already exists.';

  @override
  String get errorSavingEgg => 'Error saving egg.';

  @override
  String get insertLocality => 'Please, insert locality name';

  @override
  String get insertNestSupport => 'Please, insert nest support';

  @override
  String get errorNestAlreadyExists =>
      'A nest with this field number already exists.';

  @override
  String get errorSavingNest => 'Error saving nest.';

  @override
  String get nestRevision => 'Nest revision';

  @override
  String get nestStatus => 'Nest status';

  @override
  String get nestPhase => 'Nest phase';

  @override
  String get philornisLarvaePresent => 'Philornis larvae present';

  @override
  String get errorSavingRevision => 'Error saving nest revision.';

  @override
  String get findSpecimens => 'Find specimens...';

  @override
  String get noSpecimenCollected => 'No specimen collected.';

  @override
  String get newSpecimen => 'New specimen';

  @override
  String get deleteSpecimen => 'Delete specimen';

  @override
  String get specimenType => 'Specimen type';

  @override
  String get errorSpecimenAlreadyExists =>
      'A specimen with this field number already exists.';

  @override
  String get errorSavingSpecimen => 'Error saving specimen.';

  @override
  String images(int howMany) {
    String _temp0 = intl.Intl.pluralLogic(
      howMany,
      locale: localeName,
      other: 'Images',
      one: 'Image',
    );
    return '$_temp0';
  }

  @override
  String get noImagesFound => 'No images found.';

  @override
  String get addImage => 'Add image';

  @override
  String get gallery => 'Gallery';

  @override
  String get camera => 'Camera';

  @override
  String get permissionDenied => 'Permission denied.';

  @override
  String get permissionDeniedPermanently => 'Permission denied permanently.';

  @override
  String get shareImage => 'Share image';

  @override
  String get editImageNotes => 'Edit image notes';

  @override
  String get deleteImage => 'Delete image';

  @override
  String get editNotes => 'Edit notes';

  @override
  String get imageDetails => 'Image details';

  @override
  String inventoryExported(int howMany) {
    String _temp0 = intl.Intl.pluralLogic(
      howMany,
      locale: localeName,
      other: 'Inventories exported!',
      one: 'Inventory exported!',
    );
    return '$_temp0';
  }

  @override
  String inventoryData(int howMany) {
    String _temp0 = intl.Intl.pluralLogic(
      howMany,
      locale: localeName,
      other: 'Inventories data',
      one: 'Inventory data',
    );
    return '$_temp0';
  }

  @override
  String errorExportingInventory(int howMany, String errorMessage) {
    String _temp0 = intl.Intl.pluralLogic(
      howMany,
      locale: localeName,
      other: 'inventories',
      one: 'inventory',
    );
    return 'Error exporting $_temp0: $errorMessage';
  }

  @override
  String nestExported(int howMany) {
    String _temp0 = intl.Intl.pluralLogic(
      howMany,
      locale: localeName,
      other: 'Nests exported!',
      one: 'Nest exported!',
    );
    return '$_temp0';
  }

  @override
  String nestData(int howMany) {
    String _temp0 = intl.Intl.pluralLogic(
      howMany,
      locale: localeName,
      other: 'Nests data',
      one: 'Nest data',
    );
    return '$_temp0';
  }

  @override
  String errorExportingNest(int howMany, String errorMessage) {
    String _temp0 = intl.Intl.pluralLogic(
      howMany,
      locale: localeName,
      other: 'nests',
      one: 'nest',
    );
    return 'Error exporting $_temp0: $errorMessage';
  }

  @override
  String specimenExported(int howMany) {
    String _temp0 = intl.Intl.pluralLogic(
      howMany,
      locale: localeName,
      other: 'Specimens exported!',
      one: 'Specimen exported!',
    );
    return '$_temp0';
  }

  @override
  String specimenData(int howMany) {
    String _temp0 = intl.Intl.pluralLogic(
      howMany,
      locale: localeName,
      other: 'Specimens data',
      one: 'Specimen data',
    );
    return '$_temp0';
  }

  @override
  String errorExportingSpecimen(int howMany, String errorMessage) {
    String _temp0 = intl.Intl.pluralLogic(
      howMany,
      locale: localeName,
      other: 'specimens',
      one: 'specimen',
    );
    return 'Error exporting $_temp0: $errorMessage';
  }

  @override
  String get findSpecies => 'Find species';

  @override
  String get addSpecies => 'Add species';

  @override
  String get deleteSpecies => 'Delete species';

  @override
  String get speciesNotes => 'Species notes';

  @override
  String get noSpeciesFound => 'No species recorded';

  @override
  String get speciesName => 'Species name';

  @override
  String get errorSpeciesAlreadyExists => 'Species already added to the list';

  @override
  String get addSpeciesToSample => 'Add to the sample';

  @override
  String get removeSpeciesFromSample => 'Remove from the sample';

  @override
  String get reactivateInventory => 'Reactivate inventory';

  @override
  String get listFinished => 'List finished';

  @override
  String get listFinishedMessage =>
      'The list reached the maximum of species. Do you want to start the next list or finish now?';

  @override
  String get startNextList => 'Start next list';

  @override
  String get editSpecimen => 'Edit specimen';

  @override
  String get editNest => 'Edit nest';

  @override
  String get editNestRevision => 'Edit nest revision';

  @override
  String get editEgg => 'Edit egg';

  @override
  String get editWeather => 'Edit weather';

  @override
  String get editVegetation => 'Edit vegetation';

  @override
  String get editInventoryId => 'Edit ID';

  @override
  String get confirmDeleteSpecies => 'Delete species';

  @override
  String confirmDeleteSpeciesMessage(String speciesName) {
    return 'Do you want to delete $speciesName from other active inventories?';
  }

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get newJournalEntry => 'New journal entry';

  @override
  String get sortByLastModified => 'Sort by Last Modified Time';

  @override
  String get sortByTitle => 'Sort by Title';

  @override
  String get findJournalEntries => 'Find journal entries';

  @override
  String get noJournalEntriesFound => 'No journal entries found';

  @override
  String get title => 'Title';

  @override
  String get insertTitle => 'Insert a title for the journal entry';

  @override
  String get errorSavingJournalEntry => 'Error saving the field journal entry';

  @override
  String get deleteJournalEntry => 'Delete journal entry';

  @override
  String get editJournalEntry => 'Edit journal entry';

  @override
  String get statistics => 'Statistics';

  @override
  String get selectSpeciesToShowStats =>
      'Select a species to show the statistics';

  @override
  String get perSpecies => 'Per species';

  @override
  String get totalRecords => 'Total of records';

  @override
  String get recordsPerMonth => 'Records per month';

  @override
  String get recordsPerYear => 'Records per year';

  @override
  String get addCoordinates => 'Add coordinates';

  @override
  String get recordedSpecies => 'recorded species';

  @override
  String topSpecies(int howMany) {
    return 'Top $howMany most recorded species';
  }

  @override
  String get surveyHours => 'survey hours';

  @override
  String get averageSurveyHours => 'average survey hours';

  @override
  String get pending => 'Pending';

  @override
  String get archived => 'Archived';

  @override
  String get archiveSpecimen => 'Archive specimen';

  @override
  String get maleNameOrId => 'Male name or ID';

  @override
  String get femaleNameOrId => 'Female name or ID';

  @override
  String get helpersNamesOrIds => 'Helpers names or IDs';

  @override
  String get plantSpeciesOrSupportType => 'Plant species or support type';

  @override
  String get formatNumbersDescription =>
      'Uncheck this to format numbers with point as decimal separator';

  @override
  String get selectAll => 'Select all';

  @override
  String get exporting => 'Exporting...';

  @override
  String get noDataToExport => 'No data to export.';

  @override
  String get exportingPleaseWait => 'Exporting, please wait...';

  @override
  String get errorTitle => 'Error';

  @override
  String get warningTitle => 'Warning';

  @override
  String get remindMissingVegetationData => 'Remind missing vegetation data';

  @override
  String get remindMissingWeatherData => 'Remind missing weather data';

  @override
  String get missingVegetationData => 'There is no vegetation data.';

  @override
  String get missingWeatherData => 'There is no weather data.';

  @override
  String get addButton => 'Add';

  @override
  String get ignoreButton => 'Ignore';

  @override
  String get observerAbbreviationMissing =>
      'Observer abbreviation is missing. Please add it in the settings.';

  @override
  String get invalidNumericValue => 'Invalid numeric value';

  @override
  String get nestRevisionsMissing =>
      'There are no revisions for this nest. Add at least one revision.';

  @override
  String get editLocality => 'Edit locality';

  @override
  String get addEditNotes => 'Add/edit notes';

  @override
  String get exportKml => 'Export KML';

  @override
  String get edit => 'Edit';

  @override
  String get noPoisToExport => 'No POIs to export.';

  @override
  String get totalSpeciesWithinSample => 'Species within sample';

  @override
  String get details => 'Details';

  @override
  String get editInventoryDetails => 'Inventory details';

  @override
  String get discardedInventory => 'Discarded inventory';

  @override
  String errorImportingInventoryWithFormatError(String errorMessage) {
    return 'Format error importing inventory: $errorMessage';
  }

  @override
  String inventoriesImportedSuccessfully(int howMany) {
    return 'Inventories imported successfully: $howMany';
  }

  @override
  String importCompletedWithErrors(
    int successfullyImportedCount,
    int importErrorsCount,
  ) {
    return 'Import completed with errors: $successfullyImportedCount successful, $importErrorsCount errors';
  }

  @override
  String failedToImportInventoryWithId(String id) {
    return 'Failed to import inventory with ID: $id';
  }

  @override
  String get invalidJsonFormatExpectedObjectOrArray =>
      'Invalid JSON format. Expected an object or an array.';

  @override
  String get importingNests => 'Importing nests';

  @override
  String get errorImportingNests => 'Error importing nests';

  @override
  String errorImportingNestsWithFormatError(String errorMessage) {
    return 'Format error importing nest: $errorMessage';
  }

  @override
  String nestsImportedSuccessfully(int howMany) {
    return 'Nests imported successfully: $howMany';
  }

  @override
  String failedToImportNestWithId(int id) {
    return 'Failed to import nest with ID: $id';
  }

  @override
  String get backup => 'Backup';

  @override
  String get createBackup => 'Create backup';

  @override
  String get sendBackupTo => 'Send backup to...';

  @override
  String get backupCreatedAndSharedSuccessfully =>
      'Backup created and shared successfully';

  @override
  String get errorCreatingBackup => 'Error creating backup';

  @override
  String get errorBackupNotFound => 'Backup not found';

  @override
  String get restore => 'Restore';

  @override
  String get restoreBackupConfirmation =>
      'Current data will be replaced by the backup and some data could be lost. Are you sure you want to proceed?';

  @override
  String get restoreBackup => 'Restore backup';

  @override
  String get backupRestoredSuccessfully =>
      'Backup restored successfully! Restart the app to apply the changes.';

  @override
  String get errorRestoringBackup => 'Error restoring backup';

  @override
  String get backingUpData => 'Backing up data';

  @override
  String get restoringData => 'Restoring data';

  @override
  String get importingSpecimens => 'Importing specimens';

  @override
  String get errorImportingSpecimens => 'Error importing specimens';

  @override
  String errorImportingSpecimensWithFormatError(String errorMessage) {
    return 'Format error importing specimen: $errorMessage';
  }

  @override
  String specimensImportedSuccessfully(int howMany) {
    return 'Specimens imported successfully: $howMany';
  }

  @override
  String failedToImportSpecimenWithId(int id) {
    return 'Failed to import specimen with ID: $id';
  }

  @override
  String get cloudCoverRangeError => 'Cloud cover must be between 0 and 100';

  @override
  String get relativeHumidityRangeError =>
      'Relative humidity must be between 0 and 100';

  @override
  String get atmosphericPressure => 'Atmospheric pressure';

  @override
  String get relativeHumidity => 'Relative humidity';

  @override
  String get totalOfObservers => 'Total of observers';

  @override
  String get enterCoordinates => 'Enter coordinates';

  @override
  String get latitude => 'Latitude';

  @override
  String get longitude => 'Longitude';

  @override
  String get invalidLatitude => 'Invalid latitude';

  @override
  String get invalidLongitude => 'Invalid longitude';

  @override
  String get fieldCannotBeEmpty => 'Field cannot be empty';

  @override
  String get locationError => 'Location error';

  @override
  String get couldNotGetGpsLocation => 'Could not get GPS location';

  @override
  String get continueWithout => 'Continue without';

  @override
  String get enterManually => 'Enter manually';

  @override
  String get distance => 'Distance';

  @override
  String get flightHeight => 'Flight height';

  @override
  String get flightDirection => 'Flight direction';

  @override
  String get insertCount => 'Insert count';

  @override
  String get insertValidNumber => 'Insert a valid number';

  @override
  String get windDirection => 'Wind direction';

  @override
  String get reactivate => 'Reactivate';

  @override
  String get archive => 'Archive';

  @override
  String get platinumSponsor => 'Platinum Sponsor';

  @override
  String get changelog => 'Changelog';

  @override
  String get viewLicense => 'View License';

  @override
  String get openSourceLicenses => 'Open Source Licenses';

  @override
  String get sortBy => 'Sort by';

  @override
  String get startTime => 'Start time';

  @override
  String get endTime => 'End time';

  @override
  String get direction => 'Direction';

  @override
  String get ascending => 'Ascending';

  @override
  String get descending => 'Descending';

  @override
  String get foundTime => 'Found time';

  @override
  String get lastTime => 'Last time';

  @override
  String get creationTime => 'Creation time';

  @override
  String get lastModifiedTime => 'Last modified time';

  @override
  String get sampleTime => 'Sample time';

  @override
  String get refresh => 'Refresh';

  @override
  String get inventoryIdUpdated => 'Inventory ID updated successfully!';

  @override
  String get speciesUpgradeFailed => 'Species upgrade failed';

  @override
  String get country => 'Country';

  @override
  String get speciesSearch => 'Species search';

  @override
  String get selectInventoryToView => 'Select an inventory to view its details';

  @override
  String get suggestFeatureOrReportIssue =>
      'Suggest a feature or report an issue';

  @override
  String localitiesSurveyed(int howMany) {
    String _temp0 = intl.Intl.pluralLogic(
      howMany,
      locale: localeName,
      other: 'localities',
      one: 'locality',
    );
    return '$_temp0 surveyed';
  }

  @override
  String daysSurveyed(int howMany) {
    String _temp0 = intl.Intl.pluralLogic(
      howMany,
      locale: localeName,
      other: 'days',
      one: 'day',
    );
    return '$_temp0 surveyed';
  }

  @override
  String poisRecorded(int howMany) {
    String _temp0 = intl.Intl.pluralLogic(
      howMany,
      locale: localeName,
      other: 'POIs',
      one: 'POI',
    );
    return '$_temp0 recorded';
  }

  @override
  String get seeAll => 'See all';

  @override
  String get apparentSuccessRate => 'apparent success rate';

  @override
  String get nidoparasitismRate => 'nidoparasitism rate';

  @override
  String get detectionRate => 'detection rate';

  @override
  String get speciesRichness => 'Species richness';

  @override
  String get totalRichness => 'total richness';

  @override
  String get averageRichness => 'average richness';

  @override
  String get relativeFrequency => 'relative frequency';

  @override
  String get relativeAbundance => 'relative abundance';

  @override
  String get recordsByHour => 'Records by hour';

  @override
  String get totalAbundance => 'total abundance';

  @override
  String get selectedInventories => 'selected inventories';

  @override
  String errorParsingArrayItem(String item, String errorMessage) {
    return 'Error parsing array item: $errorMessage \nItem: $item';
  }

  @override
  String errorUnexpectedArrayItem(String item) {
    return 'Unexpected item in JSON array: $item';
  }

  @override
  String errorParsingInventoriesArrayItem(String item, String errorMessage) {
    return 'Error parsing \'inventories\' array item: $errorMessage \nItem: $item';
  }

  @override
  String errorUnexpectedInventoriesArrayItem(String item) {
    return 'Unexpected item in \'inventories\' JSON array: $item';
  }

  @override
  String errorParsingObject(String errorMessage) {
    return 'Error parsing object: $errorMessage';
  }

  @override
  String get noInventoriesFoundInFile =>
      'No inventories found in the imported file.';

  @override
  String get noValidInventoriesFoundInFile =>
      'No valid inventories found in the imported file.';

  @override
  String errorImportingInventoryWithId(
    String inventoryId,
    String errorMessage,
  ) {
    return 'Error importing inventory $inventoryId: $errorMessage';
  }

  @override
  String errorParsingNestsArrayItem(String item, String errorMessage) {
    return 'Error parsing \'nests\' array item: $errorMessage \nItem: $item';
  }

  @override
  String errorUnexpectedNestsArrayItem(String item) {
    return 'Unexpected item in \'nests\' JSON array: $item';
  }

  @override
  String errorParsingSpecimensArrayItem(String item, String errorMessage) {
    return 'Error parsing \'specimens\' array item: $errorMessage \nItem: $item';
  }

  @override
  String errorUnexpectedSpecimensArrayItem(String item) {
    return 'Unexpected item in \'specimens\' JSON array: $item';
  }

  @override
  String get insertObserver => 'Insert observer';

  @override
  String selectedNests(int howMany) {
    String _temp0 = intl.Intl.pluralLogic(
      howMany,
      locale: localeName,
      other: 'nests',
      one: 'nest',
    );
    return 'selected $_temp0';
  }

  @override
  String get countryArgentina => 'Argentina';

  @override
  String get countryBrazil => 'Brazil';

  @override
  String get countryParaguay => 'Paraguay';

  @override
  String get countryUruguay => 'Uruguay';

  @override
  String get precipitationNone => 'None';

  @override
  String get precipitationFog => 'Fog';

  @override
  String get precipitationMist => 'Mist';

  @override
  String get precipitationDrizzle => 'Drizzle';

  @override
  String get precipitationRain => 'Rain';

  @override
  String get precipitationShowers => 'Showers';

  @override
  String get precipitationSnow => 'Snow';

  @override
  String get precipitationHail => 'Hail';

  @override
  String get precipitationFrost => 'Frost';

  @override
  String get distributionNone => 'None';

  @override
  String get distributionRare => 'Rare';

  @override
  String get distributionFewSparseIndividuals => 'Few sparse individuals';

  @override
  String get distributionOnePatch => 'One patch';

  @override
  String get distributionOnePatchFewSparseIndividuals =>
      'One patch and isolated individuals';

  @override
  String get distributionManySparseIndividuals => 'Many sparse individuals';

  @override
  String get distributionOnePatchManySparseIndividuals =>
      'Patch and many isolated individuals';

  @override
  String get distributionFewPatches => 'Few patches';

  @override
  String get distributionFewPatchesSparseIndividuals =>
      'Few patches and isolated individuals';

  @override
  String get distributionManyPatches => 'Many equidistant patches';

  @override
  String get distributionManyPatchesSparseIndividuals =>
      'Many patches and scattered individuals';

  @override
  String get distributionHighDensityIndividuals =>
      'Isolated individuals in high density';

  @override
  String get distributionContinuousCoverWithGaps => 'Continuous with gaps';

  @override
  String get distributionContinuousDenseCover => 'Continuous and dense';

  @override
  String get distributionContinuousDenseCoverWithEdge =>
      'Continuous with edge between strata';

  @override
  String get inventoryFreeQualitative => 'Free Qualitative List';

  @override
  String get inventoryTimedQualitative => 'Timed Qualitative List';

  @override
  String get inventoryIntervalQualitative => 'Interval Qualitative List';

  @override
  String get inventoryMackinnonList => 'Mackinnon List';

  @override
  String get inventoryTransectCount => 'Transect Count';

  @override
  String get inventoryPointCount => 'Point Count';

  @override
  String get inventoryBanding => 'Banding';

  @override
  String get inventoryCasual => 'Casual Observation';

  @override
  String get inventoryTransectDetection => 'Detection Transect Count';

  @override
  String get inventoryPointDetection => 'Detection Point Count';

  @override
  String get eggShapeSpherical => 'Spherical';

  @override
  String get eggShapeElliptical => 'Elliptical';

  @override
  String get eggShapeOval => 'Oval';

  @override
  String get eggShapePyriform => 'Pyriform';

  @override
  String get eggShapeConical => 'Conical';

  @override
  String get eggShapeBiconical => 'Biconical';

  @override
  String get eggShapeCylindrical => 'Cylindrical';

  @override
  String get eggShapeLongitudinal => 'Longitudinal';

  @override
  String get nestStageUnknown => 'Unknown';

  @override
  String get nestStageBuilding => 'Building';

  @override
  String get nestStageLaying => 'Laying';

  @override
  String get nestStageIncubating => 'Incubating';

  @override
  String get nestStageHatching => 'Hatching';

  @override
  String get nestStageNestling => 'Nestling';

  @override
  String get nestStageInactive => 'Inactive';

  @override
  String get nestStatusUnknown => 'Unknown';

  @override
  String get nestStatusActive => 'Active';

  @override
  String get nestStatusInactive => 'Inactive';

  @override
  String get nestFateUnknown => 'Unknown';

  @override
  String get nestFateLost => 'Lost';

  @override
  String get nestFateSuccess => 'Success';

  @override
  String get specimenWholeCarcass => 'Whole carcass';

  @override
  String get specimenPartialCarcass => 'Partial carcass';

  @override
  String get specimenNest => 'Nest';

  @override
  String get specimenBones => 'Bones';

  @override
  String get specimenEgg => 'Egg';

  @override
  String get specimenParasites => 'Parasites';

  @override
  String get specimenFeathers => 'Feathers';

  @override
  String get specimenBlood => 'Blood';

  @override
  String get specimenClaw => 'Claw';

  @override
  String get specimenSwab => 'Swab';

  @override
  String get specimenTissues => 'Tissues';

  @override
  String get specimenFeces => 'Feces';

  @override
  String get specimenRegurgite => 'Regurgite';
}
