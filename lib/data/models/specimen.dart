import '../../core/core_consts.dart';

// Specimen class

class Specimen {
  int? id;
  DateTime? sampleTime;
  String fieldNumber;
  SpecimenType type;
  double? longitude;
  double? latitude;
  String? locality;
  String? speciesName;
  String? observer;
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
    this.observer,
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
      'observer': observer,
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
      'observer': observer,
      'notes': notes,
      'isPending': isPending,
    };
  }

  factory Specimen.fromJson(Map<String, dynamic> json) {
    return Specimen(
      id: json['id'],
      sampleTime: json['sampleTime'] != null ? DateTime.parse(json['sampleTime']) : null,
      fieldNumber: json['fieldNumber'],
      type: json['type'] != null ? SpecimenType.values[json['type']] : SpecimenType.spcFeathers,
      longitude: json['longitude'],
      latitude: json['latitude'],
      locality: json['locality'],
      speciesName: json['speciesName'],
      observer: json['observer'],
      notes: json['notes'],
      isPending: json['isPending'] == 1,
    );
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
      observer: map['observer'],
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
    String? observer,
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
      observer: observer ?? this.observer,
      notes: notes ?? this.notes,
      isPending: isPending ?? this.isPending,
    );
  }
}