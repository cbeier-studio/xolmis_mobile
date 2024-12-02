// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:xolmis/main.dart';

import 'package:xolmis/data/database/database_helper.dart';

import 'package:xolmis/data/database/repositories/inventory_repository.dart';
import 'package:xolmis/data/database/repositories/species_repository.dart';
import 'package:xolmis/data/database/repositories/poi_repository.dart';
import 'package:xolmis/data/database/repositories/vegetation_repository.dart';
import 'package:xolmis/data/database/repositories/weather_repository.dart';
import 'package:xolmis/data/database/repositories/nest_repository.dart';
import 'package:xolmis/data/database/repositories/nest_revision_repository.dart';
import 'package:xolmis/data/database/repositories/egg_repository.dart';
import 'package:xolmis/data/database/repositories/specimen_repository.dart';
import 'package:xolmis/data/database/repositories/app_image_repository.dart';

import 'package:xolmis/data/database/daos/egg_dao.dart';
import 'package:xolmis/data/database/daos/inventory_dao.dart';
import 'package:xolmis/data/database/daos/nest_dao.dart';
import 'package:xolmis/data/database/daos/nest_revision_dao.dart';
import 'package:xolmis/data/database/daos/poi_dao.dart';
import 'package:xolmis/data/database/daos/species_dao.dart';
import 'package:xolmis/data/database/daos/specimen_dao.dart';
import 'package:xolmis/data/database/daos/vegetation_dao.dart';
import 'package:xolmis/data/database/daos/weather_dao.dart';
import 'package:xolmis/data/database/daos/app_image_dao.dart';

Future<void> main() async {
  late DatabaseHelper databaseHelper;

  late InventoryDao inventoryDao;
  late SpeciesDao speciesDao;
  late PoiDao poiDao;
  late VegetationDao vegetationDao;
  late WeatherDao weatherDao;
  late NestDao nestDao;
  late NestRevisionDao nestRevisionDao;
  late EggDao eggDao;
  late SpecimenDao specimenDao;
  late AppImageDao appImageDao;

  late InventoryRepository inventoryRepository;
  late SpeciesRepository speciesRepository;
  late PoiRepository poiRepository;
  late VegetationRepository vegetationRepository;
  late WeatherRepository weatherRepository;
  late NestRepository nestRepository;
  late NestRevisionRepository nestRevisionRepository;
  late EggRepository eggRepository;
  late SpecimenRepository specimenRepository;
  late AppImageRepository appImageRepository;

  setUp(() async {
    databaseHelper = DatabaseHelper();
    await databaseHelper.initDatabase();

    poiDao = PoiDao(databaseHelper);
    speciesDao = SpeciesDao(databaseHelper, poiDao);
    vegetationDao = VegetationDao(databaseHelper);
    weatherDao = WeatherDao(databaseHelper);
    inventoryDao = InventoryDao(databaseHelper, speciesDao, vegetationDao, weatherDao);
    eggDao = EggDao(databaseHelper);
    nestRevisionDao = NestRevisionDao(databaseHelper);
    nestDao = NestDao(databaseHelper, nestRevisionDao, eggDao);
    specimenDao = SpecimenDao(databaseHelper);
    appImageDao = AppImageDao(databaseHelper);

    poiRepository = PoiRepository(poiDao);
    speciesRepository = SpeciesRepository(speciesDao);
    vegetationRepository = VegetationRepository(vegetationDao);
    weatherRepository = WeatherRepository(weatherDao);
    inventoryRepository = InventoryRepository(inventoryDao);
    eggRepository = EggRepository(eggDao);
    nestRevisionRepository = NestRevisionRepository(nestRevisionDao);
    nestRepository = NestRepository(nestDao);
    specimenRepository = SpecimenRepository(specimenDao);
    appImageRepository = AppImageRepository(appImageDao);
  });

  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
        MyApp(
          inventoryRepository: inventoryRepository,
          speciesRepository: speciesRepository,
          poiRepository: poiRepository,
          vegetationRepository: vegetationRepository,
          weatherRepository: weatherRepository,
          nestRepository: nestRepository,
          nestRevisionRepository: nestRevisionRepository,
          eggRepository: eggRepository,
          specimenRepository: specimenRepository,
          appImageRepository: appImageRepository,
        )
    );

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
