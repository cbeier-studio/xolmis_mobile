import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:xolmis/core/core_consts.dart';
import 'package:xolmis/data/daos/inventory_dao.dart';
import 'package:xolmis/data/daos/poi_dao.dart';
import 'package:xolmis/data/daos/species_dao.dart';
import 'package:xolmis/data/daos/vegetation_dao.dart';
import 'package:xolmis/data/daos/weather_dao.dart';
import 'package:xolmis/data/database/database_helper.dart';
import 'package:xolmis/data/models/inventory.dart';

class _FakeBuildContext extends Fake implements BuildContext {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    SharedPreferences.setMockInitialValues({});
  });

  group('Inventory Notifiers and State Updates', () {
    late Inventory inventory;

    setUp(() {
      inventory = Inventory(
        id: 'INV-001',
        type: InventoryType.invPointCount,
        duration: 15,
      );
    });

    test('updateElapsedTime updates elapsedTime and notifies listeners', () {
      double? notifiedValue;
      inventory.elapsedTimeNotifier.addListener(() {
        notifiedValue = inventory.elapsedTimeNotifier.value;
      });

      inventory.updateElapsedTime(120.5);

      expect(inventory.elapsedTime, equals(120.5));
      expect(notifiedValue, equals(120.5));
    });

    test('updateCurrentInterval updates currentInterval and notifies listeners', () {
      int? notifiedValue;
      inventory.currentIntervalNotifier.addListener(() {
        notifiedValue = inventory.currentIntervalNotifier.value;
      });

      inventory.updateCurrentInterval(3);

      expect(inventory.currentInterval, equals(3));
      expect(notifiedValue, equals(3));
    });

    test('updateIntervalsWithoutNewSpecies updates counter and notifies listeners', () {
      int? notifiedValue;
      inventory.intervalWithoutSpeciesNotifier.addListener(() {
        notifiedValue = inventory.intervalWithoutSpeciesNotifier.value;
      });

      inventory.updateIntervalsWithoutNewSpecies(2);

      expect(inventory.intervalsWithoutNewSpecies, equals(2));
      expect(notifiedValue, equals(2));
    });

    test('updateIsFinished updates isFinished and resets autoFinished when set to false', () {
      bool? notifiedValue;
      inventory.isFinishedNotifier.addListener(() {
        notifiedValue = inventory.isFinishedNotifier.value;
      });

      inventory.updateIsFinished(true);

      expect(inventory.isFinished, isTrue);
      expect(notifiedValue, isTrue);

      inventory.updateIsFinished(false);

      expect(inventory.isFinished, isFalse);
      expect(inventory.isAutoFinished(), isFalse);
      expect(notifiedValue, isFalse);
    });

    test('applyPersistedState synchronizes state and notifiers from source inventory', () {
      final source = Inventory(
        id: 'INV-001',
        type: InventoryType.invPointCount,
        duration: 15,
        isPaused: true,
        isFinished: false,
        elapsedTime: 300,
        currentInterval: 2,
        intervalsWithoutNewSpecies: 1,
        currentIntervalSpeciesCount: 4,
        totalPausedTimeInSeconds: 45,
        pauseStartTime: DateTime(2025, 3, 10, 10, 0, 0),
      );

      inventory.applyPersistedState(source);

      expect(inventory.isPaused, isTrue);
      expect(inventory.isFinished, isFalse);
      expect(inventory.elapsedTime, equals(300));
      expect(inventory.currentInterval, equals(2));
      expect(inventory.intervalsWithoutNewSpecies, equals(1));
      expect(inventory.currentIntervalSpeciesCount, equals(4));
      expect(inventory.totalPausedTimeInSeconds, equals(45));
      expect(inventory.pauseStartTime, equals(DateTime(2025, 3, 10, 10, 0, 0)));
      expect(inventory.elapsedTimeNotifier.value, equals(300));
      expect(inventory.currentIntervalNotifier.value, equals(2));
      expect(inventory.intervalWithoutSpeciesNotifier.value, equals(1));
      expect(inventory.isFinishedNotifier.value, isFalse);
    });
  });

  group('Inventory Timer Pause, Resume and Stop Lifecycle with Persistence', () {
    late DatabaseHelper databaseHelper;
    late InventoryDao inventoryDao;
    late Inventory inventory;
    late BuildContext fakeContext;

    setUp(() async {
      fakeContext = _FakeBuildContext();
      databaseHelper = DatabaseHelper();
      await databaseHelper.initDatabase();

      final poiDao = PoiDao(databaseHelper);
      final speciesDao = SpeciesDao(databaseHelper, poiDao);
      final vegetationDao = VegetationDao(databaseHelper);
      final weatherDao = WeatherDao(databaseHelper);
      inventoryDao = InventoryDao(databaseHelper, speciesDao, vegetationDao, weatherDao);

      inventory = Inventory(
        id: 'INV-TIMER-1',
        type: InventoryType.invPointCount,
        duration: 20,
        startTime: DateTime.now().subtract(const Duration(minutes: 5)),
        isPaused: false,
        isFinished: false,
      );

      await inventoryDao.insertInventory(inventory);
    });

    tearDown(() {
      inventory.cancelTimer();
    });

    tearDownAll(() async {
      await databaseHelper.closeDatabase();
    });

    test('pauseTimer sets isPaused to true and records pauseStartTime in DB', () async {
      await inventory.pauseTimer(inventoryDao);

      expect(inventory.isPaused, isTrue);
      expect(inventory.pauseStartTime, isNotNull);

      final persisted = await inventoryDao.getInventoryById('INV-TIMER-1');
      expect(persisted, isNotNull);
      expect(persisted!.isPaused, isTrue);
      expect(persisted.pauseStartTime, isNotNull);
    });

    test('calling pauseTimer again when already paused is ignored', () async {
      await inventory.pauseTimer(inventoryDao);
      final initialPauseStart = inventory.pauseStartTime;

      await Future.delayed(const Duration(milliseconds: 50));
      await inventory.pauseTimer(inventoryDao);

      expect(inventory.pauseStartTime, equals(initialPauseStart));
    });

    test('resumeTimer accumulates paused time and clears pauseStartTime', () async {
      await inventory.startTimer(fakeContext, inventoryDao);
      await inventory.pauseTimer(inventoryDao);

      final pauseStart = DateTime.now().subtract(const Duration(seconds: 10));
      inventory.pauseStartTime = pauseStart;

      await inventory.resumeTimer(fakeContext, inventoryDao);
      inventory.cancelTimer();

      expect(inventory.isPaused, isFalse);
      expect(inventory.pauseStartTime, isNull);
      expect(inventory.totalPausedTimeInSeconds, greaterThanOrEqualTo(9.5));

      final persisted = await inventoryDao.getInventoryById('INV-TIMER-1');
      expect(persisted, isNotNull);
      expect(persisted!.isPaused, isFalse);
      expect(persisted.pauseStartTime, isNull);
      expect(persisted.totalPausedTimeInSeconds, greaterThanOrEqualTo(9.5));
    });

    test('calling resumeTimer when not paused is ignored', () async {
      inventory.isPaused = false;

      await inventory.resumeTimer(fakeContext, inventoryDao);
      inventory.cancelTimer();

      expect(inventory.isPaused, isFalse);
      expect(inventory.totalPausedTimeInSeconds, equals(0));
    });

    test('stopTimer marks inventory as finished and records endTime in DB', () async {
      await inventory.stopTimer(null, inventoryDao);

      expect(inventory.isFinished, isTrue);
      expect(inventory.isPaused, isFalse);
      expect(inventory.endTime, isNotNull);

      final persisted = await inventoryDao.getInventoryById('INV-TIMER-1');
      expect(persisted, isNotNull);
      expect(persisted!.isFinished, isTrue);
      expect(persisted.endTime, isNotNull);
    });

    test('calling stopTimer when already finished is ignored', () async {
      await inventory.stopTimer(null, inventoryDao);
      final initialEndTime = inventory.endTime;

      await Future.delayed(const Duration(milliseconds: 20));
      await inventory.stopTimer(null, inventoryDao);

      expect(inventory.endTime, equals(initialEndTime));
    });
  });
}
