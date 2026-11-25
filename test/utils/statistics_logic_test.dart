import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xolmis/core/core_consts.dart';
import 'package:xolmis/data/models/inventory.dart';
import 'package:xolmis/data/models/nest.dart';
import 'package:xolmis/data/models/specimen.dart';
import 'package:xolmis/generated/l10n.dart';
import 'package:xolmis/utils/statistics_logic.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await S.delegate.load(const Locale('en'));
  });

  group('Species Accumulation & Within Sample Calculations', () {
    test('prepareAccumulatedSpeciesData starts with FlSpot(0,0) and accumulates distinct species', () {
      final inventories = [
        Inventory(
          id: 'inv-1',
          type: InventoryType.invCasual,
          duration: 10,
          speciesList: [
            Species(inventoryId: 'inv-1', name: 'Species A', count: 1, isOutOfInventory: false),
            Species(inventoryId: 'inv-1', name: 'Species B', count: 2, isOutOfInventory: false),
          ],
        ),
        Inventory(
          id: 'inv-2',
          type: InventoryType.invCasual,
          duration: 10,
          speciesList: [
            Species(inventoryId: 'inv-2', name: 'Species B', count: 1, isOutOfInventory: false),
            Species(inventoryId: 'inv-2', name: 'Species C', count: 3, isOutOfInventory: false),
          ],
        ),
      ];

      final spots = prepareAccumulatedSpeciesData(inventories);

      expect(spots, hasLength(3));
      expect(spots[0], equals(const FlSpot(0, 0)));
      expect(spots[1], equals(const FlSpot(1, 2)));
      expect(spots[2], equals(const FlSpot(2, 3)));
    });

    test('prepareAccumulatedSpeciesWithinSample excludes out-of-sample species', () {
      final inventories = [
        Inventory(
          id: 'inv-1',
          type: InventoryType.invCasual,
          duration: 10,
          speciesList: [
            Species(inventoryId: 'inv-1', name: 'Species A', isOutOfInventory: false),
            Species(inventoryId: 'inv-1', name: 'Species Out', isOutOfInventory: true),
          ],
        ),
        Inventory(
          id: 'inv-2',
          type: InventoryType.invCasual,
          duration: 10,
          speciesList: [
            Species(inventoryId: 'inv-2', name: 'Species B', isOutOfInventory: false),
            Species(inventoryId: 'inv-2', name: 'Species C', isOutOfInventory: false),
          ],
        ),
      ];

      final spots = prepareAccumulatedSpeciesWithinSample(inventories);

      expect(spots, hasLength(3));
      expect(spots[0], equals(const FlSpot(0, 0)));
      expect(spots[1], equals(const FlSpot(1, 1)));
      expect(spots[2], equals(const FlSpot(2, 3)));
    });
  });

  group('Biodiversity Diversity Metrics (Shannon, Simpson, Pielou, Hill, Chao1)', () {
    test('computeDiversityMetrics returns correct values for single species', () {
      final List<Species> speciesList = [
        Species(inventoryId: 'inv-1', name: 'Species A', count: 5, isOutOfInventory: false),
      ];

      final metrics = computeDiversityMetrics('Single Species', speciesList);

      expect(metrics.richness, equals(1));
      expect(metrics.totalIndividuals, equals(5));
      expect(metrics.shannonWiener, equals(0.0));
      expect(metrics.pielouEvenness, equals(1.0));
      expect(metrics.simpsonDiversity, equals(0.0));
      expect(metrics.hillQ0, equals(1.0));
      expect(metrics.chao1, equals(1.0));
    });

    test('computeDiversityMetrics calculates Shannon and Pielou for equal abundances', () {
      final List<Species> speciesList = [
        Species(inventoryId: 'inv-1', name: 'Species A', count: 10, isOutOfInventory: false),
        Species(inventoryId: 'inv-1', name: 'Species B', count: 10, isOutOfInventory: false),
      ];

      final metrics = computeDiversityMetrics('Equal Abundance', speciesList);

      expect(metrics.richness, equals(2));
      expect(metrics.totalIndividuals, equals(20));
      expect(metrics.shannonWiener, closeTo(log(2), 0.0001));
      expect(metrics.pielouEvenness, closeTo(1.0, 0.0001));
      expect(metrics.simpsonDiversity, closeTo(0.5, 0.0001));
      expect(metrics.hillQ0, equals(2.0));
    });

    test('computeDiversityMetrics calculates Chao1 estimator with singletons and doubletons', () {
      final List<Species> speciesList = [
        Species(inventoryId: 'inv-1', name: 'Singleton A', count: 1, isOutOfInventory: false),
        Species(inventoryId: 'inv-1', name: 'Singleton B', count: 1, isOutOfInventory: false),
        Species(inventoryId: 'inv-1', name: 'Doubleton C', count: 2, isOutOfInventory: false),
      ];

      final metrics = computeDiversityMetrics('Chao1 Test', speciesList);

      // S = 3, a1 = 2 (Singletons A and B), a2 = 1 (Doubleton C)
      // Chao1 = S + (a1^2) / (2 * a2) = 3 + (2^2) / (2 * 1) = 3 + 2 = 5.0
      expect(metrics.richness, equals(3));
      expect(metrics.chao1, equals(5.0));
    });
  });

  group('Mao Tau Analytical Rarefaction Curve', () {
    test('prepareRarefactionCurveSpots handles empty inventories', () {
      final result = prepareRarefactionCurveSpots([]);

      expect(result.sampled, equals([const FlSpot(0, 0)]));
      expect(result.expected, equals([const FlSpot(0, 0)]));
    });

    test('prepareRarefactionCurveSpots generates sampled and expected curve spots', () {
      final inventories = [
        Inventory(
          id: 'inv-1',
          type: InventoryType.invCasual,
          duration: 10,
          speciesList: [
            Species(inventoryId: 'inv-1', name: 'Species A', isOutOfInventory: false),
            Species(inventoryId: 'inv-1', name: 'Species B', isOutOfInventory: false),
          ],
        ),
        Inventory(
          id: 'inv-2',
          type: InventoryType.invCasual,
          duration: 10,
          speciesList: [
            Species(inventoryId: 'inv-2', name: 'Species B', isOutOfInventory: false),
            Species(inventoryId: 'inv-2', name: 'Species C', isOutOfInventory: false),
          ],
        ),
      ];

      final result = prepareRarefactionCurveSpots(inventories);

      expect(result.sampled, hasLength(3));
      expect(result.expected, hasLength(3));

      expect(result.sampled[0], equals(const FlSpot(0, 0)));
      expect(result.sampled[1], equals(const FlSpot(1, 2)));
      expect(result.sampled[2], equals(const FlSpot(2, 3)));

      expect(result.expected[0], equals(const FlSpot(0, 0)));
      expect(result.expected[2].y, closeTo(3.0, 0.001));
    });
  });

  group('Summary & Helper Calculations', () {
    test('getNestFateCounts tallies nest fates', () {
      final nests = [
        Nest(nestFate: NestFateType.fatSuccess),
        Nest(nestFate: NestFateType.fatSuccess),
        Nest(nestFate: NestFateType.fatLost),
      ];

      final counts = getNestFateCounts(nests);
      final l10n = lookupS(const Locale('en'));

      expect(counts[l10n.nestFateSuccess], equals(2));
      expect(counts[l10n.nestFateLost], equals(1));
    });

    test('getSpecimenTypeCountsFromList counts specimen categories', () {
      final specimens = [
        Specimen(type: SpecimenType.spcFeathers),
        Specimen(type: SpecimenType.spcFeathers),
        Specimen(type: SpecimenType.spcBlood),
      ];

      final counts = getSpecimenTypeCountsFromList(specimens);

      expect(counts[SpecimenType.spcFeathers], equals(2));
      expect(counts[SpecimenType.spcBlood], equals(1));
    });

    test('getSpecimensBySpecies counts specimens grouped by species name', () {
      final specimens = [
        Specimen(speciesName: 'Turdus rufiventris'),
        Specimen(speciesName: 'Turdus rufiventris'),
        Specimen(speciesName: 'Xolmis irupero'),
      ];

      final list = getSpecimensBySpecies(specimens);

      expect(list.first.key, equals('Turdus rufiventris'));
      expect(list.first.value, equals(2));
      expect(list.last.key, equals('Xolmis irupero'));
      expect(list.last.value, equals(1));
    });

    test('getSpeciesRichnessPerMonth returns 12 months with richness counts', () {
      final inventories = [
        Inventory(
          id: 'inv-1',
          type: InventoryType.invCasual,
          duration: 10,
          startTime: DateTime(2025, 3, 15),
          speciesList: [
            Species(inventoryId: 'inv-1', name: 'Species A', isOutOfInventory: false),
            Species(inventoryId: 'inv-1', name: 'Species B', isOutOfInventory: false),
          ],
        ),
      ];

      final richnessMap = getSpeciesRichnessPerMonth(inventories);

      expect(richnessMap.keys, hasLength(12));
      expect(richnessMap[3], equals(2));
      expect(richnessMap[1], equals(0));
    });
  });
}
