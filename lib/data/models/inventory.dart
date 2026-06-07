import 'dart:async';
import 'package:flutter/material.dart';

import 'package:geolocator/geolocator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../core/core_consts.dart';
import '../../utils/utils.dart';

import '../daos/inventory_dao.dart';

import '../../main.dart';

/// Represents a point of interest linked to a species record.
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

  /// Creates a [Poi] instance from a SQLite row [map].
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

  /// Returns a copy of this [Poi] with the specified fields replaced.
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

  /// Converts this [Poi] to a SQLite-compatible map, using [speciesId] as the
  /// foreign key value.
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

  /// Converts this [Poi] to a JSON-compatible map for export.
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

  /// Creates a [Poi] instance from a JSON map.
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

/// Represents a species observation recorded inside an inventory.
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

  /// Creates a [Species] instance from a SQLite row [map], associating the
  /// given [pois] list.
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

  /// Returns a copy of this [Species] with the specified fields replaced.
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

  /// Converts this [Species] to a SQLite-compatible map, using [inventoryId]
  /// as the foreign key value.
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

  /// Converts this [Species] to a JSON-compatible map for export, including
  /// the nested [pois] list.
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

  /// Creates a [Species] instance from a JSON map, including nested [Poi]s.
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

/// Represents a vegetation sample collected during an inventory.
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

  /// Creates a [Vegetation] instance from a SQLite row [map].
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

  /// Returns a copy of this [Vegetation] with the specified fields replaced.
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

  /// Converts this [Vegetation] to a SQLite-compatible map, using [inventoryId]
  /// as the foreign key value.
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

  /// Converts this [Vegetation] to a JSON-compatible map for export.
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

  /// Creates a [Vegetation] instance from a JSON map.
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

/// Represents a weather sample collected during an inventory.
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

  /// Creates a [Weather] instance from a SQLite row [map].
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

  /// Returns a copy of this [Weather] with the specified fields replaced.
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

  /// Converts this [Weather] to a SQLite-compatible map, using [inventoryId]
  /// as the foreign key value.
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

  /// Converts this [Weather] to a JSON-compatible map for export.
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

  /// Creates a [Weather] instance from a JSON map.
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

/// Represents an inventory together with its timing state and child records.
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
  String? observer;
  String? notes;
  bool isDiscarded;
  List<Species> speciesList;
  int speciesCount = 0; // Cached count of all species records
  int speciesWithinCount = 0; // Cached count of species inside sample
  int speciesOutOfInventoryCount = 0; // Cached count of species outside sample
  List<Vegetation> vegetationList;
  List<Weather> weatherList;
  StreamSubscription<void>? _timer;
  final ValueNotifier<double> _elapsedTimeNotifier = ValueNotifier<double>(0);
  /// Emits the current elapsed time for listeners interested in timer updates.
  ValueNotifier<double> get elapsedTimeNotifier => _elapsedTimeNotifier;
  final ValueNotifier<bool> _isFinishedNotifier = ValueNotifier<bool>(false);

  /// Emits whether the inventory is currently finished.
  ValueNotifier<bool> get isFinishedNotifier => _isFinishedNotifier;
  bool _autoFinished = false;

  /// Returns whether the inventory was finished automatically by a rule.
  bool isAutoFinished() => _autoFinished;
  int currentInterval = 1;
  final ValueNotifier<int> _currentIntervalNotifier = ValueNotifier<int>(1);

  /// Emits the currently active interval number.
  ValueNotifier<int> get currentIntervalNotifier => _currentIntervalNotifier;
  int intervalsWithoutNewSpecies = 0;
  final ValueNotifier<int> _intervalWithoutSpeciesNotifier = ValueNotifier<int>(0);

  /// Emits the number of consecutive intervals without new species.
  ValueNotifier<int> get intervalWithoutSpeciesNotifier => _intervalWithoutSpeciesNotifier;
  int currentIntervalSpeciesCount = 0;
  double totalPausedTimeInSeconds = 0;
  DateTime? pauseStartTime;

  /// Creates an inventory model with optional preloaded child collections.
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
    this.observer,
    this.notes,
    this.isDiscarded = false,
    this.speciesList = const [],
    this.speciesCount = 0,
    this.speciesWithinCount = 0,
    this.speciesOutOfInventoryCount = 0,
    this.vegetationList = const [],
    this.weatherList = const [],
    this.currentInterval = 1,
    this.intervalsWithoutNewSpecies = 0,
    this.currentIntervalSpeciesCount = 0,
    this.totalPausedTimeInSeconds = 0,
    this.pauseStartTime,
  }) {
    if (speciesList.isNotEmpty && speciesCount == 0) {
      speciesCount = speciesList.length;
      speciesOutOfInventoryCount =
          speciesList.where((s) => s.isOutOfInventory).length;
      speciesWithinCount = speciesCount - speciesOutOfInventoryCount;
    }
    if (duration == 0) {
      elapsedTime = 0;
    }
  }

  /// Creates an [Inventory] from a SQLite row plus already loaded child lists.
  Inventory.fromMap(Map<String, dynamic> map, List<Species> speciesList,
      List<Vegetation> vegetationList, List<Weather> weatherList,
      {int speciesCount = 0,
      int speciesWithinCount = 0,
      int speciesOutOfInventoryCount = 0})
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
        observer = map['observer'],
        notes = map['notes'],
        isDiscarded = map['isDiscarded'] == 1,
        currentInterval = map['currentInterval'] ?? 1,
        intervalsWithoutNewSpecies = map['intervalsWithoutNewSpecies'] ?? 0,
        currentIntervalSpeciesCount = map['currentIntervalSpeciesCount'] ?? 0,
        totalPausedTimeInSeconds = map['totalPausedTimeInSeconds'] ?? 0,
        pauseStartTime = map['pauseStartTime'] != null
            ? DateTime.parse(map['pauseStartTime'])
            : null,
        speciesList = speciesList,
        speciesCount = speciesCount,
        speciesWithinCount = speciesWithinCount,
        speciesOutOfInventoryCount = speciesOutOfInventoryCount,
        vegetationList = vegetationList,
        weatherList = weatherList {
    if (this.speciesCount == 0 && speciesList.isNotEmpty) {
      this.speciesCount = speciesList.length;
    }
    if (this.speciesOutOfInventoryCount == 0 && speciesList.isNotEmpty) {
      this.speciesOutOfInventoryCount =
          speciesList.where((s) => s.isOutOfInventory).length;
    }
    if (this.speciesWithinCount == 0 && this.speciesCount > 0) {
      this.speciesWithinCount = this.speciesCount - this.speciesOutOfInventoryCount;
    }
  }

  /// Returns a copy of this inventory with the provided fields replaced.
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
    double? totalPausedTimeInSeconds,
    DateTime? pauseStartTime,
    String? localityName,
    int? totalObservers,
    String? observer,
    String? notes,
    bool? isDiscarded,
    List<Species>? speciesList,
    int? speciesCount,
    int? speciesWithinCount,
    int? speciesOutOfInventoryCount,
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
      totalPausedTimeInSeconds: totalPausedTimeInSeconds ?? this.totalPausedTimeInSeconds,
      pauseStartTime: pauseStartTime ?? this.pauseStartTime,
      localityName: localityName ?? this.localityName,
      totalObservers: totalObservers ?? this.totalObservers,
      observer: observer ?? this.observer,
      notes: notes ?? this.notes,
      isDiscarded: isDiscarded ?? this.isDiscarded,
      speciesList: speciesList ?? this.speciesList,
      speciesCount: speciesCount ?? this.speciesCount,
      speciesWithinCount: speciesWithinCount ?? this.speciesWithinCount,
      speciesOutOfInventoryCount:
          speciesOutOfInventoryCount ?? this.speciesOutOfInventoryCount,
      vegetationList: vegetationList ?? this.vegetationList,
      weatherList: weatherList ?? this.weatherList,
    );
  }

  /// Converts this [Inventory] to a SQLite-compatible map. Sub-lists
  /// ([speciesList], [vegetationList], [weatherList]) are NOT included; they
  /// are persisted separately by their own DAOs.
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
      'totalPausedTimeInSeconds': totalPausedTimeInSeconds,
      'pauseStartTime': pauseStartTime?.toIso8601String(),
      'localityName': localityName,
      'totalObservers': totalObservers,
      'observer': observer,
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
        'totalPausedTimeInSeconds: $totalPausedTimeInSeconds, '
        'pauseStartTime: $pauseStartTime, '
        'localityName: $localityName, '
        'totalObservers: $totalObservers, '
        'observer: $observer, '
        'notes: $notes, '
        'isDiscarded: $isDiscarded }';
  }

  /// Converts this [Inventory] to a JSON-compatible map for export, including
  /// the nested [speciesList], [vegetationList], and [weatherList].
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
      'observer': observer,
      'notes': notes,
      'isDiscarded': isDiscarded,
      'currentInterval': currentInterval,
      'intervalsWithoutNewSpecies': intervalsWithoutNewSpecies,
      'currentIntervalSpeciesCount': currentIntervalSpeciesCount,
      'totalPausedTimeInSeconds': totalPausedTimeInSeconds,
      'pauseStartTime': pauseStartTime?.toIso8601String(),
      'speciesList': speciesList.map((species) => species.toJson()).toList(),
      'vegetationList': vegetationList.map((vegetation) => vegetation.toJson()).toList(),
      'weatherList': weatherList.map((weather) => weather.toJson()).toList(),
    };
  }

  /// Creates an [Inventory] instance from a JSON map, including nested
  /// [Species], [Vegetation], and [Weather] lists.
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
      observer: json['observer'],
      notes: json['notes'],
      isDiscarded: json['isDiscarded'] ?? false,
      currentInterval: json['currentInterval'],
      intervalsWithoutNewSpecies: json['intervalsWithoutNewSpecies'],
      currentIntervalSpeciesCount: json['currentIntervalSpeciesCount'],
      totalPausedTimeInSeconds: json['totalPausedTimeInSeconds'],
      pauseStartTime: json['pauseStartTime'] != null ? DateTime.parse(json['pauseStartTime']) : null,
      speciesList: (json['speciesList'] as List).map((item) => Species.fromJson(item)).toList(),
      vegetationList: (json['vegetationList'] as List).map((item) => Vegetation.fromJson(item)).toList(),
      weatherList: (json['weatherList'] as List).map((item) => Weather.fromJson(item)).toList(),
    );
  }

  /// Updates [elapsedTime] and notifies all listeners and [ValueNotifier]s.
  void updateElapsedTime(double newElapsedTime) {
    elapsedTime = newElapsedTime;
    elapsedTimeNotifier.value = elapsedTime;
    elapsedTimeNotifier.notifyListeners();
    notifyListeners();
  }

  /// Updates [currentInterval] and notifies all listeners and [ValueNotifier]s.
  void updateCurrentInterval(int newInterval) {
    currentInterval = newInterval;
    currentIntervalNotifier.value = currentInterval;
    currentIntervalNotifier.notifyListeners();
    notifyListeners();
  }

  /// Updates [intervalsWithoutNewSpecies] and notifies all listeners and
  /// [ValueNotifier]s.
  void updateIntervalsWithoutNewSpecies(int newInterval) {
    intervalsWithoutNewSpecies = newInterval;
    intervalWithoutSpeciesNotifier.value = intervalsWithoutNewSpecies;
    intervalWithoutSpeciesNotifier.notifyListeners();
    notifyListeners();
  }

  /// Updates [isFinished] and notifies all listeners and [ValueNotifier]s.
  ///
  /// When [newIsFinished] is `false`, also resets the internal auto-finish flag.
  void updateIsFinished(bool newIsFinished) {
    isFinished = newIsFinished;
    if (newIsFinished == false) {
      _autoFinished = false;
    }
    isFinishedNotifier.value = isFinished;
    isFinishedNotifier.notifyListeners();
    notifyListeners();
  }

  /// Applies persisted values from [source] into this in-memory instance.
  ///
  /// This keeps the same object identity (and therefore any active runtime
  /// timer subscription) while refreshing DB-backed fields.
  ///
  /// When [includeCollections] is `true`, nested lists ([speciesList],
  /// [vegetationList], [weatherList]) are also replaced with [source] values.
  void applyPersistedState(Inventory source, {bool includeCollections = false}) {
    duration = source.duration;
    maxSpecies = source.maxSpecies;
    isPaused = source.isPaused;
    isFinished = source.isFinished;
    elapsedTime = source.elapsedTime;
    startTime = source.startTime;
    endTime = source.endTime;
    startLongitude = source.startLongitude;
    startLatitude = source.startLatitude;
    endLongitude = source.endLongitude;
    endLatitude = source.endLatitude;
    localityName = source.localityName;
    totalObservers = source.totalObservers;
    observer = source.observer;
    notes = source.notes;
    isDiscarded = source.isDiscarded;
    currentInterval = source.currentInterval;
    intervalsWithoutNewSpecies = source.intervalsWithoutNewSpecies;
    currentIntervalSpeciesCount = source.currentIntervalSpeciesCount;
    totalPausedTimeInSeconds = source.totalPausedTimeInSeconds;
    pauseStartTime = source.pauseStartTime;
    speciesCount = source.speciesCount;
    speciesWithinCount = source.speciesWithinCount;
    speciesOutOfInventoryCount = source.speciesOutOfInventoryCount;

    if (includeCollections) {
      speciesList = source.speciesList;
      vegetationList = source.vegetationList;
      weatherList = source.weatherList;
    }

    _elapsedTimeNotifier.value = elapsedTime;
    _currentIntervalNotifier.value = currentInterval;
    _intervalWithoutSpeciesNotifier.value = intervalsWithoutNewSpecies;
    _isFinishedNotifier.value = isFinished;
  }

  /// Starts the inventory countdown timer, ticking every 5 seconds.
  ///
  /// Does nothing if [duration] is `0`. On each tick, the elapsed time is
  /// incremented and persisted via [inventoryDao]. For
  /// [InventoryType.invIntervalQualitative] inventories, interval transitions
  /// and the three-intervals-without-new-species auto-finish rule are also
  /// evaluated. For other timed types the inventory finishes as soon as
  /// `elapsedTime >= duration * 60`. When the inventory finishes automatically,
  /// [stopTimer] is called and a local notification is shown.
  Future<void> startTimer(BuildContext context, InventoryDao inventoryDao) async {
    debugPrint('START_TIMER_CALLED for inventory $id. Current state: isFinished=$isFinished, isPaused=$isPaused, duration=$duration');
    // If duration was not defined, do not start the timer
    if (duration == 0) {
      debugPrint('...START_TIMER_ABORTED for $id: duration is 0.');
      updateElapsedTime(0.0);
      return;
    }
    // If duration is defined and the inventory is not finished, start the timer
    if (duration > 0 && !isFinished) {
      _autoFinished = false;
      updateCurrentInterval(currentInterval);

      // Cancel any existing timer before starting a new one
      debugPrint('...Cancelling existing timer for $id before starting new one.');
      _timer?.cancel();
      _timer = null;

      debugPrint('...SUCCESS: Starting new timer for $id with 5-second interval.');
      _timer = Stream<void>.periodic(const Duration(seconds: 5)).listen((_) async {
        // Only process things if inventory is not paused or finished
        if (!isPaused && !isFinished) {
          if (pauseStartTime != null) {
            // 1. Calculate the pause duration that just finished.
            final pauseDuration = DateTime.now().difference(pauseStartTime!).inSeconds.toDouble();
            // 2. Accumulate this duration in the total paused time.
            totalPausedTimeInSeconds += pauseDuration;
            // 3. Clear the `pauseStartTime`, because the pause finished.
            pauseStartTime = null;
          }

          if (elapsedTime == 0) {
            updateElapsedTime(0);
            // If elapsed time is zero, update it in the database
            await inventoryDao.updateInventoryElapsedTime(id, elapsedTime);
          }

          // Update the elapsed time every 5 seconds
          final oldElapsedTime = elapsedTime;
          updateElapsedTime(elapsedTime += 5);
          debugPrint('TIMER_TICK for $id: elapsedTime changed from $oldElapsedTime to $elapsedTime.');
          await inventoryDao.updateInventoryElapsedTime(id, elapsedTime);

          // Elapsed time reach the defined duration
          if (elapsedTime >= duration * 60 && !isFinished) {
            debugPrint('TIMER_TICK for $id: Interval duration reached! (elapsedTime: $elapsedTime >= ${duration * 60})');

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
                debugPrint('!!! AUTO-FINISH condition met for $id: intervalsWithoutNewSpecies is 3.');
              } else {
                // Else, reset elapsed time for new interval
                updateElapsedTime(0.0);
                await inventoryDao.updateInventoryElapsedTime(id, elapsedTime);
              }
            } else {
              // If other type of timed inventory, finish inventory if duration is reached
              _autoFinished = true;
              debugPrint('!!! AUTO-FINISH condition met for $id: Timed inventory duration reached.');
            }

            if (isAutoFinished() && !isFinished) {
              debugPrint('>>> Calling stopTimer() automatically for $id...');
              await stopTimer(context, inventoryDao);
              // If finished automatically, show a notification
              await showNotification(flutterLocalNotificationsPlugin);

              debugPrint('stopTimer called automatically: $elapsedTime of ${duration * 60}');
            }
          }
        }
      });
    }
    notifyListeners();
  }

  /// Pauses the running timer, recording the pause start time and persisting
  /// the inventory state via [inventoryDao].
  ///
  /// Does nothing if the inventory is already paused.
  Future<void> pauseTimer(InventoryDao inventoryDao) async {
    if (isPaused) {
      debugPrint('PAUSE IGNORED for $id: Already paused.');
      return;
    }
    debugPrint('PAUSING inventory $id...');
    _timer?.pause();
    isPaused = true;
    pauseStartTime = DateTime.now();
    elapsedTimeNotifier.value = elapsedTime;
    debugPrint('...PAUSED inventory $id at $pauseStartTime. Current elapsedTime: $elapsedTime');
    elapsedTimeNotifier.notifyListeners();
    notifyListeners();
    await inventoryDao.updateInventory(this);
  }

  /// Resumes a paused timer, accumulating the paused duration into
  /// [totalPausedTimeInSeconds] and persisting the inventory state via
  /// [inventoryDao].
  ///
  /// Restarts the timer from scratch (via [startTimer]) if no paused timer
  /// subscription exists. Does nothing if the inventory is not currently paused.
  Future<void> resumeTimer(BuildContext context, InventoryDao inventoryDao) async {
    if (!isPaused) {
      debugPrint('RESUME IGNORED for $id: Not currently paused.');
      return;
    }
    debugPrint('RESUMING inventory $id...');

    if (isPaused) {
      isPaused = false;
      if (_timer?.isPaused == true) {
        if (pauseStartTime != null) {
          // 1. Calculate the pause duration that just finished.
          final pauseDuration = DateTime.now().difference(pauseStartTime!).inSeconds.toDouble();
          debugPrint('...Calculated pause duration for $id: $pauseDuration seconds.');
          // 2. Accumulate this duration in the total paused time.
          totalPausedTimeInSeconds += pauseDuration;
          debugPrint('...New totalPausedTimeInSeconds for $id: $totalPausedTimeInSeconds seconds.');
          // 3. Clear the `pauseStartTime`, because the pause finished.
          pauseStartTime = null;
        }
        // If the timer was paused, resume it
        debugPrint('...Resuming existing timer for $id.');
        _timer?.resume();
      } else {
        // If not paused, start it again
        debugPrint('...No existing timer found for $id, calling startTimer() to recreate it.');
        startTimer(context, inventoryDao);
      }
    } else {
      // If not paused, it means it was stopped.
      // We need to start it again.
      debugPrint('...No existing timer found for $id, calling startTimer() to recreate it.');
      startTimer(context, inventoryDao);
    }
    elapsedTimeNotifier.value = elapsedTime.toDouble();
    elapsedTimeNotifier.notifyListeners();
    notifyListeners();
    await inventoryDao.updateInventory(this);
  }

  /// Stops the timer, marks the inventory as finished, records [endTime] and
  /// end coordinates, and persists the final state via [inventoryDao].
  ///
  /// Does nothing if the inventory is already finished.
  Future<void> stopTimer(BuildContext context, InventoryDao inventoryDao) async {
    if (isFinished) {
      debugPrint('STOP_TIMER_IGNORED for $id: Already finished.');
      return;
    }
    debugPrint('STOPPING_TIMER for inventory $id...');

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

  /// Shows a local push notification informing the user that this inventory
  /// was finished automatically.
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
        id: 0,
        title: 'Inventário Encerrado',
        body: 'O inventário $id foi encerrado automaticamente.',
        notificationDetails: platformChannelSpecifics,
        payload: 'item x');
  }
}
