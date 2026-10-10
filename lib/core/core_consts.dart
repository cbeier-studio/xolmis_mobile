import 'package:material_ui/material_ui.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../generated/l10n.dart';

/// Minimum width (in dp) used to switch to tablet-oriented layouts.
const double kTabletBreakpoint = 600.0;

/// Minimum width (in dp) used to switch to desktop-oriented layouts.
const double kDesktopBreakpoint = 840.0;

/// Default width (in dp) used by side sheets on large screens.
const double kSideSheetWidth = 360.0;

/// Latest bundled species taxonomy update version.
const int kCurrentSpeciesUpdateVersion = 2025;

/// Shared preferences key that stores the startup module index.
const String kStartupModulePreferenceKey = 'startupModuleIndex';

/// Shared preferences key that stores import behavior for existing records.
const String kImportExistingRecordsPolicyPreferenceKey = 'importExistingRecordsPolicy';

/// Shared preferences key that stores species propagation behavior between inventories.
const String kSpeciesPropagationPolicyPreferenceKey = 'speciesPropagationPolicy';

/// Shared preferences key that stores whether the inventory export onboarding was acknowledged.
const String kInventoryExportOnboardingSeenPreferenceKey = 'inventoryExportOnboardingSeen';

/// Version threshold where inventory export onboarding was introduced.
const int kInventoryExportOnboardingVersion = 152;

/// Extra window (as a factor of inventory wall-clock duration) accepted after
/// inventory end for species accumulation chart calculations.
///
/// Example: `1.0` means records up to one additional inventory duration after
/// end time are still considered.
const double kSpeciesChartPostFinishWindowFactor = 1.0;

const String kRecentInventoryTypePreferenceKey = 'recentInventoryType';
const String kRecentInventoryLocalitiesPreferenceKey = 'recentInventoryLocalities';
const String kRecentNestLocalitiesPreferenceKey = 'recentNestLocalities';
const String kRecentSpecimenLocalitiesPreferenceKey = 'recentSpecimenLocalities';

/// App modules that can be used as startup destination.
enum StartupModule { inventories, nests, specimens, fieldJournal, statistics }

/// Defines what to do when imported records already exist locally.
enum ImportExistingRecordPolicy { askEveryTime, updateExisting, skipExisting }

/// Defines how species are propagated to other active inventories.
enum SpeciesPropagationPolicy { alwaysPropagate, askEveryTime, neverPropagate }

/// Default policy used when no species propagation preference has been saved yet.
const SpeciesPropagationPolicy kDefaultSpeciesPropagationPolicy = SpeciesPropagationPolicy.askEveryTime;

/// Exception thrown when inserting records into the database fails.
class DatabaseInsertException implements Exception {
  final String message;

  DatabaseInsertException(this.message);

  @override
  String toString() => 'DatabaseInsertException: $message';
}

/// Countries currently supported by species checklists and settings.
enum SupportedCountry {
  AR, // Argentina
  BR, // Brazil
  PY, // Paraguay
  UY, // Uruguay
}

/// Localized metadata for each supported country.
final Map<SupportedCountry, CountryMetadata> countryMetadata = {
  SupportedCountry.AR: CountryMetadata(name: S.current.countryArgentina, isoCode: 'AR'),
  SupportedCountry.BR: CountryMetadata(name: S.current.countryBrazil, isoCode: 'BR'),
  SupportedCountry.PY: CountryMetadata(name: S.current.countryParaguay, isoCode: 'PY'),
  SupportedCountry.UY: CountryMetadata(name: S.current.countryUruguay, isoCode: 'UY'),
};

/// Human-readable metadata associated with a supported country.
class CountryMetadata {
  final String name;
  final String isoCode;

  CountryMetadata({required this.name, required this.isoCode});
}

/// Provider groups that can show badge counters in navigation.
enum BadgeProviderType { inventory, nest }

/// Predefined date range filters for list and statistics screens.
enum DateFilter { today, yesterday, last7Days, last30Days, last90Days, last180Days, last365Days, customRange }

/// Sort direction for ordered data views.
enum SortOrder { ascending, descending }

/// Available sort fields for inventories.
enum InventorySortField { id, startTime, endTime, locality, inventoryType }

/// Available sort fields for nests.
enum NestSortField { fieldNumber, foundTime, lastTime, species, locality, nestFate }

/// Available sort fields for specimens.
enum SpecimenSortField { fieldNumber, sampleTime, species, locality, specimenType }

/// Available sort fields for field journal entries.
enum JournalSortField { title, creationDate, lastModifiedDate }

/// Available sort fields for species records inside inventories.
enum SpeciesSortField {
  name,
  time,
  // type,
}

/// Broad habitat categories that can be assigned to a species record.
enum SpeciesHabitat {
  forest,
  woodland,
  grassland,
  savanna,
  shrubland,
  wetland,
  freshwater,
  marine,
  coastal,
  urban,
  agricultural,
  rocky,
  mangrove,
  other,
}

/// Localized labels for [SpeciesHabitat] values.
final Map<SpeciesHabitat, String> speciesHabitatFriendlyNames = {
  SpeciesHabitat.forest: S.current.speciesHabitatForest,
  SpeciesHabitat.woodland: S.current.speciesHabitatWoodland,
  SpeciesHabitat.grassland: S.current.speciesHabitatGrassland,
  SpeciesHabitat.savanna: S.current.speciesHabitatSavanna,
  SpeciesHabitat.shrubland: S.current.speciesHabitatShrubland,
  SpeciesHabitat.wetland: S.current.speciesHabitatWetland,
  SpeciesHabitat.freshwater: S.current.speciesHabitatFreshwater,
  SpeciesHabitat.marine: S.current.speciesHabitatMarine,
  SpeciesHabitat.coastal: S.current.speciesHabitatCoastal,
  SpeciesHabitat.urban: S.current.speciesHabitatUrban,
  SpeciesHabitat.agricultural: S.current.speciesHabitatAgricultural,
  SpeciesHabitat.rocky: S.current.speciesHabitatRocky,
  SpeciesHabitat.mangrove: S.current.speciesHabitatMangrove,
  SpeciesHabitat.other: S.current.speciesHabitatOther,
};

/// Detection modes used when a species is recorded.
enum SpeciesDetectionMode { visual, song, call, wingFlapping, drumming, capture, remote, trackOrSign, other }

/// Localized labels for [SpeciesDetectionMode] values.
final Map<SpeciesDetectionMode, String> speciesDetectionModeFriendlyNames = {
  SpeciesDetectionMode.visual: S.current.speciesDetectionVisual,
  SpeciesDetectionMode.song: S.current.speciesDetectionSong,
  SpeciesDetectionMode.call: S.current.speciesDetectionCall,
  SpeciesDetectionMode.wingFlapping: S.current.speciesDetectionWingFlapping,
  SpeciesDetectionMode.drumming: S.current.speciesDetectionDrumming,
  SpeciesDetectionMode.capture: S.current.speciesDetectionCapture,
  SpeciesDetectionMode.remote: S.current.speciesDetectionRemote,
  SpeciesDetectionMode.trackOrSign: S.current.speciesDetectionTrackOrSign,
  SpeciesDetectionMode.other: S.current.speciesDetectionOther,
};

/// Reproductive/breeding evidence values based on eBird breeding and behavior codes.
enum SpeciesReproductiveStatus {
  h('H'),
  s('S'),
  s7('S7'),
  m('M'),
  p('P'),
  t('T'),
  c('C'),
  n('N'),
  a('A'),
  b('B'),
  pe('PE'),
  cn('CN'),
  nb('NB'),
  dd('DD'),
  un('UN'),
  on('ON'),
  fl('FL'),
  cf('CF'),
  fy('FY'),
  fs('FS'),
  ne('NE'),
  ny('NY'),
  f('F');

  const SpeciesReproductiveStatus(this.code);

  final String code;
}

/// Display labels for [SpeciesReproductiveStatus] values.
final Map<SpeciesReproductiveStatus, String> speciesReproductiveStatusFriendlyNames = {
  SpeciesReproductiveStatus.h: S.current.speciesReproductiveCodeH,
  SpeciesReproductiveStatus.s: S.current.speciesReproductiveCodeS,
  SpeciesReproductiveStatus.s7: S.current.speciesReproductiveCodeS7,
  SpeciesReproductiveStatus.m: S.current.speciesReproductiveCodeM,
  SpeciesReproductiveStatus.p: S.current.speciesReproductiveCodeP,
  SpeciesReproductiveStatus.t: S.current.speciesReproductiveCodeT,
  SpeciesReproductiveStatus.c: S.current.speciesReproductiveCodeC,
  SpeciesReproductiveStatus.n: S.current.speciesReproductiveCodeN,
  SpeciesReproductiveStatus.a: S.current.speciesReproductiveCodeA,
  SpeciesReproductiveStatus.b: S.current.speciesReproductiveCodeB,
  SpeciesReproductiveStatus.pe: S.current.speciesReproductiveCodePE,
  SpeciesReproductiveStatus.cn: S.current.speciesReproductiveCodeCN,
  SpeciesReproductiveStatus.nb: S.current.speciesReproductiveCodeNB,
  SpeciesReproductiveStatus.dd: S.current.speciesReproductiveCodeDD,
  SpeciesReproductiveStatus.un: S.current.speciesReproductiveCodeUN,
  SpeciesReproductiveStatus.on: S.current.speciesReproductiveCodeON,
  SpeciesReproductiveStatus.fl: S.current.speciesReproductiveCodeFL,
  SpeciesReproductiveStatus.cf: S.current.speciesReproductiveCodeCF,
  SpeciesReproductiveStatus.fy: S.current.speciesReproductiveCodeFY,
  SpeciesReproductiveStatus.fs: S.current.speciesReproductiveCodeFS,
  SpeciesReproductiveStatus.ne: S.current.speciesReproductiveCodeNE,
  SpeciesReproductiveStatus.ny: S.current.speciesReproductiveCodeNY,
  SpeciesReproductiveStatus.f: S.current.speciesReproductiveCodeF,
};

/// Preferred UI order by evidence strength from observed to confirmed.
const List<SpeciesReproductiveStatus> kSpeciesReproductiveStatusDisplayOrder = [
  SpeciesReproductiveStatus.f,
  SpeciesReproductiveStatus.h,
  SpeciesReproductiveStatus.s,
  SpeciesReproductiveStatus.s7,
  SpeciesReproductiveStatus.m,
  SpeciesReproductiveStatus.p,
  SpeciesReproductiveStatus.t,
  SpeciesReproductiveStatus.c,
  SpeciesReproductiveStatus.n,
  SpeciesReproductiveStatus.a,
  SpeciesReproductiveStatus.b,
  SpeciesReproductiveStatus.pe,
  SpeciesReproductiveStatus.cn,
  SpeciesReproductiveStatus.nb,
  SpeciesReproductiveStatus.dd,
  SpeciesReproductiveStatus.un,
  SpeciesReproductiveStatus.on,
  SpeciesReproductiveStatus.fl,
  SpeciesReproductiveStatus.cf,
  SpeciesReproductiveStatus.fy,
  SpeciesReproductiveStatus.fs,
  SpeciesReproductiveStatus.ne,
  SpeciesReproductiveStatus.ny,
];

const Map<String, SpeciesReproductiveStatus> _legacySpeciesReproductiveStatusAlias = {
  'possiblebreeding': SpeciesReproductiveStatus.h,
  'probablebreeding': SpeciesReproductiveStatus.p,
  'confirmedbreeding': SpeciesReproductiveStatus.ne,
};

/// Parses persisted reproductive status values from either current code or legacy enum name.
SpeciesReproductiveStatus? parseSpeciesReproductiveStatus(dynamic raw) {
  if (raw == null) return null;

  if (raw is int && raw >= 0 && raw < SpeciesReproductiveStatus.values.length) {
    return SpeciesReproductiveStatus.values[raw];
  }

  final token = raw.toString().trim();
  if (token.isEmpty) return null;

  for (final value in SpeciesReproductiveStatus.values) {
    if (value.code.toLowerCase() == token.toLowerCase()) {
      return value;
    }
  }

  for (final value in SpeciesReproductiveStatus.values) {
    if (value.name.toLowerCase() == token.toLowerCase()) {
      return value;
    }
  }

  final index = int.tryParse(token);
  if (index != null && index >= 0 && index < SpeciesReproductiveStatus.values.length) {
    return SpeciesReproductiveStatus.values[index];
  }

  return _legacySpeciesReproductiveStatusAlias[token.toLowerCase()];
}

/// Sex values that can be assigned to a species record.
enum SpeciesSex { indeterminate, male, female, both }

/// Localized labels for [SpeciesSex] values.
final Map<SpeciesSex, String> speciesSexFriendlyNames = {
  SpeciesSex.indeterminate: S.current.speciesSexIndeterminate,
  SpeciesSex.male: S.current.speciesSexMale,
  SpeciesSex.female: S.current.speciesSexFemale,
  SpeciesSex.both: S.current.speciesSexBoth,
};

/// Main observed activities/behaviors that can be selected for a species.
enum SpeciesActivity {
  flying,
  foraging,
  perching,
  singing,
  calling,
  nesting,
  feedingYoung,
  resting,
  bathing,
  moving,
  displaying,
  aggressive,
  roosting,
  other,
}

/// Localized labels for [SpeciesActivity] values.
final Map<SpeciesActivity, String> speciesActivityFriendlyNames = {
  SpeciesActivity.flying: S.current.speciesActivityFlying,
  SpeciesActivity.foraging: S.current.speciesActivityForaging,
  SpeciesActivity.perching: S.current.speciesActivityPerching,
  SpeciesActivity.singing: S.current.speciesActivitySinging,
  SpeciesActivity.calling: S.current.speciesActivityCalling,
  SpeciesActivity.nesting: S.current.speciesActivityNesting,
  SpeciesActivity.feedingYoung: S.current.speciesActivityFeedingYoung,
  SpeciesActivity.resting: S.current.speciesActivityResting,
  SpeciesActivity.bathing: S.current.speciesActivityBathing,
  SpeciesActivity.moving: S.current.speciesActivityMoving,
  SpeciesActivity.displaying: S.current.speciesActivityDisplaying,
  SpeciesActivity.aggressive: S.current.speciesActivityAggressive,
  SpeciesActivity.roosting: S.current.speciesActivityRoosting,
  SpeciesActivity.other: S.current.speciesActivityOther,
};

/// Actions returned by conditional warning dialogs.
enum ConditionalAction { add, ignore, cancelDialog }

/// Vegetation distribution descriptors used in vegetation samples.
enum DistributionType {
  disNone,
  disRare,
  disFewSparseIndividuals,
  disOnePatch,
  disOnePatchFewSparseIndividuals,
  disManySparseIndividuals,
  disOnePatchManySparseIndividuals,
  disFewPatches,
  disFewPatchesSparseIndividuals,
  disManyPatches,
  disManyPatchesSparseIndividuals,
  disHighDensityIndividuals,
  disContinuousCoverWithGaps,
  disContinuousDenseCover,
  disContinuousDenseCoverWithEdge,
}

/// Localized labels for [DistributionType] values.
Map<DistributionType, String> distributionTypeFriendlyNames = {
  DistributionType.disNone: S.current.distributionNone,
  DistributionType.disRare: S.current.distributionRare,
  DistributionType.disFewSparseIndividuals: S.current.distributionFewSparseIndividuals,
  DistributionType.disOnePatch: S.current.distributionOnePatch,
  DistributionType.disOnePatchFewSparseIndividuals: S.current.distributionOnePatchFewSparseIndividuals,
  DistributionType.disManySparseIndividuals: S.current.distributionManySparseIndividuals,
  DistributionType.disOnePatchManySparseIndividuals: S.current.distributionOnePatchManySparseIndividuals,
  DistributionType.disFewPatches: S.current.distributionFewPatches,
  DistributionType.disFewPatchesSparseIndividuals: S.current.distributionFewPatchesSparseIndividuals,
  DistributionType.disManyPatches: S.current.distributionManyPatches,
  DistributionType.disManyPatchesSparseIndividuals: S.current.distributionManyPatchesSparseIndividuals,
  DistributionType.disHighDensityIndividuals: S.current.distributionHighDensityIndividuals,
  DistributionType.disContinuousCoverWithGaps: S.current.distributionContinuousCoverWithGaps,
  DistributionType.disContinuousDenseCover: S.current.distributionContinuousDenseCover,
  DistributionType.disContinuousDenseCoverWithEdge: S.current.distributionContinuousDenseCoverWithEdge,
};

/// Precipitation categories used in weather samples.
enum PrecipitationType { preNone, preFog, preMist, preDrizzle, preRain, preShowers, preSnow, preHail, preFrost }

/// Localized labels for [PrecipitationType] values.
Map<PrecipitationType, String> precipitationTypeFriendlyNames = {
  PrecipitationType.preNone: S.current.precipitationNone,
  PrecipitationType.preFog: S.current.precipitationFog,
  PrecipitationType.preMist: S.current.precipitationMist,
  PrecipitationType.preDrizzle: S.current.precipitationDrizzle,
  PrecipitationType.preRain: S.current.precipitationRain,
  PrecipitationType.preShowers: S.current.precipitationShowers,
  PrecipitationType.preSnow: S.current.precipitationSnow,
  PrecipitationType.preHail: S.current.precipitationHail,
  PrecipitationType.preFrost: S.current.precipitationFrost,
};

/// Inventory protocol types available when creating an inventory.
enum InventoryType {
  invFreeQualitative,
  invTimedQualitative,
  invIntervalQualitative,
  invMackinnonList,
  invTransectCount,
  invPointCount,
  invBanding,
  invCasual,
  invTransectDetection,
  invPointDetection,
}

/// Localized labels for [InventoryType] values.
Map<InventoryType, String> inventoryTypeFriendlyNames = {
  InventoryType.invFreeQualitative: S.current.inventoryFreeQualitative,
  InventoryType.invTimedQualitative: S.current.inventoryTimedQualitative,
  InventoryType.invIntervalQualitative: S.current.inventoryIntervalQualitative,
  InventoryType.invMackinnonList: S.current.inventoryMackinnonList,
  InventoryType.invTransectCount: S.current.inventoryTransectCount,
  InventoryType.invPointCount: S.current.inventoryPointCount,
  InventoryType.invBanding: S.current.inventoryBanding,
  InventoryType.invCasual: S.current.inventoryCasual,
  InventoryType.invTransectDetection: S.current.inventoryTransectDetection,
  InventoryType.invPointDetection: S.current.inventoryPointDetection,
};

/// Transport modes used during field inventories.
enum TransportMode {
  tmodeNotApplicable,
  tmodeWalking,
  tmodeVehicle,
  tmodeBoat,
  tmodeAircraft,
  tmodeBicycle,
  tmodeHorse,
  tmodeRemote,
  tmodeOther,
}

/// Localized labels for [TransportMode] values.
Map<TransportMode, String> transportModeFriendlyNames = {
  TransportMode.tmodeNotApplicable: S.current.transportNotApplicable,
  TransportMode.tmodeWalking: S.current.transportWalking,
  TransportMode.tmodeVehicle: S.current.transportVehicle,
  TransportMode.tmodeBoat: S.current.transportBoat,
  TransportMode.tmodeAircraft: S.current.transportAircraft,
  TransportMode.tmodeBicycle: S.current.transportBicycle,
  TransportMode.tmodeHorse: S.current.transportHorse,
  TransportMode.tmodeRemote: S.current.transportRemote,
  TransportMode.tmodeOther: S.current.transportOther,
};

/// Icon mapping for [TransportMode] values (null if no icon should be shown).
Map<TransportMode, FaIconData?> transportModeIcons = {
  TransportMode.tmodeNotApplicable: null,
  TransportMode.tmodeWalking: FontAwesomeIcons.personWalking,
  TransportMode.tmodeVehicle: FontAwesomeIcons.car,
  TransportMode.tmodeBoat: FontAwesomeIcons.ship,
  TransportMode.tmodeAircraft: FontAwesomeIcons.plane,
  TransportMode.tmodeBicycle: FontAwesomeIcons.bicycle,
  TransportMode.tmodeHorse: FontAwesomeIcons.horse,
  TransportMode.tmodeRemote: FontAwesomeIcons.satelliteDish,
  TransportMode.tmodeOther: null,
};

/// Egg shape categories used by nest egg records.
enum EggShapeType {
  estSpherical,
  estElliptical,
  estOval,
  estPyriform,
  estConical,
  estBiconical,
  estCylindrical,
  estLongitudinal,
}

/// Localized labels for [EggShapeType] values.
Map<EggShapeType, String> eggShapeTypeFriendlyNames = {
  EggShapeType.estSpherical: S.current.eggShapeSpherical,
  EggShapeType.estElliptical: S.current.eggShapeElliptical,
  EggShapeType.estOval: S.current.eggShapeOval,
  EggShapeType.estPyriform: S.current.eggShapePyriform,
  EggShapeType.estConical: S.current.eggShapeConical,
  EggShapeType.estBiconical: S.current.eggShapeBiconical,
  EggShapeType.estCylindrical: S.current.eggShapeCylindrical,
  EggShapeType.estLongitudinal: S.current.eggShapeLongitudinal,
};

/// Stages of nest development recorded in revisions.
enum NestStageType { stgUnknown, stgBuilding, stgLaying, stgIncubating, stgHatching, stgNestling, stgInactive }

/// Localized labels for [NestStageType] values.
Map<NestStageType, String> nestStageTypeFriendlyNames = {
  NestStageType.stgUnknown: S.current.nestStageUnknown,
  NestStageType.stgBuilding: S.current.nestStageBuilding,
  NestStageType.stgLaying: S.current.nestStageLaying,
  NestStageType.stgIncubating: S.current.nestStageIncubating,
  NestStageType.stgHatching: S.current.nestStageHatching,
  NestStageType.stgNestling: S.current.nestStageNestling,
  NestStageType.stgInactive: S.current.nestStageInactive,
};

/// Activity status of a nest during a revision.
enum NestStatusType { nstUnknown, nstActive, nstInactive }

/// Localized labels for [NestStatusType] values.
Map<NestStatusType, String> nestStatusTypeFriendlyNames = {
  NestStatusType.nstUnknown: S.current.nestStatusUnknown,
  NestStatusType.nstActive: S.current.nestStatusActive,
  NestStatusType.nstInactive: S.current.nestStatusInactive,
};

/// Final fate categories used to close nest records.
enum NestFateType { fatUnknown, fatSuccess, fatLost }

/// Localized labels for [NestFateType] values.
Map<NestFateType, String> nestFateTypeFriendlyNames = {
  NestFateType.fatUnknown: S.current.nestFateUnknown,
  NestFateType.fatSuccess: S.current.nestFateSuccess,
  NestFateType.fatLost: S.current.nestFateLost,
};

/// Biological specimen categories used when recording samples.
enum SpecimenType {
  spcWholeCarcass,
  spcPartialCarcass,
  spcNest,
  spcBones,
  spcEgg,
  spcParasites,
  spcFeathers,
  spcBlood,
  spcClaw,
  spcSwab,
  spcTissues,
  spcFeces,
  spcRegurgite,
}

/// Localized labels for [SpecimenType] values.
Map<SpecimenType, String> specimenTypeFriendlyNames = {
  SpecimenType.spcWholeCarcass: S.current.specimenWholeCarcass,
  SpecimenType.spcPartialCarcass: S.current.specimenPartialCarcass,
  SpecimenType.spcNest: S.current.specimenNest,
  SpecimenType.spcBones: S.current.specimenBones,
  SpecimenType.spcEgg: S.current.specimenEgg,
  SpecimenType.spcParasites: S.current.specimenParasites,
  SpecimenType.spcFeathers: S.current.specimenFeathers,
  SpecimenType.spcBlood: S.current.specimenBlood,
  SpecimenType.spcClaw: S.current.specimenClaw,
  SpecimenType.spcSwab: S.current.specimenSwab,
  SpecimenType.spcTissues: S.current.specimenTissues,
  SpecimenType.spcFeces: S.current.specimenFeces,
  SpecimenType.spcRegurgite: S.current.specimenRegurgite,
};

/// Palette of predefined colors for journal tags with good contrast in light/dark themes.
const List<Color> kJournalTagColors = [
  Color(0xFF48429B), // Jacaranda
  Color(0xFF1B5E20), // Emerald
  Color(0xFFE65100), // Calango Orange
  Color(0xFF0D47A1), // Navy Blue
  Color(0xFFB71C1C), // Carmine
  Color(0xFF004D40), // Teal
  Color(0xFF4A148C), // Purple
  Color(0xFF33691E), // Olive
  Color(0xFFF57F17), // Amber
  Color(0xFF880E4F), // Magenta
  Color(0xFF006064), // Sky Cyan
  Color(0xFF795548), // Light Brown
  Color(0xFF827717), // Lime Green
  Color(0xFF1A237E), // Indigo
  Color(0xFF3E2723), // Clay Brown
  Color(0xFF263238), // Graphite
];

/// Returns a random color from the predefined tag colors palette.
Color getRandomTagColor() {
  return kJournalTagColors[DateTime.now().millisecond % kJournalTagColors.length];
}

/// Returns a tag color by index.
Color getTagColorByIndex(int colorIndex) {
  return kJournalTagColors[colorIndex % kJournalTagColors.length];
}
