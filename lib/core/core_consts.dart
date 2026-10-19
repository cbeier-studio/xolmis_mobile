import 'package:material_ui/material_ui.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../generated/l10n.dart';

S get _activeL10n {
  final dispatcher = WidgetsBinding.instance.platformDispatcher;
  for (final locale in dispatcher.locales) {
    if (S.delegate.isSupported(locale)) {
      return lookupS(locale);
    }
    final fallbackLocale = Locale(locale.languageCode);
    if (S.delegate.isSupported(fallbackLocale)) {
      return lookupS(fallbackLocale);
    }
  }
  return lookupS(const Locale('en'));
}

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
const String kRecentInventoryProjectsPreferenceKey = 'recentInventoryProjects';
const String kRecentInventoryExpeditionsPreferenceKey = 'recentInventoryExpeditions';
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
Map<SupportedCountry, CountryMetadata> get countryMetadata {
  final l10n = _activeL10n;
  return {
    SupportedCountry.AR: CountryMetadata(name: l10n.countryArgentina, isoCode: 'AR'),
    SupportedCountry.BR: CountryMetadata(name: l10n.countryBrazil, isoCode: 'BR'),
    SupportedCountry.PY: CountryMetadata(name: l10n.countryParaguay, isoCode: 'PY'),
    SupportedCountry.UY: CountryMetadata(name: l10n.countryUruguay, isoCode: 'UY'),
  };
}

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
Map<SpeciesHabitat, String> get speciesHabitatFriendlyNames {
  final l10n = _activeL10n;
  return {
    SpeciesHabitat.forest: l10n.speciesHabitatForest,
    SpeciesHabitat.woodland: l10n.speciesHabitatWoodland,
    SpeciesHabitat.grassland: l10n.speciesHabitatGrassland,
    SpeciesHabitat.savanna: l10n.speciesHabitatSavanna,
    SpeciesHabitat.shrubland: l10n.speciesHabitatShrubland,
    SpeciesHabitat.wetland: l10n.speciesHabitatWetland,
    SpeciesHabitat.freshwater: l10n.speciesHabitatFreshwater,
    SpeciesHabitat.marine: l10n.speciesHabitatMarine,
    SpeciesHabitat.coastal: l10n.speciesHabitatCoastal,
    SpeciesHabitat.urban: l10n.speciesHabitatUrban,
    SpeciesHabitat.agricultural: l10n.speciesHabitatAgricultural,
    SpeciesHabitat.rocky: l10n.speciesHabitatRocky,
    SpeciesHabitat.mangrove: l10n.speciesHabitatMangrove,
    SpeciesHabitat.other: l10n.speciesHabitatOther,
  };
}

/// Detection modes used when a species is recorded.
enum SpeciesDetectionMode { visual, song, call, wingFlapping, drumming, capture, remote, trackOrSign, other }

/// Localized labels for [SpeciesDetectionMode] values.
Map<SpeciesDetectionMode, String> get speciesDetectionModeFriendlyNames {
  final l10n = _activeL10n;
  return {
    SpeciesDetectionMode.visual: l10n.speciesDetectionVisual,
    SpeciesDetectionMode.song: l10n.speciesDetectionSong,
    SpeciesDetectionMode.call: l10n.speciesDetectionCall,
    SpeciesDetectionMode.wingFlapping: l10n.speciesDetectionWingFlapping,
    SpeciesDetectionMode.drumming: l10n.speciesDetectionDrumming,
    SpeciesDetectionMode.capture: l10n.speciesDetectionCapture,
    SpeciesDetectionMode.remote: l10n.speciesDetectionRemote,
    SpeciesDetectionMode.trackOrSign: l10n.speciesDetectionTrackOrSign,
    SpeciesDetectionMode.other: l10n.speciesDetectionOther,
  };
}

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
Map<SpeciesReproductiveStatus, String> get speciesReproductiveStatusFriendlyNames {
  final l10n = _activeL10n;
  return {
    SpeciesReproductiveStatus.h: l10n.speciesReproductiveCodeH,
    SpeciesReproductiveStatus.s: l10n.speciesReproductiveCodeS,
    SpeciesReproductiveStatus.s7: l10n.speciesReproductiveCodeS7,
    SpeciesReproductiveStatus.m: l10n.speciesReproductiveCodeM,
    SpeciesReproductiveStatus.p: l10n.speciesReproductiveCodeP,
    SpeciesReproductiveStatus.t: l10n.speciesReproductiveCodeT,
    SpeciesReproductiveStatus.c: l10n.speciesReproductiveCodeC,
    SpeciesReproductiveStatus.n: l10n.speciesReproductiveCodeN,
    SpeciesReproductiveStatus.a: l10n.speciesReproductiveCodeA,
    SpeciesReproductiveStatus.b: l10n.speciesReproductiveCodeB,
    SpeciesReproductiveStatus.pe: l10n.speciesReproductiveCodePE,
    SpeciesReproductiveStatus.cn: l10n.speciesReproductiveCodeCN,
    SpeciesReproductiveStatus.nb: l10n.speciesReproductiveCodeNB,
    SpeciesReproductiveStatus.dd: l10n.speciesReproductiveCodeDD,
    SpeciesReproductiveStatus.un: l10n.speciesReproductiveCodeUN,
    SpeciesReproductiveStatus.on: l10n.speciesReproductiveCodeON,
    SpeciesReproductiveStatus.fl: l10n.speciesReproductiveCodeFL,
    SpeciesReproductiveStatus.cf: l10n.speciesReproductiveCodeCF,
    SpeciesReproductiveStatus.fy: l10n.speciesReproductiveCodeFY,
    SpeciesReproductiveStatus.fs: l10n.speciesReproductiveCodeFS,
    SpeciesReproductiveStatus.ne: l10n.speciesReproductiveCodeNE,
    SpeciesReproductiveStatus.ny: l10n.speciesReproductiveCodeNY,
    SpeciesReproductiveStatus.f: l10n.speciesReproductiveCodeF,
  };
}

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
Map<SpeciesSex, String> get speciesSexFriendlyNames {
  final l10n = _activeL10n;
  return {
    SpeciesSex.indeterminate: l10n.speciesSexIndeterminate,
    SpeciesSex.male: l10n.speciesSexMale,
    SpeciesSex.female: l10n.speciesSexFemale,
    SpeciesSex.both: l10n.speciesSexBoth,
  };
}

/// Main observed activities/behaviors that can be selected for a species.
enum SpeciesActivity {
  resting,
  vocalizing,
  overflying,
  circling,
  wandering,
  moving,
  swimming,
  foraging,
  displaying,
  mating,
  nesting,
  attendingYoung,
  distraction,
  selfMaintenance,
  territorialDispute,
  intraSpecificAggression,
  interSpecificAggression,
  other,
}

/// Localized labels for [SpeciesActivity] values.
Map<SpeciesActivity, String> get speciesActivityFriendlyNames {
  return {
    SpeciesActivity.resting: 'Repousando',
    SpeciesActivity.vocalizing: 'Vocalizando',
    SpeciesActivity.overflying: 'Sobrevoando',
    SpeciesActivity.circling: 'Circulando',
    SpeciesActivity.wandering: 'Vagando',
    SpeciesActivity.moving: 'Deslocando',
    SpeciesActivity.swimming: 'Nadando',
    SpeciesActivity.foraging: 'Forrageando',
    SpeciesActivity.displaying: 'Exibição',
    SpeciesActivity.mating: 'Acasalando',
    SpeciesActivity.nesting: 'Nidificando',
    SpeciesActivity.attendingYoung: 'Atendendo filhotes',
    SpeciesActivity.distraction: 'Distração',
    SpeciesActivity.selfMaintenance: 'Manutenção individual',
    SpeciesActivity.territorialDispute: 'Disputa territorial',
    SpeciesActivity.intraSpecificAggression: 'Agressão intraespecífica',
    SpeciesActivity.interSpecificAggression: 'Agressão interespecífica',
    SpeciesActivity.other: 'Outro',
  };
}

const Map<String, SpeciesActivity> _legacySpeciesActivityAlias = {
  'flying': SpeciesActivity.overflying,
  'foraging': SpeciesActivity.foraging,
  'perching': SpeciesActivity.resting,
  'singing': SpeciesActivity.vocalizing,
  'calling': SpeciesActivity.vocalizing,
  'nesting': SpeciesActivity.nesting,
  'feedingyoung': SpeciesActivity.attendingYoung,
  'resting': SpeciesActivity.resting,
  'bathing': SpeciesActivity.selfMaintenance,
  'moving': SpeciesActivity.moving,
  'displaying': SpeciesActivity.displaying,
  'aggressive': SpeciesActivity.intraSpecificAggression,
  'roosting': SpeciesActivity.resting,
  'other': SpeciesActivity.other,
};

const Map<int, SpeciesActivity> _legacySpeciesActivityIndexAlias = {
  0: SpeciesActivity.overflying,
  1: SpeciesActivity.foraging,
  2: SpeciesActivity.resting,
  3: SpeciesActivity.vocalizing,
  4: SpeciesActivity.vocalizing,
  5: SpeciesActivity.nesting,
  6: SpeciesActivity.attendingYoung,
  7: SpeciesActivity.resting,
  8: SpeciesActivity.selfMaintenance,
  9: SpeciesActivity.moving,
  10: SpeciesActivity.displaying,
  11: SpeciesActivity.intraSpecificAggression,
  12: SpeciesActivity.resting,
  13: SpeciesActivity.other,
};

/// Parses persisted species activity values from either current enum names,
/// legacy enum names, or legacy indexes.
SpeciesActivity? parseSpeciesActivity(dynamic raw) {
  if (raw == null) return null;

  if (raw is int) {
    final legacy = _legacySpeciesActivityIndexAlias[raw];
    if (legacy != null) {
      return legacy;
    }
    if (raw >= 0 && raw < SpeciesActivity.values.length) {
      return SpeciesActivity.values[raw];
    }
    return null;
  }

  final token = raw.toString().trim();
  if (token.isEmpty) return null;

  for (final value in SpeciesActivity.values) {
    if (value.name.toLowerCase() == token.toLowerCase()) {
      return value;
    }
  }

  final parsedIndex = int.tryParse(token);
  if (parsedIndex != null) {
    final legacy = _legacySpeciesActivityIndexAlias[parsedIndex];
    if (legacy != null) {
      return legacy;
    }
    if (parsedIndex >= 0 && parsedIndex < SpeciesActivity.values.length) {
      return SpeciesActivity.values[parsedIndex];
    }
  }

  return _legacySpeciesActivityAlias[token.toLowerCase()];
}

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
Map<DistributionType, String> get distributionTypeFriendlyNames {
  final l10n = _activeL10n;
  return {
    DistributionType.disNone: l10n.distributionNone,
    DistributionType.disRare: l10n.distributionRare,
    DistributionType.disFewSparseIndividuals: l10n.distributionFewSparseIndividuals,
    DistributionType.disOnePatch: l10n.distributionOnePatch,
    DistributionType.disOnePatchFewSparseIndividuals: l10n.distributionOnePatchFewSparseIndividuals,
    DistributionType.disManySparseIndividuals: l10n.distributionManySparseIndividuals,
    DistributionType.disOnePatchManySparseIndividuals: l10n.distributionOnePatchManySparseIndividuals,
    DistributionType.disFewPatches: l10n.distributionFewPatches,
    DistributionType.disFewPatchesSparseIndividuals: l10n.distributionFewPatchesSparseIndividuals,
    DistributionType.disManyPatches: l10n.distributionManyPatches,
    DistributionType.disManyPatchesSparseIndividuals: l10n.distributionManyPatchesSparseIndividuals,
    DistributionType.disHighDensityIndividuals: l10n.distributionHighDensityIndividuals,
    DistributionType.disContinuousCoverWithGaps: l10n.distributionContinuousCoverWithGaps,
    DistributionType.disContinuousDenseCover: l10n.distributionContinuousDenseCover,
    DistributionType.disContinuousDenseCoverWithEdge: l10n.distributionContinuousDenseCoverWithEdge,
  };
}

/// Precipitation categories used in weather samples.
enum PrecipitationType { preNone, preFog, preMist, preDrizzle, preRain, preShowers, preSnow, preHail, preFrost }

/// Localized labels for [PrecipitationType] values.
Map<PrecipitationType, String> get precipitationTypeFriendlyNames {
  final l10n = _activeL10n;
  return {
    PrecipitationType.preNone: l10n.precipitationNone,
    PrecipitationType.preFog: l10n.precipitationFog,
    PrecipitationType.preMist: l10n.precipitationMist,
    PrecipitationType.preDrizzle: l10n.precipitationDrizzle,
    PrecipitationType.preRain: l10n.precipitationRain,
    PrecipitationType.preShowers: l10n.precipitationShowers,
    PrecipitationType.preSnow: l10n.precipitationSnow,
    PrecipitationType.preHail: l10n.precipitationHail,
    PrecipitationType.preFrost: l10n.precipitationFrost,
  };
}

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
Map<InventoryType, String> get inventoryTypeFriendlyNames {
  final l10n = _activeL10n;
  return {
    InventoryType.invFreeQualitative: l10n.inventoryFreeQualitative,
    InventoryType.invTimedQualitative: l10n.inventoryTimedQualitative,
    InventoryType.invIntervalQualitative: l10n.inventoryIntervalQualitative,
    InventoryType.invMackinnonList: l10n.inventoryMackinnonList,
    InventoryType.invTransectCount: l10n.inventoryTransectCount,
    InventoryType.invPointCount: l10n.inventoryPointCount,
    InventoryType.invBanding: l10n.inventoryBanding,
    InventoryType.invCasual: l10n.inventoryCasual,
    InventoryType.invTransectDetection: l10n.inventoryTransectDetection,
    InventoryType.invPointDetection: l10n.inventoryPointDetection,
  };
}

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
Map<TransportMode, String> get transportModeFriendlyNames {
  final l10n = _activeL10n;
  return {
    TransportMode.tmodeNotApplicable: l10n.transportNotApplicable,
    TransportMode.tmodeWalking: l10n.transportWalking,
    TransportMode.tmodeVehicle: l10n.transportVehicle,
    TransportMode.tmodeBoat: l10n.transportBoat,
    TransportMode.tmodeAircraft: l10n.transportAircraft,
    TransportMode.tmodeBicycle: l10n.transportBicycle,
    TransportMode.tmodeHorse: l10n.transportHorse,
    TransportMode.tmodeRemote: l10n.transportRemote,
    TransportMode.tmodeOther: l10n.transportOther,
  };
}

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
Map<EggShapeType, String> get eggShapeTypeFriendlyNames {
  final l10n = _activeL10n;
  return {
    EggShapeType.estSpherical: l10n.eggShapeSpherical,
    EggShapeType.estElliptical: l10n.eggShapeElliptical,
    EggShapeType.estOval: l10n.eggShapeOval,
    EggShapeType.estPyriform: l10n.eggShapePyriform,
    EggShapeType.estConical: l10n.eggShapeConical,
    EggShapeType.estBiconical: l10n.eggShapeBiconical,
    EggShapeType.estCylindrical: l10n.eggShapeCylindrical,
    EggShapeType.estLongitudinal: l10n.eggShapeLongitudinal,
  };
}

/// Stages of nest development recorded in revisions.
enum NestStageType { stgUnknown, stgBuilding, stgLaying, stgIncubating, stgHatching, stgNestling, stgInactive }

/// Localized labels for [NestStageType] values.
Map<NestStageType, String> get nestStageTypeFriendlyNames {
  final l10n = _activeL10n;
  return {
    NestStageType.stgUnknown: l10n.nestStageUnknown,
    NestStageType.stgBuilding: l10n.nestStageBuilding,
    NestStageType.stgLaying: l10n.nestStageLaying,
    NestStageType.stgIncubating: l10n.nestStageIncubating,
    NestStageType.stgHatching: l10n.nestStageHatching,
    NestStageType.stgNestling: l10n.nestStageNestling,
    NestStageType.stgInactive: l10n.nestStageInactive,
  };
}

/// Activity status of a nest during a revision.
enum NestStatusType { nstUnknown, nstActive, nstInactive }

/// Localized labels for [NestStatusType] values.
Map<NestStatusType, String> get nestStatusTypeFriendlyNames {
  final l10n = _activeL10n;
  return {
    NestStatusType.nstUnknown: l10n.nestStatusUnknown,
    NestStatusType.nstActive: l10n.nestStatusActive,
    NestStatusType.nstInactive: l10n.nestStatusInactive,
  };
}

/// Final fate categories used to close nest records.
enum NestFateType { fatUnknown, fatSuccess, fatLost }

/// Localized labels for [NestFateType] values.
Map<NestFateType, String> get nestFateTypeFriendlyNames {
  final l10n = _activeL10n;
  return {
    NestFateType.fatUnknown: l10n.nestFateUnknown,
    NestFateType.fatSuccess: l10n.nestFateSuccess,
    NestFateType.fatLost: l10n.nestFateLost,
  };
}

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
Map<SpecimenType, String> get specimenTypeFriendlyNames {
  final l10n = _activeL10n;
  return {
    SpecimenType.spcWholeCarcass: l10n.specimenWholeCarcass,
    SpecimenType.spcPartialCarcass: l10n.specimenPartialCarcass,
    SpecimenType.spcNest: l10n.specimenNest,
    SpecimenType.spcBones: l10n.specimenBones,
    SpecimenType.spcEgg: l10n.specimenEgg,
    SpecimenType.spcParasites: l10n.specimenParasites,
    SpecimenType.spcFeathers: l10n.specimenFeathers,
    SpecimenType.spcBlood: l10n.specimenBlood,
    SpecimenType.spcClaw: l10n.specimenClaw,
    SpecimenType.spcSwab: l10n.specimenSwab,
    SpecimenType.spcTissues: l10n.specimenTissues,
    SpecimenType.spcFeces: l10n.specimenFeces,
    SpecimenType.spcRegurgite: l10n.specimenRegurgite,
  };
}

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
