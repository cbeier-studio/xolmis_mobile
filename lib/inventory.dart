
class Poi {
  final int? id;
  final int speciesId;
  double longitude;
  double latitude;

  Poi({
    this.id,
    required this.speciesId,
    required this.longitude,
    required this.latitude,
  });

  factory Poi.fromMap(Map<String, dynamic> map) {
    return Poi(
      id: map['id'],
      speciesId: map['speciesId'],
      longitude: map['longitude'],
      latitude: map['latitude'],
    );
  }

  Poi copyWith({int? id, int? speciesId, double? longitude, double? latitude}) {
    return Poi(
      id: id ?? this.id,
      speciesId: speciesId ?? this.speciesId,
      longitude: longitude ?? this.longitude,
      latitude: latitude ?? this.latitude,
    );
  }

  Map<String, dynamic> toMap(int speciesId) {
    return {
      'id': id,
      'speciesId': speciesId,
      'longitude': longitude,
      'latitude': latitude,
    };
  }

  @override
  String toString() {
    return 'Poi{'
        'id: $id, '
        'speciesId: $speciesId, '
        'longitude: $longitude, '
        'latitude: $latitude}';
  }
}

class Species {
  final int? id;
  final String inventoryId;
  final String name;
  bool isOutOfInventory;
  int count;
  List<Poi> pois;

  Species({
    this.id,
    required this.inventoryId,
    required this.name,
    required this.isOutOfInventory,
    this.count = 0,
    this.pois = const [],
  });

  factory Species.fromMap(Map<String, dynamic> map, List<Poi> pois) {
    return Species(
      id: map['id'],
      inventoryId: map['inventoryId'],
      name: map['name'],
      count: map['count'],
      isOutOfInventory: map['isOutOfInventory'] == 1, // Converte int para boolean
      pois: pois,
    );
  }

  Species copyWith({int? id, String? inventoryId, String? name, bool? isOutOfInventory, int? count, List<Poi>? pois}) {
    return Species(
      id: id ?? this.id,
      inventoryId: inventoryId ?? this.inventoryId,
      name: name ?? this.name,
      isOutOfInventory: isOutOfInventory ?? this.isOutOfInventory,
      count: count ?? this.count,
      pois: pois ?? this.pois,
    );
  }

  Map<String, dynamic> toMap(String inventoryId) {
    return {
      'id': id,
      'inventoryId': inventoryId,
      'name': name,
      'isOutOfInventory': isOutOfInventory ? 1 : 0,
      'count': count,
    };
  }

  @override
  String toString() {
    return 'Species{'
        'id: $id, '
        'inventoryId: $inventoryId, '
        'name: $name, '
        'isOutOfInventory: $isOutOfInventory, '
        'count: $count}';
  }
}

class Vegetation {
  final int? id;
  final String inventoryId;
  final DateTime sampleTime;
  double? longitude;
  double? latitude;
  int? herbsProportion;
  int? herbsDistribution;
  int? herbsHeight;
  int? shrubsProportion;
  int? shrubsDistribution;
  int? shrubsHeight;
  int? treesProportion;
  int? treesDistribution;
  int? treesHeight;
  String? notes;

  Vegetation({
    this.id,
    required this.inventoryId,
    required this.sampleTime,
    this.longitude,
    this.latitude,
    this.herbsProportion,
    this.herbsDistribution,
    this.herbsHeight,
    this.shrubsProportion,
    this.shrubsDistribution,
    this.shrubsHeight,
    this.treesProportion,
    this.treesDistribution,
    this.treesHeight,
    this.notes,
  });

  factory Vegetation.fromMap(Map<String, dynamic> map) {
    return Vegetation(
      id: map['id'],
      inventoryId: map['inventoryId'],
      sampleTime: DateTime.parse(map['sampleTime']),
      longitude: map['longitude'],
      latitude: map['latitude'],
      herbsProportion: map['herbsProportion'],
      herbsDistribution: map['herbsDistribution'],
      herbsHeight: map['herbsHeight'],
      shrubsProportion: map['shrubsProportion'],
      shrubsDistribution: map['shrubsDistribution'],
      shrubsHeight: map['shrubsHeight'],
      treesProportion: map['treesProportion'],
      treesDistribution: map['treesDistribution'],
      treesHeight: map['treesHeight'],
      notes: map['notes'],
    );
  }

  Vegetation copyWith({int? id, String? inventoryId, DateTime? sampleTime}) {
    return Vegetation(
      id: id ?? this.id,
      inventoryId: inventoryId ?? this.inventoryId,
      sampleTime: sampleTime ?? this.sampleTime,
      longitude: longitude,
      latitude: latitude,
      herbsProportion: herbsProportion,
      herbsDistribution: herbsDistribution,
      herbsHeight: herbsHeight,
      shrubsProportion: shrubsProportion,
      shrubsDistribution: shrubsDistribution,
      shrubsHeight: shrubsHeight,
      treesProportion: treesProportion,
      treesDistribution: treesDistribution,
      treesHeight: treesHeight,
      notes: notes,
    );
  }

  Map<String, dynamic> toMap(String inventoryId) {
    return {
      'id': id,
      'inventoryId': inventoryId,
      'sampleTime': sampleTime.toIso8601String(),
      'longitude': longitude,
      'latitude': latitude,
      'herbsProportion': herbsProportion,
      'herbsDistribution': herbsDistribution,
      'herbsHeight': herbsHeight,
      'shrubsProportion': shrubsProportion,
      'shrubsDistribution': shrubsDistribution,
      'shrubsHeight': shrubsHeight,
      'treesProportion': treesProportion,
      'treesDistribution': treesDistribution,
      'treesHeight': treesHeight,
      'notes': notes,
    };
  }

  @override
  String toString() {
    return 'Vegetation{'
        'id: $id, '
        'inventoryId: $inventoryId, '
        'sampleTime: $sampleTime, '
        'longitude: $longitude, '
        'latitude: $latitude, '
        'herbsProportion: $herbsProportion, '
        'herbsDistribution: $herbsDistribution, '
        'herbsHeight: $herbsHeight, '
        'shrubsProportion: $shrubsProportion, '
        'shrubsDistribution: $shrubsDistribution, '
        'shrubsHeight: $shrubsHeight, '
        'treesProportion: $treesProportion, '
        'treesDistribution: $treesDistribution, '
        'treesHeight: $treesHeight, '
        'notes: $notes}';
  }
}

enum InventoryType {
  invQualitative,
  invMackinnon,
  invTransection,
  invPointCount,
  invCumulativeTime,
}

const Map<InventoryType, String> inventoryTypeFriendlyNames = {
  InventoryType.invQualitative: 'Lista Qualitativa',
  InventoryType.invMackinnon: 'Lista de Mackinnon',
  InventoryType.invTransection: 'Contagem em Transeção',
  InventoryType.invPointCount: 'Ponto de Contagem',
  InventoryType.invCumulativeTime: 'Lista Cumulativa por Tempo',
};

class Inventory {
  final String id;
  final InventoryType type;
  int duration;
  bool isPaused;
  bool isFinished;
  int remainingTime;
  double elapsedTime;
  DateTime? startTime;
  DateTime? endTime;
  double? startLongitude;
  double? startLatitude;
  double? endLongitude;
  double? endLatitude;
  List<Species> speciesList;
  List<Vegetation> vegetationList;

  Inventory({
    required this.id,
    required this.type,
    required this.duration,
    this.isPaused = false,
    this.isFinished = false,
    this.remainingTime = 0,
    this.elapsedTime = 0,
    this.startTime,
    this.endTime,
    this.startLongitude,
    this.startLatitude,
    this.endLongitude,
    this.endLatitude,
    this.speciesList = const [],
    this.vegetationList = const [],
  });

  Inventory.fromMap(Map<String, dynamic> map, List<Species> speciesList, List<Vegetation> vegetationList)
      : id = map['id'],
        type = InventoryType.values[map['type']], // Converte de índice para enum
        duration = (map['duration'] as num).toInt(),
        isPaused = map['isPaused'] == 1,
        isFinished = map['isFinished'] == 1,
        remainingTime = map['remainingTime'],
        elapsedTime = map['elapsedTime'],
        startTime = map['startTime'] != null ? DateTime.parse(map['startTime']) : null,
        endTime = map['endTime'] != null ? DateTime.parse(map['endTime']) : null,
        startLongitude = map['startLongitude'],
        startLatitude = map['startLatitude'],
        endLongitude = map['endLongitude'],
        endLatitude = map['endLatitude'],
        speciesList = speciesList,
        vegetationList = vegetationList;

  Inventory copyWith({
    String? id,
    InventoryType? type,
    int? duration,
    bool? isPaused,
    bool? isFinished,
    int? remainingTime,
    double? elapsedTime,
    DateTime? startTime,
    DateTime? endTime,
    double? startLongitude,
    double? startLatitude,
    double? endLongitude,
    double? endLatitude,
    List<Species>? speciesList,
    List<Vegetation>? vegetationList,
  }) {
    return Inventory(
      id: id ?? this.id,
      type: type ?? this.type,
      duration: duration ?? this.duration,
      isPaused: isPaused ?? this.isPaused,
      isFinished: isFinished ?? this.isFinished,
      remainingTime: remainingTime ?? this.remainingTime,
      elapsedTime: elapsedTime ?? this.elapsedTime,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      startLongitude: startLongitude ?? this.startLongitude,
      startLatitude: startLatitude ?? this.startLatitude,
      endLongitude: endLongitude ?? this.endLongitude,
      endLatitude: endLatitude ?? this.endLatitude,
      speciesList: speciesList ?? this.speciesList,
      vegetationList: vegetationList ?? this.vegetationList,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.index,
      'duration': duration,
      'isPaused': isPaused ? 1 : 0,
      'isFinished': isFinished ? 1 : 0,
      'remainingTime': remainingTime,
      'elapsedTime': elapsedTime,
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'startLongitude': startLongitude,
      'startLatitude': startLatitude,
      'endLongitude': endLongitude,
      'endLatitude': endLatitude,
    };
  }

  @override
  String toString() {
    return 'Inventory{'
        'id: $id, '
        'type: $type.index, '
        'duration: $duration, '
        'isPaused: $isPaused, '
        'isFinished: $isFinished, '
        'remainingTime: $remainingTime, '
        'elapsedTime: $elapsedTime, '
        'startTime: $startTime, '
        'endTime: $endTime, '
        'startLongitude: $startLongitude, '
        'startLatitude: $startLatitude, '
        'endLongitude: $endLongitude, '
        'endLatitude: $endLatitude}';
  }
}

