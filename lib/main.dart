import 'package:fleather/fleather.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/database/database_helper.dart';
import 'data/daos/inventory_dao.dart';
import 'data/daos/species_dao.dart';
import 'data/daos/poi_dao.dart';
import 'data/daos/vegetation_dao.dart';
import 'data/daos/weather_dao.dart';
import 'data/daos/nest_dao.dart';
import 'data/daos/nest_revision_dao.dart';
import 'data/daos/egg_dao.dart';
import 'data/daos/specimen_dao.dart';
import 'data/daos/app_image_dao.dart';
import 'data/daos/journal_dao.dart';

import 'providers/inventory_provider.dart';
import 'providers/species_provider.dart';
import 'providers/poi_provider.dart';
import 'providers/vegetation_provider.dart';
import 'providers/weather_provider.dart';
import 'providers/nest_provider.dart';
import 'providers/nest_revision_provider.dart';
import 'providers/egg_provider.dart';
import 'providers/specimen_provider.dart';
import 'providers/app_image_provider.dart';
import 'providers/journal_provider.dart';

import 'main_screen.dart';
import 'utils/utils.dart';
import 'utils/themes.dart';
import 'generated/l10n.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // All initialization logic is moved here, before runApp is called.

    // Register the Xolmis license
    LicenseRegistry.addLicense(() async* {
      final license = await rootBundle.loadString('assets/license.txt');
      yield LicenseEntryWithLineBreaks(['xolmis'], license);
    });

    // Start the notification service
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('ic_notification');
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();
    const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid, iOS: initializationSettingsIOS);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Initialize the database
    final databaseHelper = DatabaseHelper();
    await databaseHelper.initDatabase();

    // Create the DAOs
    final poiDao = PoiDao(databaseHelper);
    final speciesDao = SpeciesDao(databaseHelper, poiDao);
    final vegetationDao = VegetationDao(databaseHelper);
    final weatherDao = WeatherDao(databaseHelper);
    final inventoryDao =
        InventoryDao(databaseHelper, speciesDao, vegetationDao, weatherDao);
    final nestRevisionDao = NestRevisionDao(databaseHelper);
    final eggDao = EggDao(databaseHelper);
    final nestDao = NestDao(databaseHelper, nestRevisionDao, eggDao);
    final specimenDao = SpecimenDao(databaseHelper);
    final appImageDao = AppImageDao(databaseHelper);
    final journalDao = FieldJournalDao(databaseHelper);

    final appImageProvider = AppImageProvider(appImageDao);
    final poiProvider = PoiProvider(poiDao);
    final speciesProvider = SpeciesProvider(speciesDao);
    final vegetationProvider = VegetationProvider(vegetationDao);
    final weatherProvider = WeatherProvider(weatherDao);
    final nestRevisionProvider = NestRevisionProvider(nestRevisionDao);
    final eggProvider = EggProvider(eggDao);
    final specimenProvider = SpecimenProvider(specimenDao);
    final inventoryProvider = InventoryProvider(
      inventoryDao,
      speciesProvider,
      vegetationProvider,
      weatherProvider,
    );
    final nestProvider = NestProvider(nestDao);
    final journalProvider = FieldJournalProvider(journalDao);

    // Preload the species names list
    List<String> preloadedSpeciesNames = await loadSpeciesSearchData();
    preloadedSpeciesNames.sort((a, b) => a.compareTo(b));
    allSpeciesNames = List.from(preloadedSpeciesNames);

    final dependencies = AppDependencies(
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

      preloadedSpeciesNames: preloadedSpeciesNames,
    );

    runApp(
      ChangeNotifierProvider(
        create: (context) => ThemeModel(),
        child: MyApp(
          dependencies: dependencies,
        ),
      ),
    );
  } catch (e, s) {
    debugPrint('Erro fatal ao inicializar o aplicativo: $e\n$s');
    // Optionally, you can run an error-specific app widget
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Erro fatal ao inicializar o aplicativo: $e'),
        ),
      ),
    ));
  }
}

class AppDependencies {
  final InventoryDao inventoryDao;
  final SpeciesDao speciesDao;
  final PoiDao poiDao;
  final VegetationDao vegetationDao;
  final WeatherDao weatherDao;
  final NestDao nestDao;
  final NestRevisionDao nestRevisionDao;
  final EggDao eggDao;
  final SpecimenDao specimenDao;
  final AppImageDao appImageDao;
  final FieldJournalDao journalDao;
  final InventoryProvider inventoryProvider;
  final SpeciesProvider speciesProvider;
  final PoiProvider poiProvider;
  final VegetationProvider vegetationProvider;
  final WeatherProvider weatherProvider;
  final NestProvider nestProvider;
  final NestRevisionProvider nestRevisionProvider;
  final EggProvider eggProvider;
  final SpecimenProvider specimenProvider;
  final AppImageProvider appImageProvider;
  final FieldJournalProvider journalProvider;
  final List<String> preloadedSpeciesNames;

  AppDependencies({
    required this.inventoryDao,
    required this.speciesDao,
    required this.poiDao,
    required this.vegetationDao,
    required this.weatherDao,
    required this.nestDao,
    required this.nestRevisionDao,
    required this.eggDao,
    required this.specimenDao,
    required this.appImageDao,
    required this.journalDao,
    required this.inventoryProvider,
    required this.speciesProvider,
    required this.poiProvider,
    required this.vegetationProvider,
    required this.weatherProvider,
    required this.nestProvider,
    required this.nestRevisionProvider,
    required this.eggProvider,
    required this.specimenProvider,
    required this.appImageProvider,
    required this.journalProvider,
    this.preloadedSpeciesNames = const [],
  });
}

class MyApp extends StatelessWidget {
  final AppDependencies dependencies;

  const MyApp({
    super.key,
    required this.dependencies,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: dependencies.journalProvider),
        ChangeNotifierProvider.value(value: dependencies.appImageProvider),
        ChangeNotifierProvider.value(value: dependencies.specimenProvider),
        ChangeNotifierProvider.value(value: dependencies.nestRevisionProvider),
        ChangeNotifierProvider.value(value: dependencies.eggProvider),
        ChangeNotifierProvider.value(value: dependencies.poiProvider),
        ChangeNotifierProvider.value(value: dependencies.speciesProvider),
        ChangeNotifierProvider.value(value: dependencies.vegetationProvider),
        ChangeNotifierProvider.value(value: dependencies.weatherProvider),
        ChangeNotifierProvider.value(value: dependencies.inventoryProvider),
        ChangeNotifierProvider.value(value: dependencies.nestProvider),
        Provider.value(value: dependencies.inventoryDao),
        Provider.value(value: dependencies.speciesDao),
        Provider.value(value: dependencies.poiDao),
        Provider.value(value: dependencies.vegetationDao),
        Provider.value(value: dependencies.weatherDao),
        Provider.value(value: dependencies.journalDao),
      ],
      child: Consumer<ThemeModel>(
        builder: (context, themeModel, child) {
          return MaterialApp(
            localizationsDelegates: [
                S.delegate,
                FleatherLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: S.delegate.supportedLocales,
            localeResolutionCallback: (Locale? locale, Iterable<Locale> supportedLocales) { 
              if (locale == null) { 
                return supportedLocales.first;  
              } 
              for (var supportedLocale in supportedLocales) { 
                if (supportedLocale.languageCode == locale.languageCode && supportedLocale.countryCode == locale.countryCode) {
                  return supportedLocale; 
                } else if (supportedLocale.languageCode == locale.languageCode) { 
                  return supportedLocale; 
                } 
              } 
              return Locale('en', '');  
            },
            title: 'Xolmis',
            theme: ThemeData(brightness: Brightness.light),
            darkTheme: ThemeData(brightness: Brightness.dark),
            themeMode: themeModel.themeMode,
            home: MainScreen(),
          );
        },
      ),
    );
  }
}
