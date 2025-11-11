import '../../core/core_consts.dart';

// Egg class

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

  Map<String, dynamic> toJson() {
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

  factory Egg.fromJson(Map<String, dynamic> json) {
    return Egg(
      id: json['id'],
      nestId: json['nestId'],
      sampleTime: json['sampleTime'] != null ? DateTime.parse(json['sampleTime']) : null,
      fieldNumber: json['fieldNumber'],
      eggShape: json['eggShape'] != null ? EggShapeType.values[json['eggShape']] : EggShapeType.estOval,
      width: json['width'],
      length: json['length'],
      mass: json['mass'],
      speciesName: json['speciesName'],
    );
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

  Egg copyWith({
    int? id,
    int? nestId,
    DateTime? sampleTime,
    String? fieldNumber,
    EggShapeType? eggShape,
    double? width,
    double? length,
    double? mass,
    String? speciesName,
  }) {
    return Egg(
      id: id ?? this.id,
      nestId: nestId ?? this.nestId,
      sampleTime: sampleTime ?? this.sampleTime,
      fieldNumber: fieldNumber ?? this.fieldNumber,
      eggShape: eggShape ?? this.eggShape,
      width: width ?? this.width,
      length: length ?? this.length,
      mass: mass ?? this.mass,
      speciesName: speciesName ?? this.speciesName,
    );
  }
}

// Nest revision class

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

  Map<String, dynamic> toJson() {
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

  factory NestRevision.fromJson(Map<String, dynamic> json) {
    return NestRevision(
      id: json['id'],
      nestId: json['nestId'],
      sampleTime: json['sampleTime'] != null ? DateTime.parse(json['sampleTime']) : null,
      nestStatus: json['nestStatus'] != null ? NestStatusType.values[json['nestStatus']] : NestStatusType.nstUnknown,
      nestStage: json['nestStage'] != null ? NestStageType.values[json['nestStage']] : NestStageType.stgUnknown,
      eggsHost: json['eggsHost'],
      nestlingsHost: json['nestlingsHost'],
      eggsParasite: json['eggsParasite'],
      nestlingsParasite: json['nestlingsParasite'],
      hasPhilornisLarvae: json['hasPhilornisLarvae'] == 1,
      notes: json['notes'],
    );
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

  NestRevision copyWith({
    int? id,
    int? nestId,
    DateTime? sampleTime,
    NestStatusType? nestStatus,
    NestStageType? nestStage,
    int? eggsHost,
    int? nestlingsHost,
    int? eggsParasite,
    int? nestlingsParasite,
    bool? hasPhilornisLarvae,
    String? notes,
  }) {
    return NestRevision(
      id: id ?? this.id,
      nestId: nestId ?? this.nestId,
      sampleTime: sampleTime ?? this.sampleTime,
      nestStatus: nestStatus ?? this.nestStatus,
      nestStage: nestStage ?? this.nestStage,
      eggsHost: eggsHost ?? this.eggsHost,
      nestlingsHost: nestlingsHost ?? this.nestlingsHost,
      eggsParasite: eggsParasite ?? this.eggsParasite,
      nestlingsParasite: nestlingsParasite ?? this.nestlingsParasite,
      hasPhilornisLarvae: hasPhilornisLarvae ?? this.hasPhilornisLarvae,
      notes: notes ?? this.notes,
    );
  }
}

// Nest class

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

  Map<String, dynamic> toJson() {
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
      'isActive': isActive,
      'revisionsList': revisionsList?.map((nestRevision) => nestRevision.toJson()).toList(),
      'eggsList': eggsList?.map((egg) => egg.toJson()).toList(),
    };
  }

  factory Nest.fromJson(Map<String, dynamic> json) {
    return Nest(
      id: json['id'],
      fieldNumber: json['fieldNumber'],
      speciesName: json['speciesName'],
      localityName: json['localityName'],
      foundTime: json['foundTime'] != null ? DateTime.parse(json['foundTime']) : null,
      lastTime: json['lastTime'] != null ? DateTime.parse(json['lastTime']) : null,
      longitude: json['longitude'],
      latitude: json['latitude'],
      support: json['support'],
      heightAboveGround: json['heightAboveGround'],
      nestFate: json['nestFate'] != null ? NestFateType.values[json['nestFate']] : NestFateType.fatUnknown,
      male: json['male'],
      female: json['female'],
      helpers: json['helpers'],
      isActive: json['isActive'] == 1,
      revisionsList: (json['revisionsList'] as List).map((item) => NestRevision.fromJson(item)).toList(),
      eggsList: (json['eggsList'] as List).map((item) => Egg.fromJson(item)).toList(),
    );
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

  Nest copyWith({
    int? id,
    String? fieldNumber,
    String? speciesName,
    String? localityName,
    double? longitude,
    double? latitude,
    String? support,
    double? heightAboveGround,
    DateTime? foundTime,
    DateTime? lastTime,
    NestFateType? nestFate,
    String? male,
    String? female,
    String? helpers,
    bool? isActive,
    List<NestRevision>? revisionsList,
    List<Egg>? eggsList,
  }) {
    return Nest(
      id: id ?? this.id,
      fieldNumber: fieldNumber ?? this.fieldNumber,
      speciesName: speciesName ?? this.speciesName,
      localityName: localityName ?? this.localityName,
      longitude: longitude ?? this.longitude,
      latitude: latitude ?? this.latitude,
      support: support ?? this.support,
      heightAboveGround: heightAboveGround ?? this.heightAboveGround,
      foundTime: foundTime ?? this.foundTime,
      lastTime: lastTime ?? this.lastTime,
      nestFate: nestFate ?? this.nestFate,
      male: male ?? this.male,
      female: female ?? this.female,
      helpers: helpers ?? this.helpers,
      isActive: isActive ?? this.isActive,
      revisionsList: revisionsList ?? this.revisionsList,
      eggsList: eggsList ?? this.eggsList,
    );
  }
}
