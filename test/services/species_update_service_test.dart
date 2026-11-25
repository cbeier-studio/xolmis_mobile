import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:xolmis/core/core_consts.dart';
import 'package:xolmis/data/daos/egg_dao.dart';
import 'package:xolmis/data/daos/inventory_dao.dart';
import 'package:xolmis/data/daos/nest_dao.dart';
import 'package:xolmis/data/daos/nest_revision_dao.dart';
import 'package:xolmis/data/daos/poi_dao.dart';
import 'package:xolmis/data/daos/species_dao.dart';
import 'package:xolmis/data/daos/specimen_dao.dart';
import 'package:xolmis/data/daos/vegetation_dao.dart';
import 'package:xolmis/data/daos/weather_dao.dart';
import 'package:xolmis/data/database/database_helper.dart';
import 'package:xolmis/data/models/inventory.dart';
import 'package:xolmis/data/models/nest.dart';
import 'package:xolmis/data/models/specimen.dart';
import 'package:xolmis/services/species_update_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    SharedPreferences.setMockInitialValues({});

    // Mock rootBundle for assets/updates/species_update_2025.json
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (ByteData? message) async {
      if (message == null) return null;
      final String key = utf8.decode(message.buffer.asUint8List(message.offsetInBytes, message.lengthInBytes));
      if (key == 'assets/updates/species_update_2025.json') {
        final jsonContent = jsonEncode([
          {'oldName': 'Turdus rufiventris', 'newName': 'Turdus rufiventris (Updated)'},
          {'oldName': 'Xolmis irupero', 'newName': 'Xolmis irupero (Updated)'},
        ]);
        return ByteData.sublistView(Uint8List.fromList(utf8.encode(jsonContent)));
      }
      return null;
    });
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', null);
  });

  group('UpdateSummary Formatting', () {
    test('toString returns formatted summary message', () {
      final summary = UpdateSummary(
        year: 2025,
        updatesCount: 2,
        speciesUpdated: 3,
        nestsUpdated: 1,
        specimensUpdated: 4,
      );

      final text = summary.toString();
      expect(text, contains('2025'));
      expect(text, contains('2 pares de nomes'));
      expect(text, contains('Espécies atualizadas: 3'));
      expect(text, contains('Ninhos: 1'));
      expect(text, contains('Espécimes: 4'));
    });
  });

  group('SpeciesUpdateService Database Migration', () {
    late DatabaseHelper databaseHelper;
    late InventoryDao inventoryDao;
    late SpeciesDao speciesDao;
    late NestDao nestDao;
    late SpecimenDao specimenDao;
    late SpeciesUpdateService updateService;

    setUp(() async {
      databaseHelper = DatabaseHelper();
      await databaseHelper.initDatabase();

      final poiDao = PoiDao(databaseHelper);
      speciesDao = SpeciesDao(databaseHelper, poiDao);
      final vegetationDao = VegetationDao(databaseHelper);
      final weatherDao = WeatherDao(databaseHelper);
      inventoryDao = InventoryDao(databaseHelper, speciesDao, vegetationDao, weatherDao);

      final eggDao = EggDao(databaseHelper);
      final nestRevisionDao = NestRevisionDao(databaseHelper);
      nestDao = NestDao(databaseHelper, nestRevisionDao, eggDao);

      specimenDao = SpecimenDao(databaseHelper);

      updateService = SpeciesUpdateService(dbHelper: databaseHelper);
    });

    tearDownAll(() async {
      await databaseHelper.closeDatabase();
    });

    test('applySpeciesUpdates updates species names across species, nests, and specimens tables', () async {
      // 1. Seed inventory + species
      final inventory = Inventory(id: 'INV-TAXONOMY-1', type: InventoryType.invPointCount, duration: 15);
      await inventoryDao.insertInventory(inventory);

      final species = Species(
        inventoryId: 'INV-TAXONOMY-1',
        name: 'Turdus rufiventris',
        count: 2,
        isOutOfInventory: false,
      );
      await speciesDao.insertSpecies('INV-TAXONOMY-1', species);

      // 2. Seed nest
      final nest = Nest(
        fieldNumber: 'NEST-TAX-1',
        speciesName: 'Turdus rufiventris',
      );
      await nestDao.insertNest(nest);

      // 3. Seed specimen
      final specimen = Specimen(
        fieldNumber: 'SPC-TAX-1',
        speciesName: 'Xolmis irupero',
        type: SpecimenType.spcFeathers,
      );
      await specimenDao.insertSpecimen(specimen);

      // Apply updates for year 2025
      final summary = await updateService.applySpeciesUpdates(2025);

      expect(summary.year, equals(2025));
      expect(summary.updatesCount, equals(2));
      expect(summary.speciesUpdated, equals(1));
      expect(summary.nestsUpdated, equals(1));
      expect(summary.specimensUpdated, equals(1));

      // Verify updated names in species, nests, specimens
      final speciesList = await speciesDao.getSpeciesByInventory('INV-TAXONOMY-1', false);
      expect(speciesList.first.name, equals('Turdus rufiventris (Updated)'));

      final allNests = await nestDao.getNests();
      expect(allNests.first.speciesName, equals('Turdus rufiventris (Updated)'));

      final allSpecimens = await specimenDao.getSpecimens();
      expect(allSpecimens.first.speciesName, equals('Xolmis irupero (Updated)'));
    });

    test('applySpeciesUpdates is idempotent when run a second time', () async {
      // Seed specimen
      final specimen = Specimen(
        fieldNumber: 'SPC-TAX-2',
        speciesName: 'Xolmis irupero',
        type: SpecimenType.spcFeathers,
      );
      await specimenDao.insertSpecimen(specimen);

      // First run updates the record
      final summary1 = await updateService.applySpeciesUpdates(2025);
      expect(summary1.specimensUpdated, equals(1));

      // Second run finds 0 matching old records
      final summary2 = await updateService.applySpeciesUpdates(2025);
      expect(summary2.specimensUpdated, equals(0));

      final allSpecimens = await specimenDao.getSpecimens();
      expect(allSpecimens.first.speciesName, equals('Xolmis irupero (Updated)'));
    });

    test('applySpeciesUpdates returns empty summary when update file for year does not exist', () async {
      final summary = await updateService.applySpeciesUpdates(1999);

      expect(summary.year, equals(1999));
      expect(summary.updatesCount, equals(0));
      expect(summary.speciesUpdated, equals(0));
      expect(summary.nestsUpdated, equals(0));
      expect(summary.specimensUpdated, equals(0));
    });
  });
}
