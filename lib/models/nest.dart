import 'dart:convert';

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

const Map<EggShapeType, String> eggShapeTypeFriendlyNames = {
  EggShapeType.estSpherical: 'Esférico',
  EggShapeType.estElliptical: 'Elíptico',
  EggShapeType.estOval: 'Oval',
  EggShapeType.estPyriform: 'Piriforme',
  EggShapeType.estConical: 'Cônico',
  EggShapeType.estBiconical: 'Bicônico',
  EggShapeType.estCylindrical: 'Cilíndrico',
  EggShapeType.estLongitudinal: 'Longitudinal',
};

class Egg {
  int? id;
  int? nestId;
  DateTime? sampleTime;
  String? fieldNumber;
  EggShapeType eggShape;
  double? width;
  double? length;
  double? mass;
  String? speciesName;

  Egg({
    this.id,
    this.nestId,
    this.sampleTime,
    this.fieldNumber,
    this.eggShape = EggShapeType.estOval,
    this.width,
    this.length,
    this.mass,
    this.speciesName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nestId': nestId,
      'sampleTime': sampleTime?.toIso8601String(),
      'fieldNumber': fieldNumber,
      'eggShape': eggShape.index,
      'width': width,
      'length': length,
      'mass': mass,
      'speciesName': speciesName,
    };
  }

  factory Egg.fromMap(Map<String, dynamic> map) {
    return Egg(
      id: map['id']?.toInt(),
      nestId: map['nestId']?.toInt(),
      sampleTime: map['sampleTime'] != null ? DateTime.parse(map['sampleTime']) : null,
      fieldNumber: map['fieldNumber'],
      eggShape: EggShapeType.values[map['eggShape']],
      width: map['width']?.toDouble(),
      length: map['length']?.toDouble(),
      mass: map['mass']?.toDouble(),
      speciesName: map['speciesName'],
    );
  }
}

enum NestStageType {
  stgUnknown,
  stgBuilding,
  stgLaying,
  stgIncubating,
  stgHatching,
  stgNestling,
  stgInactive,
}

const Map<NestStageType, String> nestStageTypeFriendlyNames = {
  NestStageType.stgUnknown: 'Indeterminado',
  NestStageType.stgBuilding: 'Construção',
  NestStageType.stgLaying: 'Postura',
  NestStageType.stgIncubating: 'Incubação',
  NestStageType.stgHatching: 'Eclosão',
  NestStageType.stgNestling: 'Ninhego',
  NestStageType.stgInactive: 'Inativo',
};

enum NestStatusType {
  nstUnknown,
  nstActive,
  nstInactive,
}

const Map<NestStatusType, String> nestStatusTypeFriendlyNames = {
  NestStatusType.nstUnknown: 'Indeterminado',
  NestStatusType.nstActive: 'Ativo',
  NestStatusType.nstInactive: 'Inativo',
};

class NestRevision {
  int? id;
  int? nestId;
  DateTime? sampleTime;
  NestStatusType nestStatus;
  NestStageType nestStage;
  int? eggsHost;
  int? nestlingsHost;
  int? eggsParasite;
  int? nestlingsParasite;
  bool? hasPhilornisLarvae;
  String? notes;

  NestRevision({
    this.id,
    this.nestId,
    this.sampleTime,
    this.nestStatus = NestStatusType.nstUnknown,
    this.nestStage = NestStageType.stgUnknown,
    this.eggsHost,
    this.nestlingsHost,
    this.eggsParasite,
    this.nestlingsParasite,
    this.hasPhilornisLarvae,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nestId': nestId,
      'sampleTime': sampleTime?.toIso8601String(),
      'nestStatus': nestStatus.index,
      'nestStage': nestStage.index,
      'eggsHost': eggsHost,
      'nestlingsHost': nestlingsHost,
      'eggsParasite': eggsParasite,
      'nestlingsParasite': nestlingsParasite,
      'hasPhilornisLarvae': hasPhilornisLarvae == true ? 1 : 0, // Convert bool to int
      'notes': notes,
    };
  }

  factory NestRevision.fromMap(Map<String, dynamic> map) {
    return NestRevision(
      id: map['id']?.toInt(),
      nestId: map['nestId']?.toInt(),
      sampleTime: map['sampleTime'] != null ? DateTime.parse(map['sampleTime']) : null,
      nestStatus: NestStatusType.values[map['nestStatus']],
      nestStage: NestStageType.values[map['nestStage']],
      eggsHost: map['eggsHost']?.toInt(),
      nestlingsHost: map['nestlingsHost']?.toInt(),
      eggsParasite: map['eggsParasite']?.toInt(),
      nestlingsParasite: map['nestlingsParasite']?.toInt(),
      hasPhilornisLarvae: map['hasPhilornisLarvae'] == 1, // Convert int to bool
      notes: map['notes'],
    );
  }
}

enum NestFateType {
  fatUnknown,
  fatSuccess,
  fatLost,
}

const Map<NestFateType, String> nestFateTypeFriendlyNames = {
  NestFateType.fatUnknown: 'Indeterminado',
  NestFateType.fatSuccess: 'Sucesso',
  NestFateType.fatLost: 'Perdido',
};

class Nest {
  int? id;
  String? fieldNumber;
  String? speciesName;
  String? localityName;
  double? longitude;
  double? latitude;
  String? support;
  double? heightAboveGround;
  DateTime? foundTime;
  DateTime? lastTime;
  NestFateType? nestFate;
  String? male;
  String? female;
  String? helpers;
  bool isActive;
  List<NestRevision>? revisionsList;
  List<Egg>? eggsList;

  Nest({
    this.id,
    this.fieldNumber,
    this.speciesName,
    this.localityName,
    this.longitude,
    this.latitude,
    this.support,
    this.heightAboveGround,
    this.foundTime,
    this.lastTime,
    this.nestFate = NestFateType.fatUnknown,
    this.male,
    this.female,
    this.helpers,
    this.isActive = true,
    this.revisionsList = const [],
    this.eggsList = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fieldNumber': fieldNumber,
      'speciesName': speciesName,
      'localityName': localityName,
      'longitude': longitude,
      'latitude': latitude,
      'support': support,
      'heightAboveGround': heightAboveGround,
      'foundTime': foundTime?.toIso8601String(),
      'lastTime': lastTime?.toIso8601String(),
      'nestFate': nestFate?.index,
      'male': male,
      'female': female,
      'helpers': helpers,
      'isActive': isActive ? 1 : 0,
    };
  }

  factory Nest.fromMap(Map<String, dynamic> map, List<NestRevision> revisionsList, List<Egg> eggsList) {
    return Nest(
      id: map['id']?.toInt(),
      fieldNumber: map['fieldNumber'],
      speciesName: map['speciesName'],
      localityName: map['localityName'],
      longitude: map['longitude']?.toDouble(),
      latitude: map['latitude']?.toDouble(),
      support: map['support'],
      heightAboveGround: map['heightAboveGround']?.toDouble(),
      foundTime: map['foundTime'] != null ? DateTime.parse(map['foundTime']) : null,
      lastTime: map['lastTime'] != null ? DateTime.parse(map['lastTime']) : null,
      nestFate: map['nestFate'] != null ? NestFateType.values[map['nestFate'] as int] : NestFateType.fatUnknown,
      male: map['male'],
      female: map['female'],
      helpers: map['helpers'],
      isActive: map['isActive'] == 1,
      revisionsList: revisionsList,
      eggsList: eggsList,
    );
  }
}

extension NestExport on Nest {
  String toJson() {
    final data = {
      'id': id,
      'fieldNumber': fieldNumber,
      'speciesName': speciesName,
      'localityName': localityName,
      'longitude': longitude,
      'latitude': latitude,
      'support': support,
      'heightAboveGround': heightAboveGround,
      'foundTime': foundTime?.toIso8601String(),
      'lastTime': lastTime?.toIso8601String(),
      'nestFate': nestFate?.index,
      'male': male,
      'female': female,
      'helpers': helpers,
      'isActive': isActive,
      'revisionsList': revisionsList?.map((revision) => revision.toMap())
          .toList(),
      'eggsList': eggsList?.map((egg) => egg.toMap()).toList(),
    };
    return jsonEncode(data);
  }
}