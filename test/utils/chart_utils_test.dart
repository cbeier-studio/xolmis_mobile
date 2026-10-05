import 'package:flutter_test/flutter_test.dart';
import 'package:xolmis/core/core_consts.dart';
import 'package:xolmis/data/models/inventory.dart';
import 'package:xolmis/utils/chart_utils.dart';

void main() {
  group('chart_utils.dart - prepareSpeciesAccumulationData', () {
    final startTime = DateTime(2026, 3, 30, 8, 0, 0);

    test('counts only the first record of each species for invTransectDetection', () {
      final inventory = Inventory(
        id: 'inv-det-1',
        type: InventoryType.invTransectDetection,
        startTime: startTime,
        duration: 10, // 10 minutes (600s)
        isFinished: true,
        endTime: startTime.add(const Duration(minutes: 10)),
        speciesList: [
          Species(
            inventoryId: 'inv-det-1',
            name: 'Turdus rufiventris',
            isOutOfInventory: false,
            sampleTime: startTime.add(const Duration(seconds: 20)),
          ),
          Species(
            inventoryId: 'inv-det-1',
            name: 'Pitangus sulphuratus',
            isOutOfInventory: false,
            sampleTime: startTime.add(const Duration(seconds: 50)),
          ),
          // Re-detection of Turdus rufiventris much later in the inventory
          Species(
            inventoryId: 'inv-det-1',
            name: 'Turdus rufiventris',
            isOutOfInventory: false,
            sampleTime: startTime.add(const Duration(seconds: 400)),
          ),
        ],
      );

      final result = prepareSpeciesAccumulationData(inventory, inventory.speciesList);
      final data = result['data'] as List<SpeciesAccumulationData>;

      expect(data, isNotEmpty);
      // The final cumulative species count should be 2 distinct species
      expect(data.last.speciesCount, equals(2));

      // Check interval containing second 20 (intervalSize for 10 min duration is 60s)
      // At interval 0 (0s): count is 0
      // At interval 1 (60s): both Turdus (20s) and Pitangus (50s) first records are in interval 0 (0-59s)
      final countAtFirstInterval = data.firstWhere((d) => d.interval >= 60).speciesCount;
      expect(countAtFirstInterval, equals(2));
    });

    test('counts only the first record of each species for invPointDetection', () {
      final inventory = Inventory(
        id: 'inv-pt-1',
        type: InventoryType.invPointDetection,
        startTime: startTime,
        duration: 3, // 3 minutes (< 5 min -> intervalSize = 10s)
        isFinished: true,
        endTime: startTime.add(const Duration(minutes: 3)),
        speciesList: [
          Species(
            inventoryId: 'inv-pt-1',
            name: 'Species A',
            isOutOfInventory: false,
            sampleTime: startTime.add(const Duration(seconds: 15)),
          ),
          Species(
            inventoryId: 'inv-pt-1',
            name: 'Species A',
            isOutOfInventory: false,
            sampleTime: startTime.add(const Duration(seconds: 90)),
          ),
          Species(
            inventoryId: 'inv-pt-1',
            name: 'Species B',
            isOutOfInventory: false,
            sampleTime: startTime.add(const Duration(seconds: 45)),
          ),
        ],
      );

      final result = prepareSpeciesAccumulationData(inventory, inventory.speciesList);
      final data = result['data'] as List<SpeciesAccumulationData>;

      // Interval 0 (0s): 0
      // Interval 1 (10s): 0
      // Interval 2 (20s): 1 (Species A at 15s)
      // Interval 5 (50s): 2 (Species B at 45s)
      // Re-detection of Species A at 90s should NOT add another species
      final pointAt20s = data.firstWhere((d) => d.interval == 20);
      expect(pointAt20s.speciesCount, equals(1));

      final pointAt50s = data.firstWhere((d) => d.interval == 50);
      expect(pointAt50s.speciesCount, equals(2));

      final pointAt100s = data.firstWhere((d) => d.interval == 100);
      expect(pointAt100s.speciesCount, equals(2));
    });

    test('works as expected for non-detection inventory types', () {
      final inventory = Inventory(
        id: 'inv-casual-1',
        type: InventoryType.invCasual,
        startTime: startTime,
        duration: 5,
        isFinished: true,
        endTime: startTime.add(const Duration(minutes: 5)),
        speciesList: [
          Species(
            inventoryId: 'inv-casual-1',
            name: 'Species A',
            isOutOfInventory: false,
            sampleTime: startTime.add(const Duration(seconds: 30)),
          ),
          Species(
            inventoryId: 'inv-casual-1',
            name: 'Species B',
            isOutOfInventory: false,
            sampleTime: startTime.add(const Duration(seconds: 90)),
          ),
        ],
      );

      final result = prepareSpeciesAccumulationData(inventory, inventory.speciesList);
      final data = result['data'] as List<SpeciesAccumulationData>;

      expect(data.last.speciesCount, equals(2));
    });

    test('ignores species added too long after inventory end', () {
      final inventory = Inventory(
        id: 'inv-late-1',
        type: InventoryType.invCasual,
        startTime: startTime,
        duration: 10,
        isFinished: true,
        endTime: startTime.add(const Duration(minutes: 10)),
        speciesList: [
          Species(
            inventoryId: 'inv-late-1',
            name: 'Species On Time',
            isOutOfInventory: false,
            sampleTime: startTime.add(const Duration(minutes: 4)),
          ),
          // 3 hours after start; outside accepted post-finish window.
          Species(
            inventoryId: 'inv-late-1',
            name: 'Species Too Late',
            isOutOfInventory: false,
            sampleTime: startTime.add(const Duration(hours: 3)),
          ),
        ],
      );

      final result = prepareSpeciesAccumulationData(inventory, inventory.speciesList);
      final data = result['data'] as List<SpeciesAccumulationData>;
      final duration = result['duration'] as double;

      expect(duration, equals(600.0));
      expect(data.last.interval, equals(600));
      expect(data.last.speciesCount, equals(1));
    });

    test('keeps species added within post-finish window', () {
      final inventory = Inventory(
        id: 'inv-late-2',
        type: InventoryType.invCasual,
        startTime: startTime,
        duration: 10,
        isFinished: true,
        endTime: startTime.add(const Duration(minutes: 10)),
        speciesList: [
          Species(
            inventoryId: 'inv-late-2',
            name: 'Species On Time',
            isOutOfInventory: false,
            sampleTime: startTime.add(const Duration(minutes: 5)),
          ),
          // 15 minutes after start (5 min after end), inside accepted window.
          Species(
            inventoryId: 'inv-late-2',
            name: 'Species Slightly Late',
            isOutOfInventory: false,
            sampleTime: startTime.add(const Duration(minutes: 15)),
          ),
        ],
      );

      final result = prepareSpeciesAccumulationData(inventory, inventory.speciesList);
      final data = result['data'] as List<SpeciesAccumulationData>;

      expect(data.last.speciesCount, equals(2));
      expect(data.last.interval, equals(900));
    });
  });
}
