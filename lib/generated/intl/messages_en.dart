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
      "Are you sure you want to delete ${Intl.plural(howMany, one: '${Intl.gender(gender, female: 'this', male: 'this', other: 'this')}', other: '${Intl.gender(gender, female: 'these', male: 'these', other: 'these')}')} ${what}?";

  static String m1(howMany) =>
      "${Intl.plural(howMany, one: 'Egg', other: 'Eggs')}";

  static String m2(howMany, errorMessage) =>
      "Error exporting ${Intl.plural(howMany, one: 'inventory', other: 'inventories')}: ${errorMessage}";

  static String m3(howMany, errorMessage) =>
      "Error exporting ${Intl.plural(howMany, one: 'nest', other: 'nests')}: ${errorMessage}";

  static String m4(howMany, errorMessage) =>
      "Error exporting ${Intl.plural(howMany, one: 'specimen', other: 'specimens')}: ${errorMessage}";

  static String m5(errorMessage) => "Error inactivating nest: ${errorMessage}";

  static String m6(what) => "Export ${what}";

  static String m7(what) => "Export all ${what}";

  static String m8(howMany) =>
      "${Intl.plural(howMany, one: 'Image', other: 'Images')}";

  static String m9(howMany) =>
      "${Intl.plural(howMany, one: 'individual', other: 'individuals')}";

  static String m10(howMany) =>
      "${Intl.plural(howMany, one: 'inventory', other: 'inventories')}";

  static String m11(howMany) =>
      "${Intl.plural(howMany, one: 'Inventory data', other: 'Inventories data')}";

  static String m12(howMany) =>
      "${Intl.plural(howMany, one: '1 minute', other: '${howMany} minutes')} of duration";

  static String m13(howMany) =>
      "${Intl.plural(howMany, one: 'Inventory exported!', other: 'Inventories exported!')}";

  static String m14(howMany) =>
      "${Intl.plural(howMany, one: 'minute', other: 'minutes')}";

  static String m15(howMany) =>
      "${Intl.plural(howMany, one: 'nest', other: 'nests')}";

  static String m16(howMany) =>
      "${Intl.plural(howMany, one: 'Nest data', other: 'Nests data')}";

  static String m17(howMany) =>
      "${Intl.plural(howMany, one: 'Nest exported!', other: 'Nests exported!')}";

  static String m18(howMany) =>
      "${Intl.plural(howMany, one: 'Nestling', other: 'Nestlings')}";

  static String m19(howMany) =>
      "${Intl.plural(howMany, one: 'Revision', other: 'Revisions')}";

  static String m20(howMany) =>
      "${Intl.plural(howMany, one: 'Species', other: 'Species')}";

  static String m21(howMany) =>
      "${Intl.plural(howMany, one: 'sp.', other: 'spp.')}";

  static String m22(howMany) =>
      "${Intl.plural(howMany, one: '1 species', other: '${howMany} species')}";

  static String m23(howMany) =>
      "${Intl.plural(howMany, one: '1 species', other: '${howMany} species')} per list";

  static String m24(howMany) =>
      "${Intl.plural(howMany, one: 'Specimen data', other: 'Specimens data')}";

  static String m25(howMany) =>
      "${Intl.plural(howMany, one: 'Specimen exported!', other: 'Specimens exported!')}";

  static String m26(howMany) =>
      "${Intl.plural(howMany, one: 'Specimen', other: 'Specimens')}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "about": MessageLookupByLibrary.simpleMessage("About the app"),
        "active": MessageLookupByLibrary.simpleMessage("Active"),
        "addEgg": MessageLookupByLibrary.simpleMessage("Add egg"),
        "addImage": MessageLookupByLibrary.simpleMessage("Add image"),
        "addPoi": MessageLookupByLibrary.simpleMessage("Add POI"),
        "appearance": MessageLookupByLibrary.simpleMessage("Appearance"),
        "camera": MessageLookupByLibrary.simpleMessage("Camera"),
        "cancel": MessageLookupByLibrary.simpleMessage("Cancel"),
        "cloudCover": MessageLookupByLibrary.simpleMessage("Cloud cover"),
        "confirmDelete": MessageLookupByLibrary.simpleMessage("Confirm delete"),
        "confirmDeleteMessage": m0,
        "confirmFate": MessageLookupByLibrary.simpleMessage("Confirm fate"),
        "confirmFinish": MessageLookupByLibrary.simpleMessage("Confirm finish"),
        "confirmFinishMessage": MessageLookupByLibrary.simpleMessage(
            "Are you sure you want to finish this inventory?"),
        "count": MessageLookupByLibrary.simpleMessage("Count"),
        "dangerZone": MessageLookupByLibrary.simpleMessage("Danger zone"),
        "darkMode": MessageLookupByLibrary.simpleMessage("Dark"),
        "dataDeleted": MessageLookupByLibrary.simpleMessage(
            "App data deleted successfully!"),
        "decreaseIndividuals":
            MessageLookupByLibrary.simpleMessage("Decrease individuals count"),
        "delete": MessageLookupByLibrary.simpleMessage("Delete"),
        "deleteAppData":
            MessageLookupByLibrary.simpleMessage("Delete the app data"),
        "deleteData": MessageLookupByLibrary.simpleMessage("Delete data"),
        "deleteDataMessage": MessageLookupByLibrary.simpleMessage(
            "Are you sure you want to delete all app data? This action cannot be undone."),
        "deleteEgg": MessageLookupByLibrary.simpleMessage("Delete egg"),
        "deleteImage": MessageLookupByLibrary.simpleMessage("Delete image"),
        "deleteInventory":
            MessageLookupByLibrary.simpleMessage("Delete inventory"),
        "deleteNest": MessageLookupByLibrary.simpleMessage("Delete nest"),
        "deletePoi": MessageLookupByLibrary.simpleMessage("Delete POI"),
        "deleteRevision":
            MessageLookupByLibrary.simpleMessage("Delete nest revision"),
        "deleteSpecimen":
            MessageLookupByLibrary.simpleMessage("Delete specimen"),
        "deleteVegetation":
            MessageLookupByLibrary.simpleMessage("Delete vegetation record"),
        "deleteWeather":
            MessageLookupByLibrary.simpleMessage("Delete weather record"),
        "distribution": MessageLookupByLibrary.simpleMessage("Distribution"),
        "distributionContinuousCoverWithGaps":
            MessageLookupByLibrary.simpleMessage("Continuous with gaps"),
        "distributionContinuousDenseCover":
            MessageLookupByLibrary.simpleMessage("Continuous and dense"),
        "distributionContinuousDenseCoverWithEdge":
            MessageLookupByLibrary.simpleMessage(
                "Continuous with edge between strata"),
        "distributionFewPatches":
            MessageLookupByLibrary.simpleMessage("Few patches"),
        "distributionFewPatchesSparseIndividuals":
            MessageLookupByLibrary.simpleMessage(
                "Few patches and isolated individuals"),
        "distributionFewSparseIndividuals":
            MessageLookupByLibrary.simpleMessage("Few sparse individuals"),
        "distributionHighDensityIndividuals":
            MessageLookupByLibrary.simpleMessage(
                "Isolated individuals in high density"),
        "distributionManyPatches":
            MessageLookupByLibrary.simpleMessage("Many equidistant patches"),
        "distributionManyPatchesSparseIndividuals":
            MessageLookupByLibrary.simpleMessage(
                "Many patches and scattered individuals"),
        "distributionManySparseIndividuals":
            MessageLookupByLibrary.simpleMessage("Many sparse individuals"),
        "distributionNone": MessageLookupByLibrary.simpleMessage("None"),
        "distributionOnePatch":
            MessageLookupByLibrary.simpleMessage("One patch"),
        "distributionOnePatchFewSparseIndividuals":
            MessageLookupByLibrary.simpleMessage(
                "One patch and isolated individuals"),
        "distributionOnePatchManySparseIndividuals":
            MessageLookupByLibrary.simpleMessage(
                "Patch and many isolated individuals"),
        "distributionRare": MessageLookupByLibrary.simpleMessage("Rare"),
        "duration": MessageLookupByLibrary.simpleMessage("Duration"),
        "durationMin": MessageLookupByLibrary.simpleMessage("Duration (min)"),
        "editCount": MessageLookupByLibrary.simpleMessage("Edit count"),
        "editImageNotes":
            MessageLookupByLibrary.simpleMessage("Edit image notes"),
        "editNotes": MessageLookupByLibrary.simpleMessage("Edit notes"),
        "egg": m1,
        "eggShape": MessageLookupByLibrary.simpleMessage("Egg shape"),
        "eggShapeBiconical": MessageLookupByLibrary.simpleMessage("Biconical"),
        "eggShapeConical": MessageLookupByLibrary.simpleMessage("Conical"),
        "eggShapeCylindrical":
            MessageLookupByLibrary.simpleMessage("Cylindrical"),
        "eggShapeElliptical":
            MessageLookupByLibrary.simpleMessage("Elliptical"),
        "eggShapeLongitudinal":
            MessageLookupByLibrary.simpleMessage("Longitudinal"),
        "eggShapeOval": MessageLookupByLibrary.simpleMessage("Oval"),
        "eggShapePyriform": MessageLookupByLibrary.simpleMessage("Pyriform"),
        "eggShapeSpherical": MessageLookupByLibrary.simpleMessage("Spherical"),
        "errorEggAlreadyExists": MessageLookupByLibrary.simpleMessage(
            "An egg with this field number already exists."),
        "errorExportingInventory": m2,
        "errorExportingNest": m3,
        "errorExportingSpecimen": m4,
        "errorGettingLocation":
            MessageLookupByLibrary.simpleMessage("Error getting location."),
        "errorInactivatingNest": m5,
        "errorInsertingInventory":
            MessageLookupByLibrary.simpleMessage("Error inserting inventory"),
        "errorInsertingVegetation": MessageLookupByLibrary.simpleMessage(
            "Error inserting vegetation data"),
        "errorInsertingWeather": MessageLookupByLibrary.simpleMessage(
            "Error inserting weather data"),
        "errorNestAlreadyExists": MessageLookupByLibrary.simpleMessage(
            "A nest with this field number already exists."),
        "errorSavingEgg":
            MessageLookupByLibrary.simpleMessage("Error saving egg."),
        "errorSavingNest":
            MessageLookupByLibrary.simpleMessage("Error saving nest."),
        "errorSavingRevision":
            MessageLookupByLibrary.simpleMessage("Error saving nest revision."),
        "errorSavingSpecimen":
            MessageLookupByLibrary.simpleMessage("Error saving specimen."),
        "errorSpecimenAlreadyExists": MessageLookupByLibrary.simpleMessage(
            "A specimen with this field number already exists."),
        "export": m6,
        "exportAll": m7,
        "female": MessageLookupByLibrary.simpleMessage("Female"),
        "fieldNumber": MessageLookupByLibrary.simpleMessage("Field number"),
        "findInventories":
            MessageLookupByLibrary.simpleMessage("Find inventories..."),
        "findNests": MessageLookupByLibrary.simpleMessage("Find nests..."),
        "findSpecies": MessageLookupByLibrary.simpleMessage("Find species"),
        "findSpecimens":
            MessageLookupByLibrary.simpleMessage("Find specimens..."),
        "finish": MessageLookupByLibrary.simpleMessage("Finish"),
        "finishInventory":
            MessageLookupByLibrary.simpleMessage("Finish inventory"),
        "finished": MessageLookupByLibrary.simpleMessage("Finished"),
        "gallery": MessageLookupByLibrary.simpleMessage("Gallery"),
        "generateId": MessageLookupByLibrary.simpleMessage("Generate ID"),
        "height": MessageLookupByLibrary.simpleMessage("Height"),
        "heightAboveGround":
            MessageLookupByLibrary.simpleMessage("Height above ground"),
        "helpers": MessageLookupByLibrary.simpleMessage("Nest helpers"),
        "herbs": MessageLookupByLibrary.simpleMessage("Herbs"),
        "host": MessageLookupByLibrary.simpleMessage("Host"),
        "imageDetails": MessageLookupByLibrary.simpleMessage("Image details"),
        "images": m8,
        "inactive": MessageLookupByLibrary.simpleMessage("Inactive"),
        "increaseIndividuals":
            MessageLookupByLibrary.simpleMessage("Increase individuals count"),
        "individual": m9,
        "individualsCount":
            MessageLookupByLibrary.simpleMessage("Individuals count"),
        "insertDuration":
            MessageLookupByLibrary.simpleMessage("Insert a duration"),
        "insertFieldNumber": MessageLookupByLibrary.simpleMessage(
            "Please, insert the field number"),
        "insertHeight": MessageLookupByLibrary.simpleMessage("Insert height"),
        "insertInventoryId": MessageLookupByLibrary.simpleMessage(
            "Please, insert an ID for the inventory"),
        "insertLocality": MessageLookupByLibrary.simpleMessage(
            "Please, insert locality name"),
        "insertMaxSpecies":
            MessageLookupByLibrary.simpleMessage("Insert the max of species"),
        "insertNestSupport":
            MessageLookupByLibrary.simpleMessage("Please, insert nest support"),
        "insertProportion":
            MessageLookupByLibrary.simpleMessage("Insert proportion"),
        "inventories": MessageLookupByLibrary.simpleMessage("Inventories"),
        "inventory": m10,
        "inventoryBanding": MessageLookupByLibrary.simpleMessage("Banding"),
        "inventoryCasual":
            MessageLookupByLibrary.simpleMessage("Casual Observation"),
        "inventoryData": m11,
        "inventoryDuration": m12,
        "inventoryExported": m13,
        "inventoryFreeQualitative":
            MessageLookupByLibrary.simpleMessage("Free Qualitative List"),
        "inventoryId": MessageLookupByLibrary.simpleMessage("Inventory ID *"),
        "inventoryIdAlreadyExists": MessageLookupByLibrary.simpleMessage(
            "This inventory ID already exists."),
        "inventoryMackinnonList":
            MessageLookupByLibrary.simpleMessage("Mackinnon List"),
        "inventoryPointCount":
            MessageLookupByLibrary.simpleMessage("Point Count"),
        "inventoryTimedQualitative":
            MessageLookupByLibrary.simpleMessage("Timed Qualitative List"),
        "inventoryTransectionCount":
            MessageLookupByLibrary.simpleMessage("Transection Count"),
        "inventoryType":
            MessageLookupByLibrary.simpleMessage("Inventory type *"),
        "length": MessageLookupByLibrary.simpleMessage("Length"),
        "lightMode": MessageLookupByLibrary.simpleMessage("Light"),
        "listFinished": MessageLookupByLibrary.simpleMessage("List finished"),
        "listFinishedMessage": MessageLookupByLibrary.simpleMessage(
            "The list reached the maximum of species. Do you want to start the next list or finish now?"),
        "locality": MessageLookupByLibrary.simpleMessage("Locality"),
        "mackinnonLists":
            MessageLookupByLibrary.simpleMessage("Mackinnon lists"),
        "male": MessageLookupByLibrary.simpleMessage("Male"),
        "maxSpecies": MessageLookupByLibrary.simpleMessage("Max species"),
        "minutes": m14,
        "mustBeBiggerThanFive": MessageLookupByLibrary.simpleMessage(
            "Must be equal or higher than 5"),
        "nest": m15,
        "nestData": m16,
        "nestExported": m17,
        "nestFate": MessageLookupByLibrary.simpleMessage("Nest fate *"),
        "nestInfo": MessageLookupByLibrary.simpleMessage("Nest information"),
        "nestPhase": MessageLookupByLibrary.simpleMessage("Nest phase"),
        "nestRevision": MessageLookupByLibrary.simpleMessage("Nest revision"),
        "nestStageBuilding": MessageLookupByLibrary.simpleMessage("Building"),
        "nestStageHatching": MessageLookupByLibrary.simpleMessage("Hatching"),
        "nestStageInactive": MessageLookupByLibrary.simpleMessage("Inactive"),
        "nestStageIncubating":
            MessageLookupByLibrary.simpleMessage("Incubating"),
        "nestStageLaying": MessageLookupByLibrary.simpleMessage("Laying"),
        "nestStageNestling": MessageLookupByLibrary.simpleMessage("Nestling"),
        "nestStageUnknown": MessageLookupByLibrary.simpleMessage("Unknown"),
        "nestStatus": MessageLookupByLibrary.simpleMessage("Nest status"),
        "nestStatusActive": MessageLookupByLibrary.simpleMessage("Active"),
        "nestStatusInactive": MessageLookupByLibrary.simpleMessage("Inactive"),
        "nestStatusUnknown": MessageLookupByLibrary.simpleMessage("Unknown"),
        "nestSupport": MessageLookupByLibrary.simpleMessage("Nest support"),
        "nestling": m18,
        "nests": MessageLookupByLibrary.simpleMessage("Nests"),
        "newInventory": MessageLookupByLibrary.simpleMessage("New inventory"),
        "newNest": MessageLookupByLibrary.simpleMessage("New nest"),
        "newPoi": MessageLookupByLibrary.simpleMessage("New POI"),
        "newSpecimen": MessageLookupByLibrary.simpleMessage("New specimen"),
        "nidoparasite": MessageLookupByLibrary.simpleMessage("Nidoparasite"),
        "noEggsFound":
            MessageLookupByLibrary.simpleMessage("No eggs recorded."),
        "noImagesFound":
            MessageLookupByLibrary.simpleMessage("No images found."),
        "noInventoriesFound":
            MessageLookupByLibrary.simpleMessage("No inventories found."),
        "noNestsFound": MessageLookupByLibrary.simpleMessage("No nests found."),
        "noPoiFound": MessageLookupByLibrary.simpleMessage("No POI found."),
        "noRevisionsFound":
            MessageLookupByLibrary.simpleMessage("No revisions recorded."),
        "noSpecimenCollected":
            MessageLookupByLibrary.simpleMessage("No specimen collected."),
        "noVegetationFound":
            MessageLookupByLibrary.simpleMessage("No vegetation records."),
        "noWeatherFound":
            MessageLookupByLibrary.simpleMessage("No weather records."),
        "notes": MessageLookupByLibrary.simpleMessage("Notes"),
        "observer": MessageLookupByLibrary.simpleMessage("Observer"),
        "observerAcronym":
            MessageLookupByLibrary.simpleMessage("Observador acronym"),
        "observerSetting":
            MessageLookupByLibrary.simpleMessage("Observer (acronym)"),
        "ok": MessageLookupByLibrary.simpleMessage("OK"),
        "optional": MessageLookupByLibrary.simpleMessage("* optional"),
        "outOfSample":
            MessageLookupByLibrary.simpleMessage("Out of the sample"),
        "pause": MessageLookupByLibrary.simpleMessage("Pause"),
        "permissionDenied":
            MessageLookupByLibrary.simpleMessage("Permission denied."),
        "permissionDeniedPermanently": MessageLookupByLibrary.simpleMessage(
            "Permission denied permanently."),
        "philornisLarvaePresent":
            MessageLookupByLibrary.simpleMessage("Philornis larvae present"),
        "poi": MessageLookupByLibrary.simpleMessage("POI"),
        "pointCounts": MessageLookupByLibrary.simpleMessage("Count points"),
        "precipitation":
            MessageLookupByLibrary.simpleMessage("Precipitation *"),
        "precipitationDrizzle": MessageLookupByLibrary.simpleMessage("Drizzle"),
        "precipitationFog": MessageLookupByLibrary.simpleMessage("Fog"),
        "precipitationMist": MessageLookupByLibrary.simpleMessage("Mist"),
        "precipitationNone": MessageLookupByLibrary.simpleMessage("None"),
        "precipitationRain": MessageLookupByLibrary.simpleMessage("Rain"),
        "proportion": MessageLookupByLibrary.simpleMessage("Proportion"),
        "requiredField": MessageLookupByLibrary.simpleMessage("* required"),
        "resume": MessageLookupByLibrary.simpleMessage("Resume"),
        "revision": m19,
        "save": MessageLookupByLibrary.simpleMessage("Save"),
        "selectInventoryType": MessageLookupByLibrary.simpleMessage(
            "Please, select an inventory type"),
        "selectMode": MessageLookupByLibrary.simpleMessage("Select the mode"),
        "selectPrecipitation":
            MessageLookupByLibrary.simpleMessage("Select precipitation"),
        "selectSpecies":
            MessageLookupByLibrary.simpleMessage("Please, select a species"),
        "settings": MessageLookupByLibrary.simpleMessage("Settings"),
        "shareImage": MessageLookupByLibrary.simpleMessage("Share image"),
        "shrubs": MessageLookupByLibrary.simpleMessage("Shrubs"),
        "simultaneousInventories":
            MessageLookupByLibrary.simpleMessage("Simultaneous inventories"),
        "simultaneousLimitReached": MessageLookupByLibrary.simpleMessage(
            "Limit of simultaneous inventories reached."),
        "siteAcronym":
            MessageLookupByLibrary.simpleMessage("Site name or acronym"),
        "species": m20,
        "speciesAcronym": m21,
        "speciesCount": m22,
        "speciesInfo":
            MessageLookupByLibrary.simpleMessage("Species information"),
        "speciesPerList": m23,
        "speciesPerListTitle":
            MessageLookupByLibrary.simpleMessage("Species per list"),
        "specimenBlood": MessageLookupByLibrary.simpleMessage("Blood"),
        "specimenBones": MessageLookupByLibrary.simpleMessage("Bones"),
        "specimenClaw": MessageLookupByLibrary.simpleMessage("Claw"),
        "specimenData": m24,
        "specimenEgg": MessageLookupByLibrary.simpleMessage("Egg"),
        "specimenExported": m25,
        "specimenFeathers": MessageLookupByLibrary.simpleMessage("Feathers"),
        "specimenFeces": MessageLookupByLibrary.simpleMessage("Feces"),
        "specimenNest": MessageLookupByLibrary.simpleMessage("Nest"),
        "specimenParasites": MessageLookupByLibrary.simpleMessage("Parasites"),
        "specimenPartialCarcass":
            MessageLookupByLibrary.simpleMessage("Partial carcass"),
        "specimenRegurgite": MessageLookupByLibrary.simpleMessage("Regurgite"),
        "specimenSwab": MessageLookupByLibrary.simpleMessage("Swab"),
        "specimenTissues": MessageLookupByLibrary.simpleMessage("Tissues"),
        "specimenType": MessageLookupByLibrary.simpleMessage("Specimen type"),
        "specimenWholeCarcass":
            MessageLookupByLibrary.simpleMessage("Whole carcass"),
        "specimens": m26,
        "startInventory":
            MessageLookupByLibrary.simpleMessage("Start inventory"),
        "startNextList":
            MessageLookupByLibrary.simpleMessage("Start next list"),
        "systemMode": MessageLookupByLibrary.simpleMessage("System theme"),
        "temperature": MessageLookupByLibrary.simpleMessage("Temperature"),
        "timeFound":
            MessageLookupByLibrary.simpleMessage("Date and time found"),
        "timedQualitativeLists":
            MessageLookupByLibrary.simpleMessage("Timed qualitative lists"),
        "trees": MessageLookupByLibrary.simpleMessage("Trees"),
        "vegetation": MessageLookupByLibrary.simpleMessage("Vegetation"),
        "vegetationData":
            MessageLookupByLibrary.simpleMessage("Vegetation data"),
        "weather": MessageLookupByLibrary.simpleMessage("Weather"),
        "weatherData": MessageLookupByLibrary.simpleMessage("Weather data"),
        "weatherRecord": MessageLookupByLibrary.simpleMessage("weather record"),
        "weight": MessageLookupByLibrary.simpleMessage("Weight"),
        "width": MessageLookupByLibrary.simpleMessage("Width"),
        "windSpeed": MessageLookupByLibrary.simpleMessage("Wind speed"),
        "withinSample":
            MessageLookupByLibrary.simpleMessage("Within the sample")
      };
}
