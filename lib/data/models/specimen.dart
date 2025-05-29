import '../../generated/l10n.dart';

// Specimen class

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

class Specimen {
  int? id;
  DateTime? sampleTime;
  String fieldNumber;
  SpecimenType type;
  double? longitude;
  double? latitude;
  String? locality;
  String? speciesName;
  String? notes;
  bool isPending;

  Specimen({
    this.id,
    this.sampleTime,
    this.fieldNumber = '',
    this.type = SpecimenType.spcFeathers,
    this.longitude,
    this.latitude,
    this.locality,
    this.speciesName,
    this.notes,
    this.isPending = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sampleTime': sampleTime?.toIso8601String(),
      'fieldNumber': fieldNumber,
      'type': type.index,
      'longitude': longitude,
      'latitude': latitude,
      'locality': locality,
      'speciesName': speciesName,
      'notes': notes,
      'isPending': isPending ? 1 : 0,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sampleTime': sampleTime?.toIso8601String(),
      'fieldNumber': fieldNumber,
      'type': type.index,
      'longitude': longitude,
      'latitude': latitude,
      'locality': locality,
      'speciesName': speciesName,
      'notes': notes,
      'isPending': isPending,
    };
  }

  factory Specimen.fromMap(Map<String, dynamic> map) {
    return Specimen(
      id: map['id']?.toInt(),
      sampleTime: map['sampleTime'] != null ? DateTime.parse(map['sampleTime']) : null,
      fieldNumber: map['fieldNumber'],
      type: SpecimenType.values[map['type']],
      longitude: map['longitude']?.toDouble(),
      latitude: map['latitude']?.toDouble(),
      locality: map['locality'],
      speciesName: map['speciesName'],
      notes: map['notes'],
      isPending: map['isPending'] == 1,
    );
  }

  Specimen copyWith({
    int? id,
    DateTime? sampleTime,
    String? fieldNumber,
    SpecimenType? type,
    double? longitude,
    double? latitude,
    String? locality,
    String? speciesName,
    String? notes,
    bool? isPending,
  }) {
    return Specimen(
      id: id ?? this.id,
      sampleTime: sampleTime ?? this.sampleTime,
      fieldNumber: fieldNumber ?? this.fieldNumber,
      type: type ?? this.type,
      longitude: longitude ?? this.longitude,
      latitude: latitude ?? this.latitude,
      locality: locality ?? this.locality,
      speciesName: speciesName ?? this.speciesName,
      notes: notes ?? this.notes,
      isPending: isPending ?? this.isPending,
    );
  }
}