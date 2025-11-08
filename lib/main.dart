import 'package:fleather/fleather.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/database/database_helper.dart';
import 'data/database/daos/inventory_dao.dart';
import 'data/database/daos/species_dao.dart';
import 'data/database/daos/poi_dao.dart';
import 'data/database/daos/vegetation_dao.dart';
import 'data/database/daos/weather_dao.dart';
import 'data/database/daos/nest_dao.dart';
import 'data/database/daos/nest_revision_dao.dart';
import 'data/database/daos/egg_dao.dart';
import 'data/database/daos/specimen_dao.dart';
import 'data/database/daos/app_image_dao.dart';
import 'data/database/daos/journal_dao.dart';

// import 'data/database/repositories/inventory_repository.dart';
// import 'data/database/repositories/species_repository.dart';
// import 'data/database/repositories/poi_repository.dart';
// import 'data/database/repositories/vegetation_repository.dart';
// import 'data/database/repositories/weather_repository.dart';
// import 'data/database/repositories/nest_repository.dart';
// import 'data/database/repositories/nest_revision_repository.dart';
// import 'data/database/repositories/egg_repository.dart';
// import 'data/database/repositories/specimen_repository.dart';
// import 'data/database/repositories/app_image_repository.dart';
// import 'data/database/repositories/journal_repository.dart';

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

const String keepAwakeTaskName = "wakeup";

// Run an empty task just to maintain Xolmis awake
@pragma('vm:entry-point')
void callbackDispatcher() {
  WidgetsFlutterBinding.ensureInitialized();
  Workmanager().executeTask((task, inputData) async {
    try {
      switch (task) {
        case "wakeup":
          debugPrint('Xolmis awakened by WorkManager (KeepAwake Task)');
          break;
        default:
          debugPrint("Unknown task: $task");
          break;
      }
      return Future.value(true); // Successful execution
    } catch (e, s) {
      debugPrint('WorkManager error: $e\n$s');
      return Future.value(false);
    }
  });
}

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

    // Start the work manager
    Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );

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

    // Create the repositories
    // final inventoryRepository = InventoryRepository(inventoryDao);
    // final speciesRepository = SpeciesRepository(speciesDao);
    // final poiRepository = PoiRepository(poiDao);
    // final vegetationRepository = VegetationRepository(vegetationDao);
    // final weatherRepository = WeatherRepository(weatherDao);
    // final nestRepository = NestRepository(nestDao);
    // final nestRevisionRepository = NestRevisionRepository(nestRevisionDao);
    // final eggRepository = EggRepository(eggDao);
    // final specimenRepository = SpecimenRepository(specimenDao);
    // final appImageRepository = AppImageRepository(appImageDao);
    // final journalRepository = FieldJournalRepository(journalDao);

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
        ChangeNotifierProvider(create: (context) => FieldJournalProvider(dependencies.journalDao)),
        ChangeNotifierProvider(create: (context) => AppImageProvider(dependencies.appImageDao)),
        ChangeNotifierProvider(create: (context) => SpecimenProvider(dependencies.specimenDao)),
        ChangeNotifierProvider(create: (context) => NestRevisionProvider(dependencies.nestRevisionDao)),
        ChangeNotifierProvider(create: (context) => EggProvider(dependencies.eggDao)),
        ChangeNotifierProvider(create: (context) => PoiProvider(dependencies.poiDao)),
        ChangeNotifierProvider(create: (context) => SpeciesProvider(dependencies.speciesDao)),
        ChangeNotifierProvider(create: (context) => VegetationProvider(dependencies.vegetationDao)),
        ChangeNotifierProvider(create: (context) => WeatherProvider(dependencies.weatherDao)),
        ChangeNotifierProvider(
          create: (context) => InventoryProvider(
            dependencies.inventoryDao,
            context.read<SpeciesProvider>(),
            context.read<VegetationProvider>(),
            context.read<WeatherProvider>(),
          ),
        ),
        ChangeNotifierProvider(create: (_) => NestProvider(dependencies.nestDao)),
        Provider(create: (_) => dependencies.inventoryDao),
        Provider(create: (_) => dependencies.speciesDao),
        Provider(create: (_) => dependencies.poiDao),
        Provider(create: (_) => dependencies.vegetationDao),
        Provider(create: (_) => dependencies.weatherDao),
        Provider(create: (_) => dependencies.journalDao),
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
