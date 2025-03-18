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

import 'data/database/repositories/inventory_repository.dart';
import 'data/database/repositories/species_repository.dart';
import 'data/database/repositories/poi_repository.dart';
import 'data/database/repositories/vegetation_repository.dart';
import 'data/database/repositories/weather_repository.dart';
import 'data/database/repositories/nest_repository.dart';
import 'data/database/repositories/nest_revision_repository.dart';
import 'data/database/repositories/egg_repository.dart';
import 'data/database/repositories/specimen_repository.dart';
import 'data/database/repositories/app_image_repository.dart';
import 'data/database/repositories/journal_repository.dart';

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

// Run an empty task just to maintain Xolmis awake
@pragma('vm:entry-point')
void callbackDispatcher() {
  WidgetsFlutterBinding.ensureInitialized();
  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case "wakeup":
        debugPrint('Xolmis acordado pelo WorkManager (KeepAwake Task)');
        // Aqui podemos adicionar lógicas adicionais caso necessário
        // Por exemplo: verificar se existe alguma tarefa importante pendente
        break;
      default:
        debugPrint("Tarefa desconhecida: $task");
        break;
    }

    // Retorna true para indicar que a tarefa foi bem sucedida
    return Future.value(true);
  });
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyAppInitializer());
}

class MyAppInitializer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _initializeApp(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return MaterialApp(
            home: Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        } else if (snapshot.hasError) {
          return MaterialApp(
            home: Scaffold(
              body: Center(child: Text('Erro ao inicializar o aplicativo: ${snapshot.error}')),
            ),
          );
        } else {
          final data = snapshot.data!;
          return ChangeNotifierProvider(
            create: (context) => ThemeModel(),
            child: MyApp(
              inventoryRepository: data['inventoryRepository'],
              speciesRepository: data['speciesRepository'],
              poiRepository: data['poiRepository'],
              vegetationRepository: data['vegetationRepository'],
              weatherRepository: data['weatherRepository'],
              nestRepository: data['nestRepository'],
              nestRevisionRepository: data['nestRevisionRepository'],
              eggRepository: data['eggRepository'],
              specimenRepository: data['specimenRepository'],
              appImageRepository: data['appImageRepository'],
              journalRepository: data['journalRepository'],
            ),
          );
        }
      },
    );
  }

  Future<Map<String, dynamic>> _initializeApp() async {
    try {
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
      await DatabaseHelper().initDatabase();

      // Create the DAOs
      final databaseHelper = DatabaseHelper();
      final poiDao = PoiDao(databaseHelper);
      final speciesDao = SpeciesDao(databaseHelper, poiDao);
      final vegetationDao = VegetationDao(databaseHelper);
      final weatherDao = WeatherDao(databaseHelper);
      final inventoryDao = InventoryDao(databaseHelper, speciesDao, vegetationDao, weatherDao);
      final nestRevisionDao = NestRevisionDao(databaseHelper);
      final eggDao = EggDao(databaseHelper);
      final nestDao = NestDao(databaseHelper, nestRevisionDao, eggDao);
      final specimenDao = SpecimenDao(databaseHelper);
      final appImageDao = AppImageDao(databaseHelper);
      final journalDao = FieldJournalDao(databaseHelper);

      // Create the repositories
      final inventoryRepository = InventoryRepository(inventoryDao);
      final speciesRepository = SpeciesRepository(speciesDao);
      final poiRepository = PoiRepository(poiDao);
      final vegetationRepository = VegetationRepository(vegetationDao);
      final weatherRepository = WeatherRepository(weatherDao);
      final nestRepository = NestRepository(nestDao);
      final nestRevisionRepository = NestRevisionRepository(nestRevisionDao);
      final eggRepository = EggRepository(eggDao);
      final specimenRepository = SpecimenRepository(specimenDao);
      final appImageRepository = AppImageRepository(appImageDao);
      final journalRepository = FieldJournalRepository(journalDao);

      // Preload the species names list
      allSpeciesNames = await loadSpeciesSearchData();
      allSpeciesNames.sort((a, b) => a.compareTo(b));

      return {
        'inventoryRepository': inventoryRepository,
        'speciesRepository': speciesRepository,
        'poiRepository': poiRepository,
        'vegetationRepository': vegetationRepository,
        'weatherRepository': weatherRepository,
        'nestRepository': nestRepository,
        'nestRevisionRepository': nestRevisionRepository,
        'eggRepository': eggRepository,
        'specimenRepository': specimenRepository,
        'appImageRepository': appImageRepository,
        'journalRepository': journalRepository,
      };
    } catch (e) {
      debugPrint('Erro ao inicializar o aplicativo: $e');
      rethrow;
    }
  }
}

class MyApp extends StatelessWidget {
  final InventoryRepository inventoryRepository;
  final SpeciesRepository speciesRepository;
  final PoiRepository poiRepository;
  final VegetationRepository vegetationRepository;
  final WeatherRepository weatherRepository;
  final NestRepository nestRepository;
  final NestRevisionRepository nestRevisionRepository;
  final EggRepository eggRepository;
  final SpecimenRepository specimenRepository;
  final AppImageRepository appImageRepository;
  final FieldJournalRepository journalRepository;

  const MyApp({
    super.key,
    required this.inventoryRepository,
    required this.speciesRepository,
    required this.poiRepository,
    required this.vegetationRepository,
    required this.weatherRepository,
    required this.nestRepository,
    required this.nestRevisionRepository,
    required this.eggRepository,
    required this.specimenRepository,
    required this.appImageRepository,
    required this.journalRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => FieldJournalProvider(journalRepository)),
        ChangeNotifierProvider(create: (context) => AppImageProvider(appImageRepository)),
        ChangeNotifierProvider(create: (context) => SpecimenProvider(specimenRepository)),
        ChangeNotifierProvider(create: (context) => NestRevisionProvider(nestRevisionRepository)),
        ChangeNotifierProvider(create: (context) => EggProvider(eggRepository)),
        ChangeNotifierProvider(create: (context) => PoiProvider(poiRepository)),
        ChangeNotifierProvider(create: (context) => SpeciesProvider(speciesRepository)),
        ChangeNotifierProvider(create: (context) => VegetationProvider(vegetationRepository)),
        ChangeNotifierProvider(create: (context) => WeatherProvider(weatherRepository)),
        ChangeNotifierProvider(
          create: (context) => InventoryProvider(
            inventoryRepository,
            context.read<SpeciesProvider>(),
            context.read<VegetationProvider>(),
            context.read<WeatherProvider>(),
          ),
        ),
        ChangeNotifierProvider(create: (_) => NestProvider(nestRepository)),
        Provider(create: (_) => inventoryRepository),
        Provider(create: (_) => speciesRepository),
        Provider(create: (_) => poiRepository),
        Provider(create: (_) => vegetationRepository),
        Provider(create: (_) => weatherRepository),
        Provider(create: (_) => journalRepository),
      ],
      child: Consumer<ThemeModel>(
        builder: (context, themeModel, child) {
          return MaterialApp(
            localizationsDelegates: [
                S.delegate,
                // FleatherLocalizations.delegate,
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
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            themeMode: themeModel.themeMode,
            home: MainScreen(),
          );
        },
      ),
    );
  }
}

