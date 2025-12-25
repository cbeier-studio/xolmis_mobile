// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a en locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names, avoid_escaping_inner_quotes
// ignore_for_file:unnecessary_string_interpolations, unnecessary_string_escapes

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'en';

  static String m0(howMany, gender, what) =>
      "Are you sure you want to delete ${Intl.plural(
        howMany,
        one: '${Intl.gender(gender, female: 'this', male: 'this', other: 'this')}',
        other: '${Intl.gender(gender, female: 'these', male: 'these', other: 'these')}',
      )} ${what}?";

  static String m1(speciesName) =>
      "Do you want to delete ${speciesName} from other active inventories?";

  static String m2(which) =>
      "Are you sure you want to finish this inventory (${which})?";

  static String m3(howMany) =>
      "${Intl.plural(howMany, one: 'day', other: 'days')} surveyed";

  static String m4(howMany) =>
      "${Intl.plural(howMany, one: 'Egg', other: 'Eggs')}";

  static String m5(howMany, errorMessage) =>
      "Error exporting ${Intl.plural(howMany, one: 'inventory', other: 'inventories')}: ${errorMessage}";

  static String m6(howMany, errorMessage) =>
      "Error exporting ${Intl.plural(howMany, one: 'nest', other: 'nests')}: ${errorMessage}";

  static String m7(howMany, errorMessage) =>
      "Error exporting ${Intl.plural(howMany, one: 'specimen', other: 'specimens')}: ${errorMessage}";

  static String m8(errorMessage) =>
      "Format error importing inventory: ${errorMessage}";

  static String m9(inventoryId, errorMessage) =>
      "Error importing inventory ${inventoryId}: ${errorMessage}";

  static String m10(errorMessage) =>
      "Format error importing nest: ${errorMessage}";

  static String m11(errorMessage) =>
      "Format error importing specimen: ${errorMessage}";

  static String m12(errorMessage) => "Error inactivating nest: ${errorMessage}";

  static String m13(item, errorMessage) =>
      "Error parsing array item: ${errorMessage} \nItem: ${item}";

  static String m14(item, errorMessage) =>
      "Error parsing \'inventories\' array item: ${errorMessage} \nItem: ${item}";

  static String m15(item, errorMessage) =>
      "Error parsing \'nests\' array item: ${errorMessage} \nItem: ${item}";

  static String m16(errorMessage) => "Error parsing object: ${errorMessage}";

  static String m17(item, errorMessage) =>
      "Error parsing \'specimens\' array item: ${errorMessage} \nItem: ${item}";

  static String m18(item) => "Unexpected item in JSON array: ${item}";

  static String m19(item) =>
      "Unexpected item in \'inventories\' JSON array: ${item}";

  static String m20(item) => "Unexpected item in \'nests\' JSON array: ${item}";

  static String m21(item) =>
      "Unexpected item in \'specimens\' JSON array: ${item}";

  static String m22(what) => "Export all ${what}";

  static String m23(what) => "Export ${what}";

  static String m24(id) => "Failed to import inventory with ID: ${id}";

  static String m25(id) => "Failed to import nest with ID: ${id}";

  static String m26(id) => "Failed to import specimen with ID: ${id}";

  static String m27(howMany) =>
      "${Intl.plural(howMany, one: 'Image', other: 'Images')}";

  static String m28(successfullyImportedCount, importErrorsCount) =>
      "Import completed with errors: ${successfullyImportedCount} successful, ${importErrorsCount} errors";

  static String m29(howMany) =>
      "${Intl.plural(howMany, one: 'individual', other: 'individuals')}";

  static String m30(howMany) => "Inventories imported successfully: ${howMany}";

  static String m31(howMany) =>
      "${Intl.plural(howMany, one: 'inventory', other: 'inventories')}";

  static String m32(howMany) =>
      "${Intl.plural(howMany, one: 'Inventory data', other: 'Inventories data')}";

  static String m33(howMany) =>
      "${Intl.plural(howMany, one: '1 minute', other: '${howMany} minutes')}";

  static String m34(howMany) =>
      "${Intl.plural(howMany, one: 'Inventory exported!', other: 'Inventories exported!')}";

  static String m35(howMany) =>
      "${Intl.plural(howMany, one: 'inventory found', other: 'inventories found')}";

  static String m36(howMany) =>
      "${Intl.plural(howMany, one: 'Journal entry', other: 'Journal entries')}";

  static String m37(howMany) =>
      "${Intl.plural(howMany, one: 'locality', other: 'localities')} surveyed";

  static String m38(howMany) =>
      "${Intl.plural(howMany, one: 'minute', other: 'minutes')}";

  static String m39(howMany) =>
      "${Intl.plural(howMany, one: 'nest', other: 'nests')}";

  static String m40(howMany) =>
      "${Intl.plural(howMany, one: 'Nest data', other: 'Nests data')}";

  static String m41(howMany) =>
      "${Intl.plural(howMany, one: 'Nest exported!', other: 'Nests exported!')}";

  static String m42(howMany) =>
      "${Intl.plural(howMany, one: 'Nestling', other: 'Nestlings')}";

  static String m43(howMany) => "Nests imported successfully: ${howMany}";

  static String m44(howMany) =>
      "${Intl.plural(howMany, one: 'observer', other: 'observers')}";

  static String m45(howMany) =>
      "${Intl.plural(howMany, one: 'POI', other: 'POIs')} recorded";

  static String m46(howMany) =>
      "${Intl.plural(howMany, one: 'Revision', other: 'Revisions')}";

  static String m47(howMany) =>
      "selected ${Intl.plural(howMany, one: 'nest', other: 'nests')}";

  static String m48(howMany) =>
      "${Intl.plural(howMany, one: 'Species', other: 'Species')}";

  static String m49(howMany) =>
      "${Intl.plural(howMany, one: 'sp.', other: 'spp.')}";

  static String m50(howMany) =>
      "${Intl.plural(howMany, zero: 'species', one: 'species', other: 'species')}";

  static String m51(howMany) =>
      "${Intl.plural(howMany, one: '1 species', other: '${howMany} species')} per list";

  static String m52(howMany) =>
      "${Intl.plural(howMany, one: 'Specimen data', other: 'Specimens data')}";

  static String m53(howMany) =>
      "${Intl.plural(howMany, one: 'Specimen exported!', other: 'Specimens exported!')}";

  static String m54(howMany) =>
      "${Intl.plural(howMany, one: 'Specimen', other: 'Specimens')}";

  static String m55(howMany) => "Specimens imported successfully: ${howMany}";

  static String m56(howMany) => "Top ${howMany} most recorded species";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "about": MessageLookupByLibrary.simpleMessage("About the app"),
    "active": MessageLookupByLibrary.simpleMessage("Active"),
    "addButton": MessageLookupByLibrary.simpleMessage("Add"),
    "addCoordinates": MessageLookupByLibrary.simpleMessage("Add coordinates"),
    "addEditNotes": MessageLookupByLibrary.simpleMessage("Add/edit notes"),
    "addEgg": MessageLookupByLibrary.simpleMessage("Add egg"),
    "addImage": MessageLookupByLibrary.simpleMessage("Add image"),
    "addPoi": MessageLookupByLibrary.simpleMessage("Add POI"),
    "addSpecies": MessageLookupByLibrary.simpleMessage("Add species"),
    "addSpeciesToSample": MessageLookupByLibrary.simpleMessage(
      "Add to the sample",
    ),
    "apparentSuccessRate": MessageLookupByLibrary.simpleMessage(
      "apparent success rate",
    ),
    "appearance": MessageLookupByLibrary.simpleMessage("Appearance"),
    "archive": MessageLookupByLibrary.simpleMessage("Archive"),
    "archiveSpecimen": MessageLookupByLibrary.simpleMessage("Archive specimen"),
    "archived": MessageLookupByLibrary.simpleMessage("Archived"),
    "ascending": MessageLookupByLibrary.simpleMessage("Ascending"),
    "atmosphericPressure": MessageLookupByLibrary.simpleMessage(
      "Atmospheric pressure",
    ),
    "averageRichness": MessageLookupByLibrary.simpleMessage("average richness"),
    "averageSurveyHours": MessageLookupByLibrary.simpleMessage(
      "average survey hours",
    ),
    "backingUpData": MessageLookupByLibrary.simpleMessage("Backing up data"),
    "backup": MessageLookupByLibrary.simpleMessage("Backup"),
    "backupCreatedAndSharedSuccessfully": MessageLookupByLibrary.simpleMessage(
      "Backup created and shared successfully",
    ),
    "backupRestoredSuccessfully": MessageLookupByLibrary.simpleMessage(
      "Backup restored successfully! Restart the app to apply the changes.",
    ),
    "camera": MessageLookupByLibrary.simpleMessage("Camera"),
    "cancel": MessageLookupByLibrary.simpleMessage("Cancel"),
    "changelog": MessageLookupByLibrary.simpleMessage("Changelog"),
    "clearFilters": MessageLookupByLibrary.simpleMessage("Clear filters"),
    "clearSelection": MessageLookupByLibrary.simpleMessage("Clear selection"),
    "close": MessageLookupByLibrary.simpleMessage("Close"),
    "cloudCover": MessageLookupByLibrary.simpleMessage("Cloud cover"),
    "cloudCoverRangeError": MessageLookupByLibrary.simpleMessage(
      "Cloud cover must be between 0 and 100",
    ),
    "confirmAutoFinishMessage": MessageLookupByLibrary.simpleMessage(
      "Inventory automatically finished. Do you want to keep active or finish this inventory?",
    ),
    "confirmDelete": MessageLookupByLibrary.simpleMessage("Confirm delete"),
    "confirmDeleteMessage": m0,
    "confirmDeleteSpecies": MessageLookupByLibrary.simpleMessage(
      "Delete species",
    ),
    "confirmDeleteSpeciesMessage": m1,
    "confirmFate": MessageLookupByLibrary.simpleMessage("Confirm fate"),
    "confirmFinish": MessageLookupByLibrary.simpleMessage("Confirm finish"),
    "confirmFinishMessage": m2,
    "continueWithout": MessageLookupByLibrary.simpleMessage("Continue without"),
    "couldNotGetGpsLocation": MessageLookupByLibrary.simpleMessage(
      "Could not get GPS location",
    ),
    "count": MessageLookupByLibrary.simpleMessage("Count"),
    "country": MessageLookupByLibrary.simpleMessage("Country"),
    "countryArgentina": MessageLookupByLibrary.simpleMessage("Argentina"),
    "countryBrazil": MessageLookupByLibrary.simpleMessage("Brazil"),
    "countryParaguay": MessageLookupByLibrary.simpleMessage("Paraguay"),
    "countryUruguay": MessageLookupByLibrary.simpleMessage("Uruguay"),
    "createBackup": MessageLookupByLibrary.simpleMessage("Create backup"),
    "creationTime": MessageLookupByLibrary.simpleMessage("Creation time"),
    "dangerZone": MessageLookupByLibrary.simpleMessage("Danger zone"),
    "darkMode": MessageLookupByLibrary.simpleMessage("Dark"),
    "dataDeleted": MessageLookupByLibrary.simpleMessage(
      "App data deleted successfully!",
    ),
    "daysSurveyed": m3,
    "decreaseIndividuals": MessageLookupByLibrary.simpleMessage(
      "Decrease individuals count",
    ),
    "delete": MessageLookupByLibrary.simpleMessage("Delete"),
    "deleteAppData": MessageLookupByLibrary.simpleMessage(
      "Delete the app data",
    ),
    "deleteAppDataDescription": MessageLookupByLibrary.simpleMessage(
      "All data will be erased. Use with caution! This action cannot be undone.",
    ),
    "deleteData": MessageLookupByLibrary.simpleMessage("Delete data"),
    "deleteDataMessage": MessageLookupByLibrary.simpleMessage(
      "Are you sure you want to delete all app data? This action cannot be undone.",
    ),
    "deleteEgg": MessageLookupByLibrary.simpleMessage("Delete egg"),
    "deleteImage": MessageLookupByLibrary.simpleMessage("Delete image"),
    "deleteInventory": MessageLookupByLibrary.simpleMessage("Delete inventory"),
    "deleteJournalEntry": MessageLookupByLibrary.simpleMessage(
      "Delete journal entry",
    ),
    "deleteNest": MessageLookupByLibrary.simpleMessage("Delete nest"),
    "deletePoi": MessageLookupByLibrary.simpleMessage("Delete POI"),
    "deleteRevision": MessageLookupByLibrary.simpleMessage(
      "Delete nest revision",
    ),
    "deleteSpecies": MessageLookupByLibrary.simpleMessage("Delete species"),
    "deleteSpecimen": MessageLookupByLibrary.simpleMessage("Delete specimen"),
    "deleteVegetation": MessageLookupByLibrary.simpleMessage(
      "Delete vegetation record",
    ),
    "deleteWeather": MessageLookupByLibrary.simpleMessage(
      "Delete weather record",
    ),
    "descending": MessageLookupByLibrary.simpleMessage("Descending"),
    "details": MessageLookupByLibrary.simpleMessage("Details"),
    "detectionRate": MessageLookupByLibrary.simpleMessage("detection rate"),
    "direction": MessageLookupByLibrary.simpleMessage("Direction"),
    "discardedInventory": MessageLookupByLibrary.simpleMessage(
      "Discarded inventory",
    ),
    "distance": MessageLookupByLibrary.simpleMessage("Distance"),
    "distribution": MessageLookupByLibrary.simpleMessage("Distribution"),
    "distributionContinuousCoverWithGaps": MessageLookupByLibrary.simpleMessage(
      "Continuous with gaps",
    ),
    "distributionContinuousDenseCover": MessageLookupByLibrary.simpleMessage(
      "Continuous and dense",
    ),
    "distributionContinuousDenseCoverWithEdge":
        MessageLookupByLibrary.simpleMessage(
          "Continuous with edge between strata",
        ),
    "distributionFewPatches": MessageLookupByLibrary.simpleMessage(
      "Few patches",
    ),
    "distributionFewPatchesSparseIndividuals":
        MessageLookupByLibrary.simpleMessage(
          "Few patches and isolated individuals",
        ),
    "distributionFewSparseIndividuals": MessageLookupByLibrary.simpleMessage(
      "Few sparse individuals",
    ),
    "distributionHighDensityIndividuals": MessageLookupByLibrary.simpleMessage(
      "Isolated individuals in high density",
    ),
    "distributionManyPatches": MessageLookupByLibrary.simpleMessage(
      "Many equidistant patches",
    ),
    "distributionManyPatchesSparseIndividuals":
        MessageLookupByLibrary.simpleMessage(
          "Many patches and scattered individuals",
        ),
    "distributionManySparseIndividuals": MessageLookupByLibrary.simpleMessage(
      "Many sparse individuals",
    ),
    "distributionNone": MessageLookupByLibrary.simpleMessage("None"),
    "distributionOnePatch": MessageLookupByLibrary.simpleMessage("One patch"),
    "distributionOnePatchFewSparseIndividuals":
        MessageLookupByLibrary.simpleMessage(
          "One patch and isolated individuals",
        ),
    "distributionOnePatchManySparseIndividuals":
        MessageLookupByLibrary.simpleMessage(
          "Patch and many isolated individuals",
        ),
    "distributionRare": MessageLookupByLibrary.simpleMessage("Rare"),
    "duration": MessageLookupByLibrary.simpleMessage("Duration"),
    "durationMin": MessageLookupByLibrary.simpleMessage("Duration (min)"),
    "edit": MessageLookupByLibrary.simpleMessage("Edit"),
    "editCount": MessageLookupByLibrary.simpleMessage("Edit count"),
    "editEgg": MessageLookupByLibrary.simpleMessage("Edit egg"),
    "editImageNotes": MessageLookupByLibrary.simpleMessage("Edit image notes"),
    "editInventoryDetails": MessageLookupByLibrary.simpleMessage(
      "Inventory details",
    ),
    "editInventoryId": MessageLookupByLibrary.simpleMessage("Edit ID"),
    "editJournalEntry": MessageLookupByLibrary.simpleMessage(
      "Edit journal entry",
    ),
    "editLocality": MessageLookupByLibrary.simpleMessage("Edit locality"),
    "editNest": MessageLookupByLibrary.simpleMessage("Edit nest"),
    "editNestRevision": MessageLookupByLibrary.simpleMessage(
      "Edit nest revision",
    ),
    "editNotes": MessageLookupByLibrary.simpleMessage("Edit notes"),
    "editSpecimen": MessageLookupByLibrary.simpleMessage("Edit specimen"),
    "editVegetation": MessageLookupByLibrary.simpleMessage("Edit vegetation"),
    "editWeather": MessageLookupByLibrary.simpleMessage("Edit weather"),
    "egg": m4,
    "eggShape": MessageLookupByLibrary.simpleMessage("Egg shape"),
    "eggShapeBiconical": MessageLookupByLibrary.simpleMessage("Biconical"),
    "eggShapeConical": MessageLookupByLibrary.simpleMessage("Conical"),
    "eggShapeCylindrical": MessageLookupByLibrary.simpleMessage("Cylindrical"),
    "eggShapeElliptical": MessageLookupByLibrary.simpleMessage("Elliptical"),
    "eggShapeLongitudinal": MessageLookupByLibrary.simpleMessage(
      "Longitudinal",
    ),
    "eggShapeOval": MessageLookupByLibrary.simpleMessage("Oval"),
    "eggShapePyriform": MessageLookupByLibrary.simpleMessage("Pyriform"),
    "eggShapeSpherical": MessageLookupByLibrary.simpleMessage("Spherical"),
    "endTime": MessageLookupByLibrary.simpleMessage("End time"),
    "enterCoordinates": MessageLookupByLibrary.simpleMessage(
      "Enter coordinates",
    ),
    "enterManually": MessageLookupByLibrary.simpleMessage("Enter manually"),
    "errorBackupNotFound": MessageLookupByLibrary.simpleMessage(
      "Backup not found",
    ),
    "errorCreatingBackup": MessageLookupByLibrary.simpleMessage(
      "Error creating backup",
    ),
    "errorEggAlreadyExists": MessageLookupByLibrary.simpleMessage(
      "An egg with this field number already exists.",
    ),
    "errorExportingInventory": m5,
    "errorExportingNest": m6,
    "errorExportingSpecimen": m7,
    "errorGettingLocation": MessageLookupByLibrary.simpleMessage(
      "Error getting location.",
    ),
    "errorImportingInventory": MessageLookupByLibrary.simpleMessage(
      "Error importing inventory.",
    ),
    "errorImportingInventoryWithFormatError": m8,
    "errorImportingInventoryWithId": m9,
    "errorImportingNests": MessageLookupByLibrary.simpleMessage(
      "Error importing nests",
    ),
    "errorImportingNestsWithFormatError": m10,
    "errorImportingSpecimens": MessageLookupByLibrary.simpleMessage(
      "Error importing specimens",
    ),
    "errorImportingSpecimensWithFormatError": m11,
    "errorInactivatingNest": m12,
    "errorInsertingInventory": MessageLookupByLibrary.simpleMessage(
      "Error inserting inventory",
    ),
    "errorNestAlreadyExists": MessageLookupByLibrary.simpleMessage(
      "A nest with this field number already exists.",
    ),
    "errorParsingArrayItem": m13,
    "errorParsingInventoriesArrayItem": m14,
    "errorParsingNestsArrayItem": m15,
    "errorParsingObject": m16,
    "errorParsingSpecimensArrayItem": m17,
    "errorRestoringBackup": MessageLookupByLibrary.simpleMessage(
      "Error restoring backup",
    ),
    "errorSavingEgg": MessageLookupByLibrary.simpleMessage("Error saving egg."),
    "errorSavingJournalEntry": MessageLookupByLibrary.simpleMessage(
      "Error saving the field journal entry",
    ),
    "errorSavingNest": MessageLookupByLibrary.simpleMessage(
      "Error saving nest.",
    ),
    "errorSavingRevision": MessageLookupByLibrary.simpleMessage(
      "Error saving nest revision.",
    ),
    "errorSavingSpecimen": MessageLookupByLibrary.simpleMessage(
      "Error saving specimen.",
    ),
    "errorSavingVegetation": MessageLookupByLibrary.simpleMessage(
      "Error saving vegetation data",
    ),
    "errorSavingWeather": MessageLookupByLibrary.simpleMessage(
      "Error saving weather data",
    ),
    "errorSpeciesAlreadyExists": MessageLookupByLibrary.simpleMessage(
      "Species already added to the list",
    ),
    "errorSpecimenAlreadyExists": MessageLookupByLibrary.simpleMessage(
      "A specimen with this field number already exists.",
    ),
    "errorTitle": MessageLookupByLibrary.simpleMessage("Error"),
    "errorUnexpectedArrayItem": m18,
    "errorUnexpectedInventoriesArrayItem": m19,
    "errorUnexpectedNestsArrayItem": m20,
    "errorUnexpectedSpecimensArrayItem": m21,
    "export": MessageLookupByLibrary.simpleMessage("Export"),
    "exportAll": MessageLookupByLibrary.simpleMessage("Export all"),
    "exportAllWhat": m22,
    "exportKml": MessageLookupByLibrary.simpleMessage("Export KML"),
    "exportWhat": m23,
    "exporting": MessageLookupByLibrary.simpleMessage("Exporting..."),
    "exportingPleaseWait": MessageLookupByLibrary.simpleMessage(
      "Exporting, please wait...",
    ),
    "failedToImportInventoryWithId": m24,
    "failedToImportNestWithId": m25,
    "failedToImportSpecimenWithId": m26,
    "female": MessageLookupByLibrary.simpleMessage("Female"),
    "femaleNameOrId": MessageLookupByLibrary.simpleMessage("Female name or ID"),
    "fieldCannotBeEmpty": MessageLookupByLibrary.simpleMessage(
      "Field cannot be empty",
    ),
    "fieldJournal": MessageLookupByLibrary.simpleMessage("Field journal"),
    "fieldNumber": MessageLookupByLibrary.simpleMessage("Field number"),
    "findInventories": MessageLookupByLibrary.simpleMessage(
      "Find inventories...",
    ),
    "findJournalEntries": MessageLookupByLibrary.simpleMessage(
      "Find journal entries",
    ),
    "findNests": MessageLookupByLibrary.simpleMessage("Find nests..."),
    "findSpecies": MessageLookupByLibrary.simpleMessage("Find species"),
    "findSpecimens": MessageLookupByLibrary.simpleMessage("Find specimens..."),
    "finish": MessageLookupByLibrary.simpleMessage("Finish"),
    "finishInventory": MessageLookupByLibrary.simpleMessage("Finish inventory"),
    "finished": MessageLookupByLibrary.simpleMessage("Finished"),
    "flightDirection": MessageLookupByLibrary.simpleMessage("Flight direction"),
    "flightHeight": MessageLookupByLibrary.simpleMessage("Flight height"),
    "formatNumbers": MessageLookupByLibrary.simpleMessage("Format numbers"),
    "formatNumbersDescription": MessageLookupByLibrary.simpleMessage(
      "Uncheck this to format numbers with point as decimal separator",
    ),
    "foundTime": MessageLookupByLibrary.simpleMessage("Found time"),
    "gallery": MessageLookupByLibrary.simpleMessage("Gallery"),
    "general": MessageLookupByLibrary.simpleMessage("General"),
    "generateId": MessageLookupByLibrary.simpleMessage("Generate ID"),
    "height": MessageLookupByLibrary.simpleMessage("Height"),
    "heightAboveGround": MessageLookupByLibrary.simpleMessage(
      "Height above ground",
    ),
    "helpers": MessageLookupByLibrary.simpleMessage("Nest helpers"),
    "helpersNamesOrIds": MessageLookupByLibrary.simpleMessage(
      "Helpers names or IDs",
    ),
    "herbs": MessageLookupByLibrary.simpleMessage("Herbs"),
    "host": MessageLookupByLibrary.simpleMessage("Host"),
    "ignoreButton": MessageLookupByLibrary.simpleMessage("Ignore"),
    "imageDetails": MessageLookupByLibrary.simpleMessage("Image details"),
    "images": m27,
    "import": MessageLookupByLibrary.simpleMessage("Import"),
    "importCompletedWithErrors": m28,
    "importingInventory": MessageLookupByLibrary.simpleMessage(
      "Importing inventory...",
    ),
    "importingNests": MessageLookupByLibrary.simpleMessage("Importing nests"),
    "importingSpecimens": MessageLookupByLibrary.simpleMessage(
      "Importing specimens",
    ),
    "inactive": MessageLookupByLibrary.simpleMessage("Inactive"),
    "increaseIndividuals": MessageLookupByLibrary.simpleMessage(
      "Increase individuals count",
    ),
    "individual": m29,
    "individualsCount": MessageLookupByLibrary.simpleMessage(
      "Individuals count",
    ),
    "individualsCounted": MessageLookupByLibrary.simpleMessage(
      "Individuals counted",
    ),
    "insertCount": MessageLookupByLibrary.simpleMessage("Insert count"),
    "insertDuration": MessageLookupByLibrary.simpleMessage("Insert a duration"),
    "insertFieldNumber": MessageLookupByLibrary.simpleMessage(
      "Insert the field number",
    ),
    "insertHeight": MessageLookupByLibrary.simpleMessage("Insert height"),
    "insertInventoryId": MessageLookupByLibrary.simpleMessage(
      "Please, insert an ID for the inventory",
    ),
    "insertLocality": MessageLookupByLibrary.simpleMessage(
      "Please, insert locality name",
    ),
    "insertMaxSpecies": MessageLookupByLibrary.simpleMessage(
      "Insert the max of species",
    ),
    "insertNestSupport": MessageLookupByLibrary.simpleMessage(
      "Please, insert nest support",
    ),
    "insertObserver": MessageLookupByLibrary.simpleMessage("Insert observer"),
    "insertProportion": MessageLookupByLibrary.simpleMessage(
      "Insert proportion",
    ),
    "insertTitle": MessageLookupByLibrary.simpleMessage(
      "Insert a title for the journal entry",
    ),
    "insertValidNumber": MessageLookupByLibrary.simpleMessage(
      "Insert a valid number",
    ),
    "intervaledQualitativeLists": MessageLookupByLibrary.simpleMessage(
      "Interval qualitative lists",
    ),
    "invalidJsonFormatExpectedObjectOrArray":
        MessageLookupByLibrary.simpleMessage(
          "Invalid JSON format. Expected an object or an array.",
        ),
    "invalidLatitude": MessageLookupByLibrary.simpleMessage("Invalid latitude"),
    "invalidLongitude": MessageLookupByLibrary.simpleMessage(
      "Invalid longitude",
    ),
    "invalidNumericValue": MessageLookupByLibrary.simpleMessage(
      "Invalid numeric value",
    ),
    "inventories": MessageLookupByLibrary.simpleMessage("Inventories"),
    "inventoriesImportedSuccessfully": m30,
    "inventory": m31,
    "inventoryBanding": MessageLookupByLibrary.simpleMessage("Banding"),
    "inventoryCasual": MessageLookupByLibrary.simpleMessage(
      "Casual Observation",
    ),
    "inventoryData": m32,
    "inventoryDuration": m33,
    "inventoryExported": m34,
    "inventoryFound": m35,
    "inventoryFreeQualitative": MessageLookupByLibrary.simpleMessage(
      "Free Qualitative List",
    ),
    "inventoryId": MessageLookupByLibrary.simpleMessage("Inventory ID"),
    "inventoryIdAlreadyExists": MessageLookupByLibrary.simpleMessage(
      "This inventory ID already exists.",
    ),
    "inventoryIdUpdated": MessageLookupByLibrary.simpleMessage(
      "Inventory ID updated successfully!",
    ),
    "inventoryImportFailed": MessageLookupByLibrary.simpleMessage(
      "Inventory import failed.",
    ),
    "inventoryImportedSuccessfully": MessageLookupByLibrary.simpleMessage(
      "Inventory imported successfully!",
    ),
    "inventoryIntervalQualitative": MessageLookupByLibrary.simpleMessage(
      "Interval Qualitative List",
    ),
    "inventoryMackinnonList": MessageLookupByLibrary.simpleMessage(
      "Mackinnon List",
    ),
    "inventoryPointCount": MessageLookupByLibrary.simpleMessage("Point Count"),
    "inventoryPointDetection": MessageLookupByLibrary.simpleMessage(
      "Detection Point Count",
    ),
    "inventoryTimedQualitative": MessageLookupByLibrary.simpleMessage(
      "Timed Qualitative List",
    ),
    "inventoryTransectCount": MessageLookupByLibrary.simpleMessage(
      "Transect Count",
    ),
    "inventoryTransectDetection": MessageLookupByLibrary.simpleMessage(
      "Detection Transect Count",
    ),
    "inventoryType": MessageLookupByLibrary.simpleMessage("Inventory type"),
    "journalEntries": m36,
    "keepRunning": MessageLookupByLibrary.simpleMessage("Keep active"),
    "lastModifiedTime": MessageLookupByLibrary.simpleMessage(
      "Last modified time",
    ),
    "lastTime": MessageLookupByLibrary.simpleMessage("Last time"),
    "latitude": MessageLookupByLibrary.simpleMessage("Latitude"),
    "length": MessageLookupByLibrary.simpleMessage("Length"),
    "lightMode": MessageLookupByLibrary.simpleMessage("Light"),
    "listFinished": MessageLookupByLibrary.simpleMessage("List finished"),
    "listFinishedMessage": MessageLookupByLibrary.simpleMessage(
      "The list reached the maximum of species. Do you want to start the next list or finish now?",
    ),
    "localitiesSurveyed": m37,
    "locality": MessageLookupByLibrary.simpleMessage("Locality"),
    "locationError": MessageLookupByLibrary.simpleMessage("Location error"),
    "longitude": MessageLookupByLibrary.simpleMessage("Longitude"),
    "mackinnonLists": MessageLookupByLibrary.simpleMessage("Mackinnon lists"),
    "male": MessageLookupByLibrary.simpleMessage("Male"),
    "maleNameOrId": MessageLookupByLibrary.simpleMessage("Male name or ID"),
    "maxSpecies": MessageLookupByLibrary.simpleMessage("Max species"),
    "minutes": m38,
    "missingVegetationData": MessageLookupByLibrary.simpleMessage(
      "There is no vegetation data.",
    ),
    "missingWeatherData": MessageLookupByLibrary.simpleMessage(
      "There is no weather data.",
    ),
    "mustBeBiggerThanFive": MessageLookupByLibrary.simpleMessage(
      "Must be equal or higher than 5",
    ),
    "nest": m39,
    "nestData": m40,
    "nestExported": m41,
    "nestFate": MessageLookupByLibrary.simpleMessage("Nest fate"),
    "nestFateLost": MessageLookupByLibrary.simpleMessage("Lost"),
    "nestFateSuccess": MessageLookupByLibrary.simpleMessage("Success"),
    "nestFateUnknown": MessageLookupByLibrary.simpleMessage("Unknown"),
    "nestInfo": MessageLookupByLibrary.simpleMessage("Nest information"),
    "nestPhase": MessageLookupByLibrary.simpleMessage("Nest phase"),
    "nestRevision": MessageLookupByLibrary.simpleMessage("Nest revision"),
    "nestRevisionsMissing": MessageLookupByLibrary.simpleMessage(
      "There are no revisions for this nest. Add at least one revision.",
    ),
    "nestStageBuilding": MessageLookupByLibrary.simpleMessage("Building"),
    "nestStageHatching": MessageLookupByLibrary.simpleMessage("Hatching"),
    "nestStageInactive": MessageLookupByLibrary.simpleMessage("Inactive"),
    "nestStageIncubating": MessageLookupByLibrary.simpleMessage("Incubating"),
    "nestStageLaying": MessageLookupByLibrary.simpleMessage("Laying"),
    "nestStageNestling": MessageLookupByLibrary.simpleMessage("Nestling"),
    "nestStageUnknown": MessageLookupByLibrary.simpleMessage("Unknown"),
    "nestStatus": MessageLookupByLibrary.simpleMessage("Nest status"),
    "nestStatusActive": MessageLookupByLibrary.simpleMessage("Active"),
    "nestStatusInactive": MessageLookupByLibrary.simpleMessage("Inactive"),
    "nestStatusUnknown": MessageLookupByLibrary.simpleMessage("Unknown"),
    "nestSupport": MessageLookupByLibrary.simpleMessage("Nest support"),
    "nestling": m42,
    "nests": MessageLookupByLibrary.simpleMessage("Nests"),
    "nestsImportedSuccessfully": m43,
    "newEgg": MessageLookupByLibrary.simpleMessage("New egg"),
    "newInventory": MessageLookupByLibrary.simpleMessage("New inventory"),
    "newJournalEntry": MessageLookupByLibrary.simpleMessage(
      "New journal entry",
    ),
    "newNest": MessageLookupByLibrary.simpleMessage("New nest"),
    "newPoi": MessageLookupByLibrary.simpleMessage("New POI"),
    "newRevision": MessageLookupByLibrary.simpleMessage("New revision"),
    "newSpecimen": MessageLookupByLibrary.simpleMessage("New specimen"),
    "newVegetation": MessageLookupByLibrary.simpleMessage(
      "New vegetation record",
    ),
    "newWeather": MessageLookupByLibrary.simpleMessage("New weather record"),
    "nidoparasite": MessageLookupByLibrary.simpleMessage("Nidoparasite"),
    "nidoparasitismRate": MessageLookupByLibrary.simpleMessage(
      "nidoparasitism rate",
    ),
    "no": MessageLookupByLibrary.simpleMessage("No"),
    "noDataAvailable": MessageLookupByLibrary.simpleMessage(
      "No data available.",
    ),
    "noDataToExport": MessageLookupByLibrary.simpleMessage(
      "No data to export.",
    ),
    "noEggsFound": MessageLookupByLibrary.simpleMessage("No eggs recorded."),
    "noFileSelected": MessageLookupByLibrary.simpleMessage("No file selected."),
    "noImagesFound": MessageLookupByLibrary.simpleMessage("No images found."),
    "noInventoriesFound": MessageLookupByLibrary.simpleMessage(
      "No inventories found.",
    ),
    "noInventoriesFoundInFile": MessageLookupByLibrary.simpleMessage(
      "No inventories found in the imported file.",
    ),
    "noJournalEntriesFound": MessageLookupByLibrary.simpleMessage(
      "No journal entries found",
    ),
    "noNestsFound": MessageLookupByLibrary.simpleMessage("No nests found."),
    "noPoiFound": MessageLookupByLibrary.simpleMessage("No POI found."),
    "noPoisToExport": MessageLookupByLibrary.simpleMessage(
      "No POIs to export.",
    ),
    "noRevisionsFound": MessageLookupByLibrary.simpleMessage(
      "No revisions recorded.",
    ),
    "noSpeciesFound": MessageLookupByLibrary.simpleMessage(
      "No species recorded",
    ),
    "noSpecimenCollected": MessageLookupByLibrary.simpleMessage(
      "No specimen collected.",
    ),
    "noValidInventoriesFoundInFile": MessageLookupByLibrary.simpleMessage(
      "No valid inventories found in the imported file.",
    ),
    "noVegetationFound": MessageLookupByLibrary.simpleMessage(
      "No vegetation records.",
    ),
    "noWeatherFound": MessageLookupByLibrary.simpleMessage(
      "No weather records.",
    ),
    "notes": MessageLookupByLibrary.simpleMessage("Notes"),
    "observer": MessageLookupByLibrary.simpleMessage("Observer"),
    "observerAbbreviation": MessageLookupByLibrary.simpleMessage(
      "Observer abbreviation",
    ),
    "observerAbbreviationMissing": MessageLookupByLibrary.simpleMessage(
      "Observer abbreviation is missing. Please add it in the settings.",
    ),
    "observerSetting": MessageLookupByLibrary.simpleMessage(
      "Observer (abbreviation)",
    ),
    "observers": m44,
    "ok": MessageLookupByLibrary.simpleMessage("OK"),
    "openSourceLicenses": MessageLookupByLibrary.simpleMessage(
      "Open Source Licenses",
    ),
    "optional": MessageLookupByLibrary.simpleMessage("* optional"),
    "outOfSample": MessageLookupByLibrary.simpleMessage("Out of the sample"),
    "pause": MessageLookupByLibrary.simpleMessage("Pause"),
    "pending": MessageLookupByLibrary.simpleMessage("Pending"),
    "perSpecies": MessageLookupByLibrary.simpleMessage("Per species"),
    "permissionDenied": MessageLookupByLibrary.simpleMessage(
      "Permission denied.",
    ),
    "permissionDeniedPermanently": MessageLookupByLibrary.simpleMessage(
      "Permission denied permanently.",
    ),
    "philornisLarvaePresent": MessageLookupByLibrary.simpleMessage(
      "Philornis larvae present",
    ),
    "plantSpeciesOrSupportType": MessageLookupByLibrary.simpleMessage(
      "Plant species or support type",
    ),
    "platinumSponsor": MessageLookupByLibrary.simpleMessage("Platinum Sponsor"),
    "poi": MessageLookupByLibrary.simpleMessage("POI"),
    "pointCounts": MessageLookupByLibrary.simpleMessage("Point counts"),
    "poisRecorded": m45,
    "precipitation": MessageLookupByLibrary.simpleMessage("Precipitation"),
    "precipitationDrizzle": MessageLookupByLibrary.simpleMessage("Drizzle"),
    "precipitationFog": MessageLookupByLibrary.simpleMessage("Fog"),
    "precipitationFrost": MessageLookupByLibrary.simpleMessage("Frost"),
    "precipitationHail": MessageLookupByLibrary.simpleMessage("Hail"),
    "precipitationMist": MessageLookupByLibrary.simpleMessage("Mist"),
    "precipitationNone": MessageLookupByLibrary.simpleMessage("None"),
    "precipitationRain": MessageLookupByLibrary.simpleMessage("Rain"),
    "precipitationShowers": MessageLookupByLibrary.simpleMessage("Showers"),
    "precipitationSnow": MessageLookupByLibrary.simpleMessage("Snow"),
    "proportion": MessageLookupByLibrary.simpleMessage("Proportion"),
    "reactivate": MessageLookupByLibrary.simpleMessage("Reactivate"),
    "reactivateInventory": MessageLookupByLibrary.simpleMessage(
      "Reactivate inventory",
    ),
    "recordTime": MessageLookupByLibrary.simpleMessage("Record time"),
    "recordedSpecies": MessageLookupByLibrary.simpleMessage("recorded species"),
    "recordsByHour": MessageLookupByLibrary.simpleMessage("Records by hour"),
    "recordsPerMonth": MessageLookupByLibrary.simpleMessage(
      "Records per month",
    ),
    "recordsPerYear": MessageLookupByLibrary.simpleMessage("Records per year"),
    "refresh": MessageLookupByLibrary.simpleMessage("Refresh"),
    "refreshList": MessageLookupByLibrary.simpleMessage("Refresh"),
    "relativeAbundance": MessageLookupByLibrary.simpleMessage(
      "relative abundance",
    ),
    "relativeFrequency": MessageLookupByLibrary.simpleMessage(
      "relative frequency",
    ),
    "relativeHumidity": MessageLookupByLibrary.simpleMessage(
      "Relative humidity",
    ),
    "relativeHumidityRangeError": MessageLookupByLibrary.simpleMessage(
      "Relative humidity must be between 0 and 100",
    ),
    "remindMissingVegetationData": MessageLookupByLibrary.simpleMessage(
      "Remind missing vegetation data",
    ),
    "remindMissingWeatherData": MessageLookupByLibrary.simpleMessage(
      "Remind missing weather data",
    ),
    "removeSpeciesFromSample": MessageLookupByLibrary.simpleMessage(
      "Remove from the sample",
    ),
    "reportSpeciesByInventory": MessageLookupByLibrary.simpleMessage(
      "Species by inventory",
    ),
    "requiredField": MessageLookupByLibrary.simpleMessage("* required"),
    "restore": MessageLookupByLibrary.simpleMessage("Restore"),
    "restoreBackup": MessageLookupByLibrary.simpleMessage("Restore backup"),
    "restoreBackupConfirmation": MessageLookupByLibrary.simpleMessage(
      "Current data will be replaced by the backup and some data could be lost. Are you sure you want to proceed?",
    ),
    "restoringData": MessageLookupByLibrary.simpleMessage("Restoring data"),
    "resume": MessageLookupByLibrary.simpleMessage("Resume"),
    "revision": m46,
    "sampleTime": MessageLookupByLibrary.simpleMessage("Sample time"),
    "save": MessageLookupByLibrary.simpleMessage("Save"),
    "seeAll": MessageLookupByLibrary.simpleMessage("See all"),
    "selectAll": MessageLookupByLibrary.simpleMessage("Select all"),
    "selectInventoryToView": MessageLookupByLibrary.simpleMessage(
      "Select an inventory to view its details",
    ),
    "selectInventoryType": MessageLookupByLibrary.simpleMessage(
      "Please, select an inventory type",
    ),
    "selectMode": MessageLookupByLibrary.simpleMessage("Select the mode"),
    "selectPrecipitation": MessageLookupByLibrary.simpleMessage(
      "Select precipitation",
    ),
    "selectSpecies": MessageLookupByLibrary.simpleMessage("Select a species"),
    "selectSpeciesToShowStats": MessageLookupByLibrary.simpleMessage(
      "Select a species to show the statistics",
    ),
    "selectedInventories": MessageLookupByLibrary.simpleMessage(
      "selected inventories",
    ),
    "selectedNests": m47,
    "sendBackupTo": MessageLookupByLibrary.simpleMessage("Send backup to..."),
    "settings": MessageLookupByLibrary.simpleMessage("Settings"),
    "shareImage": MessageLookupByLibrary.simpleMessage("Share image"),
    "shrubs": MessageLookupByLibrary.simpleMessage("Shrubs"),
    "simultaneousInventories": MessageLookupByLibrary.simpleMessage(
      "Simultaneous inventories",
    ),
    "simultaneousLimitReached": MessageLookupByLibrary.simpleMessage(
      "Limit of simultaneous inventories reached.",
    ),
    "siteAbbreviation": MessageLookupByLibrary.simpleMessage(
      "Site name or abbreviation",
    ),
    "sortAscending": MessageLookupByLibrary.simpleMessage("Sort ascending"),
    "sortBy": MessageLookupByLibrary.simpleMessage("Sort by"),
    "sortByLastModified": MessageLookupByLibrary.simpleMessage(
      "Sort by Last Modified Time",
    ),
    "sortByName": MessageLookupByLibrary.simpleMessage("Sort by Name"),
    "sortByTime": MessageLookupByLibrary.simpleMessage("Sort by Time"),
    "sortByTitle": MessageLookupByLibrary.simpleMessage("Sort by Title"),
    "sortDescending": MessageLookupByLibrary.simpleMessage("Sort descending"),
    "species": m48,
    "speciesAccumulated": MessageLookupByLibrary.simpleMessage(
      "Species accumulated",
    ),
    "speciesAccumulationCurve": MessageLookupByLibrary.simpleMessage(
      "Species accumulation",
    ),
    "speciesAcronym": m49,
    "speciesCount": m50,
    "speciesCounted": MessageLookupByLibrary.simpleMessage("Species counted"),
    "speciesInfo": MessageLookupByLibrary.simpleMessage("Species information"),
    "speciesName": MessageLookupByLibrary.simpleMessage("Species name"),
    "speciesNotes": MessageLookupByLibrary.simpleMessage("Species notes"),
    "speciesPerList": m51,
    "speciesPerListTitle": MessageLookupByLibrary.simpleMessage(
      "Species per list",
    ),
    "speciesRichness": MessageLookupByLibrary.simpleMessage("Species richness"),
    "speciesSearch": MessageLookupByLibrary.simpleMessage("Species search"),
    "speciesUpgradeFailed": MessageLookupByLibrary.simpleMessage(
      "Species upgrade failed",
    ),
    "specimenBlood": MessageLookupByLibrary.simpleMessage("Blood"),
    "specimenBones": MessageLookupByLibrary.simpleMessage("Bones"),
    "specimenClaw": MessageLookupByLibrary.simpleMessage("Claw"),
    "specimenData": m52,
    "specimenEgg": MessageLookupByLibrary.simpleMessage("Egg"),
    "specimenExported": m53,
    "specimenFeathers": MessageLookupByLibrary.simpleMessage("Feathers"),
    "specimenFeces": MessageLookupByLibrary.simpleMessage("Feces"),
    "specimenNest": MessageLookupByLibrary.simpleMessage("Nest"),
    "specimenParasites": MessageLookupByLibrary.simpleMessage("Parasites"),
    "specimenPartialCarcass": MessageLookupByLibrary.simpleMessage(
      "Partial carcass",
    ),
    "specimenRegurgite": MessageLookupByLibrary.simpleMessage("Regurgite"),
    "specimenSwab": MessageLookupByLibrary.simpleMessage("Swab"),
    "specimenTissues": MessageLookupByLibrary.simpleMessage("Tissues"),
    "specimenType": MessageLookupByLibrary.simpleMessage("Specimen type"),
    "specimenWholeCarcass": MessageLookupByLibrary.simpleMessage(
      "Whole carcass",
    ),
    "specimens": m54,
    "specimensImportedSuccessfully": m55,
    "startInventory": MessageLookupByLibrary.simpleMessage("Start inventory"),
    "startNextList": MessageLookupByLibrary.simpleMessage("Start next list"),
    "startTime": MessageLookupByLibrary.simpleMessage("Start time"),
    "statistics": MessageLookupByLibrary.simpleMessage("Statistics"),
    "suggestFeatureOrReportIssue": MessageLookupByLibrary.simpleMessage(
      "Suggest a feature or report an issue",
    ),
    "surveyHours": MessageLookupByLibrary.simpleMessage("survey hours"),
    "systemMode": MessageLookupByLibrary.simpleMessage("System theme"),
    "temperature": MessageLookupByLibrary.simpleMessage("Temperature"),
    "timeFound": MessageLookupByLibrary.simpleMessage("Date and time found"),
    "timeMinutes": MessageLookupByLibrary.simpleMessage(
      "Time (10 minutes intervals)",
    ),
    "timedQualitativeLists": MessageLookupByLibrary.simpleMessage(
      "Timed qualitative lists",
    ),
    "title": MessageLookupByLibrary.simpleMessage("Title"),
    "topSpecies": m56,
    "totalAbundance": MessageLookupByLibrary.simpleMessage("total abundance"),
    "totalIndividuals": MessageLookupByLibrary.simpleMessage(
      "Total Individuals",
    ),
    "totalOfObservers": MessageLookupByLibrary.simpleMessage(
      "Total of observers",
    ),
    "totalRecords": MessageLookupByLibrary.simpleMessage("Total of records"),
    "totalRichness": MessageLookupByLibrary.simpleMessage("total richness"),
    "totalSpecies": MessageLookupByLibrary.simpleMessage("Total Species"),
    "totalSpeciesWithinSample": MessageLookupByLibrary.simpleMessage(
      "Species within sample",
    ),
    "trees": MessageLookupByLibrary.simpleMessage("Trees"),
    "vegetation": MessageLookupByLibrary.simpleMessage("Vegetation"),
    "vegetationData": MessageLookupByLibrary.simpleMessage("Vegetation data"),
    "viewLicense": MessageLookupByLibrary.simpleMessage("View License"),
    "warningTitle": MessageLookupByLibrary.simpleMessage("Warning"),
    "weather": MessageLookupByLibrary.simpleMessage("Weather"),
    "weatherData": MessageLookupByLibrary.simpleMessage("Weather data"),
    "weatherRecord": MessageLookupByLibrary.simpleMessage("weather record"),
    "weight": MessageLookupByLibrary.simpleMessage("Weight"),
    "width": MessageLookupByLibrary.simpleMessage("Width"),
    "windDirection": MessageLookupByLibrary.simpleMessage("Wind direction"),
    "windSpeed": MessageLookupByLibrary.simpleMessage("Wind speed"),
    "windSpeedRangeError": MessageLookupByLibrary.simpleMessage(
      "Must be between 0 and 12 bft",
    ),
    "withinSample": MessageLookupByLibrary.simpleMessage("Within the sample"),
    "yes": MessageLookupByLibrary.simpleMessage("Yes"),
  };
}
