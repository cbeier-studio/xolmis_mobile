import '../../generated/l10n.dart';

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

/// App modules that can be used as startup destination.
enum StartupModule {
  inventories,
  nests,
  specimens,
  fieldJournal,
  statistics,
}

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
  SupportedCountry.AR: CountryMetadata(
    name: S.current.countryArgentina,
    isoCode: 'AR',
  ),
  SupportedCountry.BR: CountryMetadata(
    name: S.current.countryBrazil,
    isoCode: 'BR',
  ),
  SupportedCountry.PY: CountryMetadata(
    name: S.current.countryParaguay,
    isoCode: 'PY',
  ),
  SupportedCountry.UY: CountryMetadata(
    name: S.current.countryUruguay,
    isoCode: 'UY',
  ),
};

/// Human-readable metadata associated with a supported country.
class CountryMetadata {
  final String name;
  final String isoCode;

  CountryMetadata({required this.name, required this.isoCode});
}

/// Provider groups that can show badge counters in navigation.
enum BadgeProviderType {
  inventory,
  nest,
}

/// Predefined date range filters for list and statistics screens.
enum DateFilter {
  today,
  yesterday,
  last7Days,
  last30Days,
  last90Days,
  last180Days,
  last365Days,
  customRange,
}

/// Sort direction for ordered data views.
enum SortOrder {
  ascending,
  descending,
}

/// Available sort fields for inventories.
enum InventorySortField {
  id,
  startTime,
  endTime,
  locality,
  inventoryType,
}

/// Available sort fields for nests.
enum NestSortField {
  fieldNumber,
  foundTime,
  lastTime,
  species,
  locality,
  nestFate,
}

/// Available sort fields for specimens.
enum SpecimenSortField {
  fieldNumber,
  sampleTime,
  species,
  locality,
  specimenType,
}

/// Available sort fields for field journal entries.
enum JournalSortField {
  title,
  creationDate,
  lastModifiedDate,
}

/// Available sort fields for species records inside inventories.
enum SpeciesSortField {
  name,
  time,
  // type,
}

/// Actions returned by conditional warning dialogs.
enum ConditionalAction {
  add,
  ignore,
  cancelDialog
}

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
enum PrecipitationType {
  preNone,
  preFog,
  preMist,
  preDrizzle,
  preRain,
  preShowers,
  preSnow,
  preHail,
  preFrost,
}

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
enum NestStageType {
  stgUnknown,
  stgBuilding,
  stgLaying,
  stgIncubating,
  stgHatching,
  stgNestling,
  stgInactive,
}

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
enum NestStatusType {
  nstUnknown,
  nstActive,
  nstInactive,
}

/// Localized labels for [NestStatusType] values.
Map<NestStatusType, String> nestStatusTypeFriendlyNames = {
  NestStatusType.nstUnknown: S.current.nestStatusUnknown,
  NestStatusType.nstActive: S.current.nestStatusActive,
  NestStatusType.nstInactive: S.current.nestStatusInactive,
};

/// Final fate categories used to close nest records.
enum NestFateType {
  fatUnknown,
  fatSuccess,
  fatLost,
}

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

