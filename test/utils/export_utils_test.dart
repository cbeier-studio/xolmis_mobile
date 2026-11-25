import 'dart:ui';
import 'package:csv/csv.dart';
import 'package:excel_plus/excel_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xolmis/core/core_consts.dart';
import 'package:xolmis/data/models/inventory.dart';
import 'package:xolmis/data/models/nest.dart';
import 'package:xolmis/data/models/specimen.dart';
import 'package:xolmis/utils/export_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Excel export cell value formatting', () {
    test('converts empty and whitespace values to null cell values', () {
      final rows = [
        ['Header1', 'Header2', 'Header3'],
        [null, '', '   '],
      ];

      final cellRows = convertRowsToCellValues(rows);

      expect(cellRows[1][0], isNull);
      expect(cellRows[1][1], isNull);
      expect(cellRows[1][2], isNull);
    });

    test('converts integer numbers and integer strings to IntCellValue', () {
      final rows = [
        [42, 0, -10, '100', '0', '-5'],
      ];

      final cellRows = convertRowsToCellValues(rows);

      expect(cellRows[0][0], equals(const IntCellValue(42)));
      expect(cellRows[0][1], equals(const IntCellValue(0)));
      expect(cellRows[0][2], equals(const IntCellValue(-10)));
      expect(cellRows[0][3], equals(const IntCellValue(100)));
      expect(cellRows[0][4], equals(const IntCellValue(0)));
      expect(cellRows[0][5], equals(const IntCellValue(-5)));
    });

    test('preserves strings with leading zeros as TextCellValue', () {
      final rows = [
        ['007', '01', '000'],
      ];

      final cellRows = convertRowsToCellValues(rows);

      expect(cellRows[0][0], equals(TextCellValue('007')));
      expect(cellRows[0][1], equals(TextCellValue('01')));
      expect(cellRows[0][2], equals(TextCellValue('000')));
    });

    test('preserves formatted decimal strings and non-integer strings as TextCellValue', () {
      final rows = [
        ['-23.5505', '-23,5505', 'Point count', '2025-01-15', '14:30:00'],
      ];

      final cellRows = convertRowsToCellValues(rows);

      expect(cellRows[0][0], equals(TextCellValue('-23.5505')));
      expect(cellRows[0][1], equals(TextCellValue('-23,5505')));
      expect(cellRows[0][2], equals(TextCellValue('Point count')));
      expect(cellRows[0][3], equals(TextCellValue('2025-01-15')));
      expect(cellRows[0][4], equals(TextCellValue('14:30:00')));
    });

    test('preserves double and boolean types', () {
      final rows = [
        [12.34, true, false],
      ];

      final cellRows = convertRowsToCellValues(rows);

      expect(cellRows[0][0], equals(const DoubleCellValue(12.34)));
      expect(cellRows[0][1], equals(const BoolCellValue(true)));
      expect(cellRows[0][2], equals(const BoolCellValue(false)));
    });
  });

  group('CSV and Excel column count consistency', () {
    const locale = Locale('en', 'US');

    void checkColumnCounts(List<List<dynamic>> rows) {
      expect(rows, isNotEmpty, reason: 'Rows matrix must not be empty');
      final headerColumnCount = rows[0].length;
      expect(headerColumnCount, greaterThan(0), reason: 'Header row must contain columns');

      for (var i = 1; i < rows.length; i++) {
        expect(
          rows[i].length,
          equals(headerColumnCount),
          reason: 'Data row $i length (${rows[i].length}) does not match header length ($headerColumnCount)',
        );
      }

      // Verify CSV export column count consistency
      final csvString = Csv(fieldDelimiter: ';').encode(rows);
      final decodedCsvRows = Csv(fieldDelimiter: ';', skipEmptyLines: false).decode(csvString);

      expect(decodedCsvRows.length, equals(rows.length), reason: 'Decoded CSV row count must match original row count');

      for (var i = 0; i < decodedCsvRows.length; i++) {
        expect(
          decodedCsvRows[i].length,
          equals(headerColumnCount),
          reason: 'CSV row $i column count (${decodedCsvRows[i].length}) does not match header column count ($headerColumnCount)',
        );
      }

      // Verify Excel export cell values column count consistency
      final cellRows = convertRowsToCellValues(rows);
      expect(cellRows.length, equals(rows.length), reason: 'Converted cell rows count must match original row count');

      for (var i = 0; i < cellRows.length; i++) {
        expect(
          cellRows[i].length,
          equals(headerColumnCount),
          reason: 'Excel row $i cell count (${cellRows[i].length}) does not match header cell count ($headerColumnCount)',
        );
      }
    }

    late Inventory sampleInventory;
    late Nest sampleNest;
    late Specimen sampleSpecimen;

    setUp(() {
      sampleInventory = Inventory(
        id: '101',
        type: InventoryType.invPointCount,
        transportMode: TransportMode.tmodeWalking,
        duration: 20,
        startTime: DateTime(2025, 3, 10, 8, 30, 0),
        endTime: DateTime(2025, 3, 10, 8, 50, 0),
        localityName: 'Field Site A',
        startLatitude: -23.5505,
        startLongitude: -46.6333,
        endLatitude: -23.5510,
        endLongitude: -46.6340,
        observer: 'JS; Observer',
        totalObservers: 2,
        currentInterval: 1,
        totalPausedTimeInSeconds: 60,
        notes: 'Clear sky; good visibility',
        isDiscarded: false,
        speciesList: [],
        vegetationList: [],
        weatherList: [],
      );

      sampleInventory.speciesList.add(
        Species(
          id: 1,
          inventoryId: '101',
          name: 'Xolmis irupero',
          count: 3,
          sampleTime: DateTime(2025, 3, 10, 8, 35, 0),
          isOutOfInventory: false,
          isDoubtful: false,
          distance: 15.5,
          flightHeight: 5.0,
          flightDirection: 'N',
          habitats: [SpeciesHabitat.forest],
          detectionModes: [SpeciesDetectionMode.visual],
          reproductiveStatus: SpeciesReproductiveStatus.c,
          sex: SpeciesSex.male,
          activities: [SpeciesActivity.foraging],
          notes: 'Perched on fence; text with semicolon',
          pois: [
            Poi(
              id: 501,
              speciesId: 1,
              latitude: -23.5507,
              longitude: -46.6335,
              sampleTime: DateTime(2025, 3, 10, 8, 36, 0),
              notes: 'Fence post 12',
            ),
          ],
        ),
      );

      sampleInventory.vegetationList.add(
        Vegetation(
          id: 201,
          inventoryId: '101',
          sampleTime: DateTime(2025, 3, 10, 8, 40, 0),
          latitude: -23.5506,
          longitude: -46.6334,
          herbsProportion: 40,
          herbsDistribution: DistributionType.disNone,
          herbsHeight: 1,
          shrubsProportion: 30,
          shrubsDistribution: DistributionType.disNone,
          shrubsHeight: 2,
          treesProportion: 30,
          treesDistribution: DistributionType.disNone,
          treesHeight: 8,
          notes: 'Grassland transition',
        ),
      );

      sampleInventory.weatherList.add(
        Weather(
          id: 301,
          inventoryId: '101',
          sampleTime: DateTime(2025, 3, 10, 8, 30, 0),
          cloudCover: 10,
          precipitation: PrecipitationType.preNone,
          temperature: 24.5,
          windSpeed: 2,
          windDirection: 'NE',
          atmosphericPressure: 1013,
          relativeHumidity: 65,
        ),
      );

      sampleNest = Nest(
        id: 201,
        fieldNumber: 'N-2025-01',
        speciesName: 'Furnarius rufus',
        localityName: 'Tree Top Hill',
        longitude: -46.6350,
        latitude: -23.5520,
        foundTime: DateTime(2025, 2, 1, 10, 0, 0),
        support: 'Branch fork',
        heightAboveGround: 3.5,
        male: 'Present',
        female: 'Incubating',
        helpers: 'None',
        lastTime: DateTime(2025, 2, 15, 11, 0, 0),
        observer: 'Researcher A',
        nestFate: NestFateType.fatSuccess,
      );

      sampleNest.revisionsList = [
        NestRevision(
          id: 10,
          nestId: 201,
          sampleTime: DateTime(2025, 2, 5, 9, 30, 0),
          nestStatus: NestStatusType.nstActive,
          nestStage: NestStageType.stgIncubating,
          eggsHost: 3,
          nestlingsHost: 0,
          eggsParasite: 0,
          nestlingsParasite: 0,
          hasPhilornisLarvae: false,
          notes: '3 intact eggs',
        ),
      ];

      sampleNest.eggsList = [
        Egg(
          id: 1001,
          nestId: 201,
          sampleTime: DateTime(2025, 2, 5, 9, 35, 0),
          fieldNumber: 'E-01',
          speciesName: 'Furnarius rufus',
          eggShape: EggShapeType.estOval,
          width: 20.1,
          length: 28.4,
          mass: 6.2,
        ),
      ];

      sampleSpecimen = Specimen(
        id: 301,
        sampleTime: DateTime(2025, 1, 20, 14, 15, 0),
        fieldNumber: 'SPC-99',
        type: SpecimenType.spcFeathers,
        longitude: -46.6360,
        latitude: -23.5530,
        locality: 'Museum Collection',
        speciesName: 'Zenaida auriculata',
        observer: 'Curator B',
        notes: 'Tail feather specimen; good condition',
        isPending: false,
      );
    });

    test('inventory species rows column count matches header for CSV and Excel', () async {
      final rowsWithSpecies = await buildInventoriesSpeciesRows([sampleInventory], locale);
      checkColumnCounts(rowsWithSpecies);

      final emptyInventory = Inventory(id: '102', type: InventoryType.invCasual, duration: 0);
      final rowsWithoutSpecies = await buildInventoriesSpeciesRows([emptyInventory], locale);
      checkColumnCounts(rowsWithoutSpecies);
    });

    test('inventory vegetation rows column count matches header for CSV and Excel', () async {
      final rows = await buildInventoriesVegetationRows([sampleInventory], locale);
      checkColumnCounts(rows);
    });

    test('inventory weather rows column count matches header for CSV and Excel', () async {
      final rows = await buildInventoriesWeatherRows([sampleInventory], locale);
      checkColumnCounts(rows);
    });

    test('inventory poi rows column count matches header for CSV and Excel', () async {
      final rows = await buildInventoriesPoiRows([sampleInventory], locale);
      checkColumnCounts(rows);
    });

    test('inventory summary rows column count matches header for CSV and Excel', () async {
      final emptyInventory = Inventory(id: '102', type: InventoryType.invCasual, duration: 0);
      final rows = await buildInventoriesSummaryRows([sampleInventory, emptyInventory], locale);
      checkColumnCounts(rows);
    });

    test('nest summary rows column count matches header for CSV and Excel', () async {
      final emptyNest = Nest(id: 202);
      final rows = await buildNestsSummaryRows([sampleNest, emptyNest], locale);
      checkColumnCounts(rows);
    });

    test('nest revisions rows column count matches header for CSV and Excel', () async {
      final rowsWithRevisions = await buildNestsRevisionsRows([sampleNest], locale);
      checkColumnCounts(rowsWithRevisions);

      final nestWithoutRevisions = Nest(id: 202);
      final rowsWithoutRevisions = await buildNestsRevisionsRows([nestWithoutRevisions], locale);
      checkColumnCounts(rowsWithoutRevisions);
    });

    test('nest eggs rows column count matches header for CSV and Excel', () async {
      final rows = await buildNestsEggsRows([sampleNest], locale);
      checkColumnCounts(rows);
    });

    test('specimens rows column count matches header for CSV and Excel', () async {
      final emptySpecimen = Specimen();
      final rows = await buildSpecimensRows([sampleSpecimen, emptySpecimen], locale);
      checkColumnCounts(rows);
    });

    test('column count consistency is preserved when number formatting is disabled', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('formatNumbers', false);

      final speciesRows = await buildInventoriesSpeciesRows([sampleInventory], locale);
      checkColumnCounts(speciesRows);

      final vegRows = await buildInventoriesVegetationRows([sampleInventory], locale);
      checkColumnCounts(vegRows);

      final weatherRows = await buildInventoriesWeatherRows([sampleInventory], locale);
      checkColumnCounts(weatherRows);

      final poiRows = await buildInventoriesPoiRows([sampleInventory], locale);
      checkColumnCounts(poiRows);

      final nestRows = await buildNestsSummaryRows([sampleNest], locale);
      checkColumnCounts(nestRows);

      final specimenRows = await buildSpecimensRows([sampleSpecimen], locale);
      checkColumnCounts(specimenRows);
    });
  });
}
