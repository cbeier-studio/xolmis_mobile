import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../utils/utils.dart';

import '../database/repositories/inventory_repository.dart';

import '../../main.dart';

import '../../generated/l10n.dart';


// POI class

class Poi {
  late int? id;
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'speciesId': speciesId,
      'longitude': longitude,
      'latitude': latitude,
    };
  }

  factory Poi.fromJson(Map<String, dynamic> json) {
    return Poi(
      id: json['id'],
      speciesId: json['speciesId'],
      longitude: json['longitude'],
      latitude: json['latitude'],
    );
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

// Species class

class Species {
  late int? id;
  final String inventoryId;
  final String name;
  bool isOutOfInventory;
  int count;
  String? notes;
  DateTime? sampleTime;
  List<Poi> pois;

  Species({
    this.id,
    required this.inventoryId,
    required this.name,
    required this.isOutOfInventory,
    this.count = 0,
    this.notes,
    this.sampleTime,
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
      notes: notes ?? this.notes,
      sampleTime: sampleTime ?? this.sampleTime,
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
}

Map<PrecipitationType, String> precipitationTypeFriendlyNames = {
  PrecipitationType.preNone: S.current.precipitationNone,
  PrecipitationType.preFog: S.current.precipitationFog,
  PrecipitationType.preMist: S.current.precipitationMist,
  PrecipitationType.preDrizzle: S.current.precipitationDrizzle,
  PrecipitationType.preRain: S.current.precipitationRain,
};

class Weather {
  late int? id;
  final String inventoryId;
  final DateTime? sampleTime;
  int? cloudCover;
  PrecipitationType? precipitation = PrecipitationType.preNone;
  double? temperature;
  int? windSpeed;

  Weather({
    this.id,
    required this.inventoryId,
    required this.sampleTime,
    this.cloudCover,
    this.precipitation,
    this.temperature,
    this.windSpeed,
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
    );
  }

  Weather copyWith({
      int? id,
      String? inventoryId,
      DateTime? sampleTime,
      int? cloudCover,
      PrecipitationType? precipitation,
      double? temperature,
      int? windSpeed
  }) {
    return Weather(
      id: id ?? this.id,
      inventoryId: inventoryId ?? this.inventoryId,
      sampleTime: sampleTime ?? this.sampleTime,
      cloudCover: cloudCover ?? this.cloudCover,
      precipitation: precipitation ?? this.precipitation,
      temperature: temperature ?? this.temperature,
      windSpeed: windSpeed ?? this.windSpeed,
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
    };
  }

  factory Weather.fromJson(Map<String, dynamic> json) {
    return Weather(
      inventoryId: json['inventoryId'],
      sampleTime: DateTime.parse(json['sampleTime']), 
      cloudCover: json['cloudCover'],
      precipitation: json['precipitation'],
      temperature: json['temperature'],
      windSpeed: json['windSpeed'],
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
        'windSpeed: $windSpeed }';
  }
}

// Inventory class

enum InventoryType {
  invFreeQualitative,
  invTimedQualitative,
  invIntervalQualitative,
  invMackinnonList,
  invTransectionCount,
  invPointCount,
  invBanding,
  invCasual,
}

Map<InventoryType, String> inventoryTypeFriendlyNames = {
  InventoryType.invFreeQualitative: S.current.inventoryFreeQualitative,
  InventoryType.invTimedQualitative: S.current.inventoryTimedQualitative,
  InventoryType.invIntervalQualitative: S.current.inventoryIntervalQualitative,
  InventoryType.invMackinnonList: S.current.inventoryMackinnonList,
  InventoryType.invTransectionCount: S.current.inventoryTransectionCount,
  InventoryType.invPointCount: S.current.inventoryPointCount,
  InventoryType.invBanding: S.current.inventoryBanding,
  InventoryType.invCasual: S.current.inventoryCasual,
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
        startLongitude = map['startLongitude'],
        startLatitude = map['startLatitude'],
        endLongitude = map['endLongitude'],
        endLatitude = map['endLatitude'],
        currentInterval = map['currentInterval'],
        intervalsWithoutNewSpecies = map['intervalsWithoutNewSpecies'],
        currentIntervalSpeciesCount = map['currentIntervalSpeciesCount'],
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
        'currentIntervalSpeciesCount: $currentIntervalSpeciesCount}';
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
      startLongitude: json['startLongitude'],
      startLatitude: json['startLatitude'],
      endLongitude: json['endLongitude'],
      endLatitude: json['endLatitude'],
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
  Future<void> startTimer(InventoryRepository inventoryRepository) async {
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
      _timer ??= Stream<void>.periodic(const Duration(seconds: 5)).listen((_) async {
        // Only process things if inventory is not paused or finished
        if (!isPaused && !isFinished) {
          if (elapsedTime == 0) {
            updateElapsedTime(0);
            // If elapsed time is zero, update it in the database
            await inventoryRepository.updateInventoryElapsedTime(id, elapsedTime);
          }

          // Update the elapsed time every 5 seconds
          updateElapsedTime(elapsedTime += 5);
          await inventoryRepository.updateInventoryElapsedTime(id, elapsedTime);

          // Elapsed time reach the defined duration
          if (elapsedTime >= duration * 60 && !isFinished) {
            // If inventory type is intervaled
            if (type == InventoryType.invIntervalQualitative) {
              // Increment the currentInterval counter
              currentInterval++;
              updateCurrentInterval(currentInterval);
              await inventoryRepository.updateInventoryCurrentInterval(id, currentInterval);

              if (currentIntervalSpeciesCount == 0) {
                // If no new species on interval, increment counter
                intervalsWithoutNewSpecies++;
              } else {
                // If has new species on interval, reset counter
                intervalsWithoutNewSpecies = 0;
              }
              await inventoryRepository.updateInventoryIntervalsWithoutSpecies(id, intervalsWithoutNewSpecies);
              intervalWithoutSpeciesNotifier.value = intervalsWithoutNewSpecies;
              intervalWithoutSpeciesNotifier.notifyListeners();
              // Every interval, reset species counter
              currentIntervalSpeciesCount = 0;

              if (intervalsWithoutNewSpecies == 3) {
                // If 3 intervals without species is reached, finish inventory
                _autoFinished = true;
                // if (_autoFinished) {
                //   await stopTimer(inventoryRepository);
                // } else {
                //   // Reset intervalsWithoutNewSpecies if user chooses to continue
                //   intervalsWithoutNewSpecies = 0;
                //   await inventoryRepository.updateInventoryIntervalsWithoutSpecies(id, intervalsWithoutNewSpecies);
                //   intervalWithoutSpeciesNotifier.value = intervalsWithoutNewSpecies;
                //   intervalWithoutSpeciesNotifier.notifyListeners();
                //   // Reset elapsed time for new interval
                //   updateElapsedTime(0.0);
                //   await inventoryRepository.updateInventoryElapsedTime(id, elapsedTime);
                // }
              } else {
                // Else, reset elapsed time for new interval
                updateElapsedTime(0.0);
                await inventoryRepository.updateInventoryElapsedTime(id, elapsedTime);
              }
            } else {
              // If other type of timed inventory, finish inventory if duration is reached
              _autoFinished = true;
              // if (_autoFinished) {
              //   await stopTimer(inventoryRepository);
              // } else {
              //   // Reset elapsedTime if user chooses to continue
              //   elapsedTime = 0;
              //   updateElapsedTime(elapsedTime);
              //   await inventoryRepository.updateInventoryElapsedTime(id, elapsedTime);
              // }
            }

            if (isAutoFinished()) {
              await stopTimer(inventoryRepository);
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
  Future<void> pauseTimer(InventoryRepository inventoryRepository) async {
    if (kDebugMode) {
      print('pauseTimer called');
    }
    _timer?.pause();
    // _timer = null;
    isPaused = true;
    elapsedTimeNotifier.value = elapsedTime;
    elapsedTimeNotifier.notifyListeners();
    notifyListeners();
    await inventoryRepository.updateInventory(this);
  }

  // Resume the inventory timer
  Future<void> resumeTimer(InventoryRepository inventoryRepository) async {
    if (kDebugMode) {
      print('resumeTimer called');
    }
    _timer?.resume();
    isPaused = false;
    startTimer(inventoryRepository);
    elapsedTimeNotifier.value = elapsedTime.toDouble();
    elapsedTimeNotifier.notifyListeners();
    notifyListeners();
    await inventoryRepository.updateInventory(this);
  }

  // Stop the timer and finish the inventory
  Future<void> stopTimer(InventoryRepository inventoryRepository) async {
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
    Position? position = await getPosition();
    if (position != null) {
      endLatitude = position.latitude;
      endLongitude = position.longitude;
    }

    await inventoryRepository.updateInventory(this);
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

