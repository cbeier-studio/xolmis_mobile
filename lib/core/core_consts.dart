import '../../generated/l10n.dart';

const double kTabletBreakpoint = 600.0;
const double kDesktopBreakpoint = 800.0;
const double kSideSheetWidth = 400.0;

const int kCurrentSpeciesUpdateVersion = 2025;

class DatabaseInsertException implements Exception {
  final String message;

  DatabaseInsertException(this.message);

  @override
  String toString() => 'DatabaseInsertException: $message';
}

enum SupportedCountry {
  BR, // Brazil
  UY, // Uruguay
}

final Map<SupportedCountry, CountryMetadata> countryMetadata = {
  SupportedCountry.BR: CountryMetadata(
    name: S.current.countryBrazil,
    isoCode: 'BR',
  ),
  SupportedCountry.UY: CountryMetadata(
    name: S.current.countryUruguay,
    isoCode: 'UY',
  ),
};

class CountryMetadata {
  final String name;
  final String isoCode;

  CountryMetadata({required this.name, required this.isoCode});
}

enum BadgeProviderType {
  inventory,
  nest,
}

enum SortOrder {
  ascending,
  descending,
}

enum InventorySortField {
  id,
  startTime,
  endTime,
  locality,
  inventoryType,
}

enum NestSortField {
  fieldNumber,
  foundTime,
  lastTime,
  species,
  locality,
  nestFate,
}

enum SpecimenSortField {
  fieldNumber,
  sampleTime,
  species,
  locality,
  specimenType,
}

enum JournalSortField {
  title,
  creationDate,
  lastModifiedDate,
}

enum SpeciesSortField {
  name,
  time,
  // type,
}

// Enum for warning dialog actions
enum ConditionalAction {
  add,
  ignore,
  cancelDialog
}

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

enum NestStageType {
  stgUnknown,
  stgBuilding,
  stgLaying,
  stgIncubating,
  stgHatching,
  stgNestling,
  stgInactive,
}

Map<NestStageType, String> nestStageTypeFriendlyNames = {
  NestStageType.stgUnknown: S.current.nestStageUnknown,
  NestStageType.stgBuilding: S.current.nestStageBuilding,
  NestStageType.stgLaying: S.current.nestStageLaying,
  NestStageType.stgIncubating: S.current.nestStageIncubating,
  NestStageType.stgHatching: S.current.nestStageHatching,
  NestStageType.stgNestling: S.current.nestStageNestling,
  NestStageType.stgInactive: S.current.nestStageInactive,
};

enum NestStatusType {
  nstUnknown,
  nstActive,
  nstInactive,
}

Map<NestStatusType, String> nestStatusTypeFriendlyNames = {
  NestStatusType.nstUnknown: S.current.nestStatusUnknown,
  NestStatusType.nstActive: S.current.nestStatusActive,
  NestStatusType.nstInactive: S.current.nestStatusInactive,
};

enum NestFateType {
  fatUnknown,
  fatSuccess,
  fatLost,
}

Map<NestFateType, String> nestFateTypeFriendlyNames = {
  NestFateType.fatUnknown: S.current.nestFateUnknown,
  NestFateType.fatSuccess: S.current.nestFateSuccess,
  NestFateType.fatLost: S.current.nestFateLost,
};

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

