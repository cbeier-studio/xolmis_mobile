import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../utils/utils.dart';

import '../database/daos/inventory_dao.dart';

import '../../main.dart';

import '../../generated/l10n.dart';


// POI class

class Poi {
  late int? id;
  final int speciesId;
  DateTime? sampleTime;
  double longitude;
  double latitude;
  String? notes;

  Poi({
    this.id,
    required this.speciesId,
    required this.sampleTime,
    required this.longitude,
    required this.latitude,
    this.notes,
  });

  factory Poi.fromMap(Map<String, dynamic> map) {
    return Poi(
      id: map['id'],
      speciesId: map['speciesId'],
      sampleTime: map['sampleTime'] != null ? DateTime.parse(map['sampleTime']) : null,
      longitude: map['longitude'],
      latitude: map['latitude'],
      notes: map['notes'],
    );
  }

  Poi copyWith({int? id, int? speciesId, DateTime? sampleTime, double? longitude, double? latitude, String? notes}) {
    return Poi(
      id: id ?? this.id,
      speciesId: speciesId ?? this.speciesId,
      sampleTime: sampleTime ?? this.sampleTime,
      longitude: longitude ?? this.longitude,
      latitude: latitude ?? this.latitude,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap(int speciesId) {
    return {
      'id': id,
      'speciesId': speciesId,
      'sampleTime': sampleTime?.toIso8601String(),
      'longitude': longitude,
      'latitude': latitude,
      'notes': notes,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'speciesId': speciesId,
      'sampleTime': sampleTime?.toIso8601String(),
      'longitude': longitude,
      'latitude': latitude,
      'notes': notes,
    };
  }

  factory Poi.fromJson(Map<String, dynamic> json) {
    return Poi(
      id: json['id'],
      speciesId: json['speciesId'],
      sampleTime: json['sampleTime'] != null ? DateTime.parse(json['sampleTime']) : null,
      longitude: json['longitude'],
      latitude: json['latitude'],
      notes: json['notes'],
    );
  }

  @override
  String toString() {
    return 'Poi{'
        'id: $id, '
        'speciesId: $speciesId, '
        'sampleTime: $sampleTime, '
        'longitude: $longitude, '
        'latitude: $latitude, '
        'notes: $notes}';
  }
}

// Species class

class Species {
  late int? id;
  final String inventoryId;
  final String name;
  bool isOutOfInventory;
  int count;
  String? notes;
  DateTime? sampleTime;
  double? distance;
  double? flightHeight;
  String? flightDirection;
  List<Poi> pois;

  Species({
    this.id,
    required this.inventoryId,
    required this.name,
    required this.isOutOfInventory,
    this.count = 0,
    this.notes,
    this.sampleTime,
    this.distance,
    this.flightHeight,
    this.flightDirection,
    this.pois = const [],
  });

  factory Species.fromMap(Map<String, dynamic> map, List<Poi> pois) {
    return Species(
      id: map['id'],
      inventoryId: map['inventoryId'],
      name: map['name'],
      count: map['count'],
      notes: map['notes'],
      sampleTime: map['sampleTime'] != null
          ? DateTime.parse(map['sampleTime'])
          : null,
      isOutOfInventory: map['isOutOfInventory'] == 1, // Convert int to boolean
      distance: map['distance'],
      flightHeight: map['flightHeight'],
      flightDirection: map['flightDirection'],
      pois: pois,
    );
  }

  Species copyWith({
    int? id,
    String? inventoryId,
    String? name,
    bool? isOutOfInventory,
    int? count,
    String? notes,
    DateTime? sampleTime,
    double? distance,
    double? flightHeight,
    String? flightDirection,
    List<Poi>? pois
  }) {
    return Species(
      id: id ?? this.id,
      inventoryId: inventoryId ?? this.inventoryId,
      name: name ?? this.name,
      isOutOfInventory: isOutOfInventory ?? this.isOutOfInventory,
      count: count ?? this.count,
      notes: notes ?? this.notes,
      sampleTime: sampleTime ?? this.sampleTime,
      distance: distance ?? this.distance,
      flightHeight: flightHeight ?? this.flightHeight,
      flightDirection: flightDirection ?? this.flightDirection,
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
      'notes': notes,
      'sampleTime': sampleTime?.toIso8601String(),
      'distance': distance,
      'flightHeight': flightHeight,
      'flightDirection': flightDirection
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'inventoryId': inventoryId,
      'name': name,
      'isOutOfInventory': isOutOfInventory ? 1 : 0,
      'count': count,
      'notes': notes,
      'sampleTime': sampleTime?.toIso8601String(),
      'distance': distance,
      'flightHeight': flightHeight,
      'flightDirection': flightDirection,
      'pois': pois.map((poi) => poi.toJson()).toList(),
    };
  }

  factory Species.fromJson(Map<String, dynamic> json) {
    return Species(
      id: json['id'],
      inventoryId: json['inventoryId'],
      name: json['name'],
      isOutOfInventory: json['isOutOfInventory'] == 1,
      count: json['count'],
      notes: json['notes'],
      sampleTime: json['sampleTime'] != null ? DateTime.parse(json['sampleTime']) : null,
      distance: json['distance'],
      flightHeight: json['flightHeight'],
      flightDirection: json['flightDirection'],
      pois: (json['pois'] as List).map((item) => Poi.fromJson(item)).toList(),
    );
  }

  @override
  String toString() {
    return 'Species{'
        'id: $id, '
        'inventoryId: $inventoryId, '
        'name: $name, '
        'isOutOfInventory: $isOutOfInventory, '
        'count: $count, '
        'sampleTime: $sampleTime, '
        'distance: $distance, '
        'flightHeight: $flightHeight, '
        'flightDirection: $flightDirection, '
        'notes: $notes}';
  }
}

// Vegetation class

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

class Vegetation {
  late int? id;
  final String inventoryId;
  final DateTime? sampleTime;
  double? longitude;
  double? latitude;
  int? herbsProportion;
  DistributionType? herbsDistribution = DistributionType.disNone;
  int? herbsHeight;
  int? shrubsProportion;
  DistributionType? shrubsDistribution = DistributionType.disNone;
  int? shrubsHeight;
  int? treesProportion;
  DistributionType? treesDistribution = DistributionType.disNone;
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
      sampleTime: map['sampleTime'] != null
          ? DateTime.parse(map['sampleTime'])
          : null,
      longitude: map['longitude'],
      latitude: map['latitude'],
      herbsProportion: map['herbsProportion'],
      herbsDistribution: DistributionType.values[map['herbsDistribution']],
      herbsHeight: map['herbsHeight'],
      shrubsProportion: map['shrubsProportion'],
      shrubsDistribution: DistributionType.values[map['shrubsDistribution']],
      shrubsHeight: map['shrubsHeight'],
      treesProportion: map['treesProportion'],
      treesDistribution: DistributionType.values[map['treesDistribution']],
      treesHeight: map['treesHeight'],
      notes: map['notes'],
    );
  }

  Vegetation copyWith({
    int? id,
    String? inventoryId,
    DateTime? sampleTime,
    double? longitude,
    double? latitude,
    int? herbsProportion,
    DistributionType? herbsDistribution,
    int? herbsHeight,
    int? shrubsProportion,
    DistributionType? shrubsDistribution,
    int? shrubsHeight,
    int? treesProportion,
    DistributionType? treesDistribution,
    int? treesHeight,
    String? notes,
  }) {
    return Vegetation(
      id: id ?? this.id,
      inventoryId: inventoryId ?? this.inventoryId,
      sampleTime: sampleTime ?? this.sampleTime,
      longitude: longitude ?? this.longitude,
      latitude: latitude ?? this.latitude,
      herbsProportion: herbsProportion ?? this.herbsProportion,
      herbsDistribution: herbsDistribution ?? this.herbsDistribution,
      herbsHeight: herbsHeight ?? this.herbsHeight,
      shrubsProportion: shrubsProportion ?? this.shrubsProportion,
      shrubsDistribution: shrubsDistribution ?? this.shrubsDistribution,
      shrubsHeight: shrubsHeight ?? this.shrubsHeight,
      treesProportion: treesProportion ?? this.treesProportion,
      treesDistribution: treesDistribution ?? this.treesDistribution,
      treesHeight: treesHeight ?? this.treesHeight,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toMap(String inventoryId) {
    return {
      'id': id,
      'inventoryId': inventoryId,
      'sampleTime': sampleTime?.toIso8601String(),
      'longitude': longitude,
      'latitude': latitude,
      'herbsProportion': herbsProportion,
      'herbsDistribution': herbsDistribution?.index,
      'herbsHeight': herbsHeight,
      'shrubsProportion': shrubsProportion,
      'shrubsDistribution': shrubsDistribution?.index,
      'shrubsHeight': shrubsHeight,
      'treesProportion': treesProportion,
      'treesDistribution': treesDistribution?.index,
      'treesHeight': treesHeight,
      'notes': notes,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'inventoryId': inventoryId,
      'sampleTime': sampleTime?.toIso8601String(),
      'longitude': longitude,
      'latitude': latitude,
      'herbsProportion': herbsProportion,
      'herbsDistribution': herbsDistribution?.index,
      'herbsHeight': herbsHeight,
      'shrubsProportion': shrubsProportion,
      'shrubsDistribution': shrubsDistribution?.index,
      'shrubsHeight': shrubsHeight,
      'treesProportion': treesProportion,
      'treesDistribution': treesDistribution?.index,
      'treesHeight': treesHeight,
      'notes': notes,
    };
  }

  factory Vegetation.fromJson(Map<String, dynamic> json) {
    return Vegetation(
      id: json['id'],
      inventoryId: json['inventoryId'],
      sampleTime: json['sampleTime'] != null ? DateTime.parse(json['sampleTime']) : null,
      longitude: json['longitude'],
      latitude: json['latitude'],
      herbsProportion: json['herbsProportion'],
      herbsDistribution: json['herbsDistribution'] != null ? DistributionType.values[json['herbsDistribution']] : DistributionType.disNone,
      herbsHeight: json['herbsHeight'],
      shrubsProportion: json['shrubsProportion'],
      shrubsDistribution: json['shrubsDistribution'] != null ? DistributionType.values[json['shrubsDistribution']] : DistributionType.disNone,
      shrubsHeight: json['shrubsHeight'],
      treesProportion: json['treesProportion'],
      treesDistribution: json['treesDistribution'] != null ? DistributionType.values[json['treesDistribution']] : DistributionType.disNone,
      treesHeight: json['treesHeight'],
      notes: json['notes'],
    );
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

// Weather class

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

class Weather {
  late int? id;
  final String inventoryId;
  final DateTime? sampleTime;
  int? cloudCover;
  PrecipitationType? precipitation = PrecipitationType.preNone;
  double? temperature;
  int? windSpeed;
  String? windDirection;
  double? atmosphericPressure;
  double? relativeHumidity;

  Weather({
    this.id,
    required this.inventoryId,
    required this.sampleTime,
    this.cloudCover,
    this.precipitation,
    this.temperature,
    this.windSpeed,
    this.windDirection,
    this.atmosphericPressure,
    this.relativeHumidity,
  });

  factory Weather.fromMap(Map<String, dynamic> map) {
    return Weather(
      id: map['id'],
      inventoryId: map['inventoryId'],
      sampleTime: map['sampleTime'] != null
          ? DateTime.parse(map['sampleTime'])
          : null,
      cloudCover: map['cloudCover'],
      precipitation: PrecipitationType.values[map['precipitation']],
      temperature: map['temperature'],
      windSpeed: map['windSpeed'],
      windDirection: map['windDirection'],
      atmosphericPressure: map['atmosphericPressure'],
      relativeHumidity: map['relativeHumidity'],
    );
  }

  Weather copyWith({
      int? id,
      String? inventoryId,
      DateTime? sampleTime,
      int? cloudCover,
      PrecipitationType? precipitation,
      double? temperature,
      int? windSpeed,
      String? windDirection,
      double? atmosphericPressure,
      double? relativeHumidity,
  }) {
    return Weather(
      id: id ?? this.id,
      inventoryId: inventoryId ?? this.inventoryId,
      sampleTime: sampleTime ?? this.sampleTime,
      cloudCover: cloudCover ?? this.cloudCover,
      precipitation: precipitation ?? this.precipitation,
      temperature: temperature ?? this.temperature,
      windSpeed: windSpeed ?? this.windSpeed,
      windDirection: windDirection ?? this.windDirection,
      atmosphericPressure: atmosphericPressure ?? this.atmosphericPressure,
      relativeHumidity: relativeHumidity ?? this.relativeHumidity,
    );
  }

  Map<String, dynamic> toMap(String inventoryId) {
    return {
      'id': id,
      'inventoryId': inventoryId,
      'sampleTime': sampleTime?.toIso8601String(),
      'cloudCover': cloudCover,
      'precipitation': precipitation?.index,
      'temperature': temperature,
      'windSpeed': windSpeed,
      'windDirection': windDirection,
      'atmosphericPressure': atmosphericPressure,
      'relativeHumidity': relativeHumidity,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'inventoryId': inventoryId,
      'sampleTime': sampleTime?.toIso8601String(),
      'cloudCover': cloudCover,
      'precipitation': precipitation?.index,
      'temperature': temperature,
      'windSpeed': windSpeed,
      'windDirection': windDirection,
      'atmosphericPressure': atmosphericPressure,
      'relativeHumidity': relativeHumidity,
    };
  }

  factory Weather.fromJson(Map<String, dynamic> json) {
    return Weather(
      id: json['id'],
      inventoryId: json['inventoryId'],
      sampleTime: DateTime.parse(json['sampleTime']), 
      cloudCover: json['cloudCover'],
      precipitation: json['precipitation'] != null ? PrecipitationType.values[json['precipitation']] : PrecipitationType.preNone,
      temperature: json['temperature'],
      windSpeed: json['windSpeed'],
      windDirection: json['windDirection'],
      atmosphericPressure: json['atmosphericPressure'],
      relativeHumidity: json['relativeHumidity'],
    );
  } 

  @override
  String toString() {
    return 'Weather{ '
        'id: $id, '
        'inventoryId: $inventoryId, '
        'sampleTime: $sampleTime, '
        'cloudCover: $cloudCover, '
        'precipitation: $precipitation, '
        'temperature: $temperature, '
        'windSpeed: $windSpeed, '
        'windDirection: $windDirection, '
        'atmosphericPressure: $atmosphericPressure, '
        'relativeHumidity: $relativeHumidity }';
  }
}

// Inventory class

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

class Inventory with ChangeNotifier {
  String id;
  final InventoryType type;
  int duration;
  int maxSpecies;
  bool isPaused;
  bool isFinished;
  double elapsedTime;
  DateTime? startTime;
  DateTime? endTime;
  double? startLongitude;
  double? startLatitude;
  double? endLongitude;
  double? endLatitude;
  String? localityName;
  int totalObservers;
  String? notes;
  bool isDiscarded;
  List<Species> speciesList;
  List<Vegetation> vegetationList;
  List<Weather> weatherList;
  StreamSubscription<void>? _timer;
  final ValueNotifier<double> _elapsedTimeNotifier = ValueNotifier<double>(0);
  ValueNotifier<double> get elapsedTimeNotifier => _elapsedTimeNotifier;
  final ValueNotifier<bool> _isFinishedNotifier = ValueNotifier<bool>(false);
  ValueNotifier<bool> get isFinishedNotifier => _isFinishedNotifier;
  bool _autoFinished = false;
  bool isAutoFinished() => _autoFinished;
  int currentInterval = 1;
  final ValueNotifier<int> _currentIntervalNotifier = ValueNotifier<int>(1);
  ValueNotifier<int> get currentIntervalNotifier => _currentIntervalNotifier;
  int intervalsWithoutNewSpecies = 0;
  final ValueNotifier<int> _intervalWithoutSpeciesNotifier = ValueNotifier<int>(0);
  ValueNotifier<int> get intervalWithoutSpeciesNotifier => _intervalWithoutSpeciesNotifier;
  int currentIntervalSpeciesCount = 0;

  Inventory({
    required this.id,
    required this.type,
    required this.duration,
    this.maxSpecies = 0,
    this.isPaused = false,
    this.isFinished = false,
    this.elapsedTime = 0,
    this.startTime,
    this.endTime,
    this.startLongitude,
    this.startLatitude,
    this.endLongitude,
    this.endLatitude,
    this.localityName,
    this.totalObservers = 1,
    this.notes,
    this.isDiscarded = false,
    this.speciesList = const [],
    this.vegetationList = const [],
    this.weatherList = const [],
    this.currentInterval = 1,
    this.intervalsWithoutNewSpecies = 0,
    this.currentIntervalSpeciesCount = 0,
  }) {
    if (duration == 0) {
      elapsedTime = 0;
    }
  }

  Inventory.fromMap(Map<String, dynamic> map, List<Species> speciesList,
      List<Vegetation> vegetationList, List<Weather> weatherList)
      : id = map['id'],
        type = InventoryType.values[map['type']],
        duration = map['duration'],
        maxSpecies = map['maxSpecies'],
        isPaused = map['isPaused'] == 1,
        isFinished = map['isFinished'] == 1,
        elapsedTime = map['elapsedTime'],
        startTime = map['startTime'] != null
            ? DateTime.parse(map['startTime'])
            : null,
        endTime = map['endTime'] != null
            ? DateTime.parse(map['endTime'])
            : null,
        startLongitude = map['startLongitude'] ?? 0,
        startLatitude = map['startLatitude'] ?? 0,
        endLongitude = map['endLongitude'] ?? 0,
        endLatitude = map['endLatitude'] ?? 0,
        localityName = map['localityName'],
        totalObservers = map['totalObservers'] ?? 1,
        notes = map['notes'],
        isDiscarded = map['isDiscarded'] == 1,
        currentInterval = map['currentInterval'] ?? 1,
        intervalsWithoutNewSpecies = map['intervalsWithoutNewSpecies'] ?? 0,
        currentIntervalSpeciesCount = map['currentIntervalSpeciesCount'] ?? 0,
        this.speciesList = speciesList,
        this.vegetationList = vegetationList,
        this.weatherList = weatherList;

  Inventory copyWith({
    String? id,
    InventoryType? type,
    int? duration,
    int? maxSpecies,
    bool? isPaused,
    bool? isFinished,
    double? elapsedTime,
    DateTime? startTime,
    DateTime? endTime,
    double? startLongitude,
    double? startLatitude,
    double? endLongitude,
    double? endLatitude,
    int? currentInterval,
    int? intervalsWithoutNewSpecies,
    int? currentIntervalSpeciesCount,
    String? localityName,
    int? totalObservers,
    String? notes,
    bool? isDiscarded,
    List<Species>? speciesList,
    List<Vegetation>? vegetationList,
    List<Weather>? weatherList,
  }) {
    return Inventory(
      id: id ?? this.id,
      type: type ?? this.type,
      duration: duration ?? this.duration,
      maxSpecies: maxSpecies ?? this.maxSpecies,
      isPaused: isPaused ?? this.isPaused,
      isFinished: isFinished ?? this.isFinished,
      elapsedTime: elapsedTime ?? this.elapsedTime,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      startLongitude: startLongitude ?? this.startLongitude,
      startLatitude: startLatitude ?? this.startLatitude,
      endLongitude: endLongitude ?? this.endLongitude,
      endLatitude: endLatitude ?? this.endLatitude,
      currentInterval: currentInterval ?? this.currentInterval,
      intervalsWithoutNewSpecies: intervalsWithoutNewSpecies ?? this.intervalsWithoutNewSpecies,
      currentIntervalSpeciesCount: currentIntervalSpeciesCount ?? this.currentIntervalSpeciesCount,
      localityName: localityName ?? this.localityName,
      totalObservers: totalObservers ?? this.totalObservers,
      notes: notes ?? this.notes,
      isDiscarded: isDiscarded ?? this.isDiscarded,
      speciesList: speciesList ?? this.speciesList,
      vegetationList: vegetationList ?? this.vegetationList,
      weatherList: weatherList ?? this.weatherList,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.index,
      'duration': duration,
      'maxSpecies': maxSpecies,
      'isPaused': isPaused ? 1 : 0,
      'isFinished': isFinished ? 1 : 0,
      'elapsedTime': elapsedTime,
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'startLongitude': startLongitude,
      'startLatitude': startLatitude,
      'endLongitude': endLongitude,
      'endLatitude': endLatitude,
      'currentInterval': currentInterval,
      'intervalsWithoutNewSpecies': intervalsWithoutNewSpecies,
      'currentIntervalSpeciesCount': currentIntervalSpeciesCount,
      'localityName': localityName,
      'totalObservers': totalObservers,
      'notes': notes,
      'isDiscarded': isDiscarded ? 1 : 0,
    };
  }

  @override
  String toString() {
    return 'Inventory{'
        'id: $id, '
        'type: $type.index, '
        'duration: $duration, '
        'maxSpecies: $maxSpecies, '
        'isPaused: $isPaused, '
        'isFinished: $isFinished, '
        'elapsedTime: $elapsedTime, '
        'startTime: $startTime, '
        'endTime: $endTime, '
        'startLongitude: $startLongitude, '
        'startLatitude: $startLatitude, '
        'endLongitude: $endLongitude, '
        'endLatitude: $endLatitude, '
        'currentInterval: $currentInterval, '
        'intervalsWithoutNewSpecies: $intervalsWithoutNewSpecies, '
        'currentIntervalSpeciesCount: $currentIntervalSpeciesCount, '
        'localityName: $localityName, '
        'totalObservers: $totalObservers, '
        'notes: $notes, '
        'isDiscarded: $isDiscarded }';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.index,
      'duration': duration,
      'maxSpecies': maxSpecies,
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'startLongitude': startLongitude,
      'startLatitude': startLatitude,
      'endLongitude': endLongitude,
      'endLatitude': endLatitude,
      'localityName': localityName,
      'totalObservers': totalObservers,
      'notes': notes,
      'isDiscarded': isDiscarded,
      'currentInterval': currentInterval,
      'intervalsWithoutNewSpecies': intervalsWithoutNewSpecies,
      'currentIntervalSpeciesCount': currentIntervalSpeciesCount,
      'speciesList': speciesList.map((species) => species.toJson()).toList(),
      'vegetationList': vegetationList.map((vegetation) => vegetation.toJson()).toList(),
      'weatherList': weatherList.map((weather) => weather.toJson()).toList(),
    };
  }

  factory Inventory.fromJson(Map<String, dynamic> json) {
    return Inventory(
      id: json['id'],
      type: InventoryType.values[json['type']],
      duration: json['duration'],
      maxSpecies: json['maxSpecies'],
      startTime: json['startTime'] != null ? DateTime.parse(json['startTime']) : null,
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      startLongitude: json['startLongitude'] ?? 0,
      startLatitude: json['startLatitude'] ?? 0,
      endLongitude: json['endLongitude'] ?? 0,
      endLatitude: json['endLatitude'] ?? 0,
      localityName: json['localityName'],
      totalObservers: json['totalObservers'] ?? 1,
      notes: json['notes'],
      isDiscarded: json['isDiscarded'] ?? false,
      currentInterval: json['currentInterval'],
      intervalsWithoutNewSpecies: json['intervalsWithoutNewSpecies'],
      currentIntervalSpeciesCount: json['currentIntervalSpeciesCount'],
      speciesList: (json['speciesList'] as List).map((item) => Species.fromJson(item)).toList(),
      vegetationList: (json['vegetationList'] as List).map((item) => Vegetation.fromJson(item)).toList(),
      weatherList: (json['weatherList'] as List).map((item) => Weather.fromJson(item)).toList(),
    );
  }

  // Update elapsed time values
  void updateElapsedTime(double newElapsedTime) {
    elapsedTime = newElapsedTime;
    elapsedTimeNotifier.value = elapsedTime;
    elapsedTimeNotifier.notifyListeners();
    notifyListeners();
  }

  // Update current interval values
  void updateCurrentInterval(int newInterval) {
    currentInterval = newInterval;
    currentIntervalNotifier.value = currentInterval;
    currentIntervalNotifier.notifyListeners();
    notifyListeners();
  }

  // Update if inventory is finished
  void updateIsFinished(bool newIsFinished) {
    isFinished = newIsFinished;
    if (newIsFinished == false) {
      _autoFinished = false;
    }
    isFinishedNotifier.value = isFinished;
    isFinishedNotifier.notifyListeners();
    notifyListeners();
  }

  // Start the inventory timer
  Future<void> startTimer(BuildContext context, InventoryDao inventoryDao) async {
    if (kDebugMode) {
      print('startTimer called');
    }
    // If duration was not defined, do not start the timer
    if (duration == 0) {
      updateElapsedTime(0.0);
      return;
    }
    // If duration is defined and the inventory is not finished, start the timer
    if (duration > 0 && !isFinished) {
      _autoFinished = false;
      updateCurrentInterval(currentInterval);

      // Cancel any existing timer before starting a new one
      _timer?.cancel();
      _timer = null;

      _timer = Stream<void>.periodic(const Duration(seconds: 5)).listen((_) async {
        // Only process things if inventory is not paused or finished
        if (!isPaused && !isFinished) {
          if (elapsedTime == 0) {
            updateElapsedTime(0);
            // If elapsed time is zero, update it in the database
            await inventoryDao.updateInventoryElapsedTime(id, elapsedTime);
          }

          // Update the elapsed time every 5 seconds
          updateElapsedTime(elapsedTime += 5);
          await inventoryDao.updateInventoryElapsedTime(id, elapsedTime);

          // Elapsed time reach the defined duration
          if (elapsedTime >= duration * 60 && !isFinished) {
            // If inventory type is intervaled
            if (type == InventoryType.invIntervalQualitative) {
              // Increment the currentInterval counter
              currentInterval++;
              updateCurrentInterval(currentInterval);
              await inventoryDao.updateInventoryCurrentInterval(id, currentInterval);

              if (currentIntervalSpeciesCount == 0) {
                // If no new species on interval, increment counter
                intervalsWithoutNewSpecies++;
              } else {
                // If has new species on interval, reset counter
                intervalsWithoutNewSpecies = 0;
              }
              await inventoryDao.updateInventoryIntervalsWithoutSpecies(id, intervalsWithoutNewSpecies);
              intervalWithoutSpeciesNotifier.value = intervalsWithoutNewSpecies;
              intervalWithoutSpeciesNotifier.notifyListeners();
              // Every interval, reset species counter
              await inventoryDao.updateInventoryCurrentIntervalSpeciesCount(id, 0);
              currentIntervalSpeciesCount = 0;

              if (intervalsWithoutNewSpecies == 3) {
                // If 3 intervals without species is reached, finish inventory
                _autoFinished = true;
              } else {
                // Else, reset elapsed time for new interval
                updateElapsedTime(0.0);
                await inventoryDao.updateInventoryElapsedTime(id, elapsedTime);
              }
            } else {
              // If other type of timed inventory, finish inventory if duration is reached
              _autoFinished = true;
            }

            if (isAutoFinished()) {
              await stopTimer(context, inventoryDao);
              // If finished automatically, show a notification
              await showNotification(flutterLocalNotificationsPlugin);
              if (kDebugMode) {
                print('stopTimer called automatically: $elapsedTime of ${duration * 60}');
              }
            }
          }
        }
      });
    }
    notifyListeners();
  }

  // Pause the inventory timer
  Future<void> pauseTimer(InventoryDao inventoryDao) async {
    if (kDebugMode) {
      print('pauseTimer called');
    }
    _timer?.pause();
    // _timer = null;
    isPaused = true;
    elapsedTimeNotifier.value = elapsedTime;
    elapsedTimeNotifier.notifyListeners();
    notifyListeners();
    await inventoryDao.updateInventory(this);
  }

  // Resume the inventory timer
  Future<void> resumeTimer(BuildContext context, InventoryDao inventoryDao) async {
    if (kDebugMode) {
      print('resumeTimer called');
    }
    if (isPaused) {
      _timer?.resume();
      isPaused = false;
    } else {
      // If not paused, it means it was stopped.
      // We need to start it again.
      startTimer(context, inventoryDao);
    }
    elapsedTimeNotifier.value = elapsedTime.toDouble();
    elapsedTimeNotifier.notifyListeners();
    notifyListeners();
    await inventoryDao.updateInventory(this);
  }

  // Stop the timer and finish the inventory
  Future<void> stopTimer(BuildContext context, InventoryDao inventoryDao) async {
    if (kDebugMode) {
      print('stopTimer called');
    }

    _timer?.cancel();
    _timer = null;

    isFinished = true;
    isFinishedNotifier.value = isFinished;
    isPaused = false;
    elapsedTimeNotifier.value = elapsedTime;

    // Define endTime, endLatitude and endLongitude when finishing the inventory
    endTime = DateTime.now();
    Position? position = await getPosition(context);
    if (position != null) {
      endLatitude = position.latitude;
      endLongitude = position.longitude;
    }

    await inventoryDao.updateInventory(this);
    onInventoryStopped?.call(id);
    notifyListeners();
  }

  // Future<bool> _showAutoFinishConfirmationDialog(BuildContext context) async {
  //   return await showDialog<bool>(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         title: Text(S.of(context).confirmFinish),
  //         content: Text(S.of(context).confirmFinishMessage),
  //         actions: <Widget>[
  //           TextButton(
  //             child: Text(S.of(context).keepRunning),
  //             onPressed: () {
  //               Navigator.of(context).pop(false);
  //             },
  //           ),
  //           TextButton(
  //             child: Text(S.of(context).finish),
  //             onPressed: () {
  //               Navigator.of(context).pop(true);
  //             },
  //           ),
  //         ],
  //       );
  //     },
  //   ) ?? false;
  // }

  // Show notification when inventory was finished automatically
  Future<void> showNotification(
      FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'studio.cbeier.xolmis',
      'Xolmis',
      channelDescription: 'Xolmis notifications',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      ticker: 'ticker',
    );
    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
        0,
        'Inventário Encerrado',
        'O inventário $id foi encerrado automaticamente.',
        platformChannelSpecifics,
        payload: 'item x');
  }
}

