// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xolmis/data/daos/journal_dao.dart';
// import 'package:xolmis/data/database/repositories/journal_repository.dart';

import 'package:xolmis/main.dart';

import 'package:xolmis/data/database/database_helper.dart';

import 'package:xolmis/providers/inventory_provider.dart';
import 'package:xolmis/providers/species_provider.dart';
import 'package:xolmis/providers/poi_provider.dart';
import 'package:xolmis/providers/vegetation_provider.dart';
import 'package:xolmis/providers/weather_provider.dart';
import 'package:xolmis/providers/nest_provider.dart';
import 'package:xolmis/providers/nest_revision_provider.dart';
import 'package:xolmis/providers/egg_provider.dart';
import 'package:xolmis/providers/specimen_provider.dart';
import 'package:xolmis/providers/app_image_provider.dart';
import 'package:xolmis/providers/journal_provider.dart';

import 'package:xolmis/data/daos/egg_dao.dart';
import 'package:xolmis/data/daos/inventory_dao.dart';
import 'package:xolmis/data/daos/nest_dao.dart';
import 'package:xolmis/data/daos/nest_revision_dao.dart';
import 'package:xolmis/data/daos/poi_dao.dart';
import 'package:xolmis/data/daos/species_dao.dart';
import 'package:xolmis/data/daos/specimen_dao.dart';
import 'package:xolmis/data/daos/vegetation_dao.dart';
import 'package:xolmis/data/daos/weather_dao.dart';
import 'package:xolmis/data/daos/app_image_dao.dart';

void main() async {
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
  late FieldJournalDao journalDao;

  late InventoryProvider inventoryProvider;
  late SpeciesProvider speciesProvider;
  late PoiProvider poiProvider;
  late VegetationProvider vegetationProvider;
  late WeatherProvider weatherProvider;
  late NestProvider nestProvider;
  late NestRevisionProvider nestRevisionProvider;
  late EggProvider eggProvider;
  late SpecimenProvider specimenProvider;
  late AppImageProvider appImageProvider;
  late FieldJournalProvider journalProvider;

  late AppDependencies dependencies;

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
    journalDao = FieldJournalDao(databaseHelper);

    poiProvider = PoiProvider(poiDao);
    speciesProvider = SpeciesProvider(speciesDao);
    vegetationProvider = VegetationProvider(vegetationDao);
    weatherProvider = WeatherProvider(weatherDao);
    inventoryProvider = InventoryProvider(inventoryDao, speciesProvider, vegetationProvider, weatherProvider);
    eggProvider = EggProvider(eggDao);
    nestRevisionProvider = NestRevisionProvider(nestRevisionDao);
    nestProvider = NestProvider(nestDao);
    specimenProvider = SpecimenProvider(specimenDao);
    appImageProvider = AppImageProvider(appImageDao);
    journalProvider = FieldJournalProvider(journalDao);

    dependencies = AppDependencies(
      inventoryDao: inventoryDao,
      speciesDao: speciesDao,
      poiDao: poiDao,
      vegetationDao: vegetationDao,
      weatherDao: weatherDao,
      nestDao: nestDao,
      nestRevisionDao: nestRevisionDao,
      eggDao: eggDao,
      specimenDao: specimenDao,
      appImageDao: appImageDao,
      journalDao: journalDao,
      inventoryProvider: inventoryProvider,
      speciesProvider: speciesProvider,
      poiProvider: poiProvider,
      vegetationProvider: vegetationProvider,
      weatherProvider: weatherProvider,
      nestProvider: nestProvider,
      nestRevisionProvider: nestRevisionProvider,
      eggProvider: eggProvider,
      specimenProvider: specimenProvider,
      appImageProvider: appImageProvider,
      journalProvider: journalProvider,
    );    
  });

  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
        MyApp(
          dependencies: dependencies,
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
