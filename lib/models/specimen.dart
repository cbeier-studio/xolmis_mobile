
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

const Map<SpecimenType, String> specimenTypeFriendlyNames = {
  SpecimenType.spcWholeCarcass: 'Carcaça inteira',
  SpecimenType.spcPartialCarcass: 'Carcaça parcial',
  SpecimenType.spcNest: 'Ninho',
  SpecimenType.spcBones: 'Ossos',
  SpecimenType.spcEgg: 'Ovo',
  SpecimenType.spcParasites: 'Parasitas',
  SpecimenType.spcFeathers: 'Penas',
  SpecimenType.spcBlood: 'Sangue',
  SpecimenType.spcClaw: 'Garra',
  SpecimenType.spcSwab: 'Swab',
  SpecimenType.spcTissues: 'Tecidos',
  SpecimenType.spcFeces: 'Fezes',
  SpecimenType.spcRegurgite: 'Regurgito',
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
    );
  }
}