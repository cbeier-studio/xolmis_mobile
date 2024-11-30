import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:side_sheet/side_sheet.dart';
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

import 'screens/inventory/inventories_screen.dart';
import 'screens/nest/nests_screen.dart';
import 'screens/specimen/specimens_screen.dart';
import 'screens/settings_screen.dart';
import 'utils/utils.dart';
import 'utils/themes.dart';
import 'generated/l10n.dart';

// Run an empty task just to maintain Xolmis awake
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) {
    debugPrint('Xolmis acordado pelo WorkManager');
    return Future.value(true);
  });
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
    AndroidInitializationSettings('@drawable/ic_notification');
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

  // Preload the species names list
  allSpeciesNames = await loadSpeciesSearchData();
  allSpeciesNames.sort((a, b) => a.compareTo(b));

  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeModel(),
      child: MyApp(
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
      ),
    ),
  );
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
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
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
      ],
      child: Consumer<ThemeModel>(
        builder: (context, themeModel, child) {
          return MaterialApp(
            localizationsDelegates: [
                S.delegate,
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

class MainScreen extends StatefulWidget {

  const MainScreen({
    super.key,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;

  static final List<Widget Function(BuildContext, GlobalKey<ScaffoldState>)> _widgetOptions = <Widget Function(BuildContext, GlobalKey<ScaffoldState>)>[
        (context, scaffoldKey) => InventoriesScreen(scaffoldKey: scaffoldKey),
        (context, scaffoldKey) => NestsScreen(scaffoldKey: scaffoldKey),
        (context, scaffoldKey) => SpecimensScreen(scaffoldKey: scaffoldKey),
  ];

  @override
  void initState() {
    super.initState();
    scheduleWakeupTask();
    _requestNotificationPermission();

    Provider.of<InventoryProvider>(context, listen: false).fetchInventories();
    Provider.of<NestProvider>(context, listen: false).fetchNests();
    Provider.of<SpecimenProvider>(context, listen: false).fetchSpecimens();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void scheduleWakeupTask() {
    Workmanager().registerPeriodicTask(
      "wakeupTask",
      "wakeup",
      frequency: Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.not_required,
        requiresBatteryNotLow: false,
      ),
    );
  }

  Future<void> _requestNotificationPermission() async {
    final status = await Permission.notification.request();
    if (status.isGranted) {
      // Granted permission
    } else if (status.isDenied) {
      // Denied permission
    } else if (status.isPermanentlyDenied) {
      // Permanently denied permission
    }
  }

  @override
  Widget build(BuildContext context) {
    final useSideNavRail = MediaQuery.sizeOf(context).width >= 600 &&
        MediaQuery.sizeOf(context).width < 800;
    final useFixedNavDrawer = MediaQuery.sizeOf(context).width >= 800;
    List<NavigationRailDestination> destinations = [
      NavigationRailDestination(
        icon: Selector<InventoryProvider, int>(
          selector: (context, provider) => provider.inventoriesCount,
          builder: (context, inventoriesCount, child) {
            return Visibility(
              visible: inventoriesCount > 0,
              replacement: const Icon(Icons.list_alt_outlined),
              child: Badge.count(
                count: inventoriesCount,
                child: const Icon(Icons.list_alt_outlined),
              ),
            );
          },
        ),
        selectedIcon: Selector<InventoryProvider, int>(
          selector: (context, provider) => provider.inventoriesCount,
          builder: (context, inventoriesCount, child) {
            return Visibility(
              visible: inventoriesCount > 0,
              replacement: const Icon(Icons.list_alt),
              child: Badge.count(
                count: inventoriesCount,
                child: const Icon(Icons.list_alt),
              ),
            );
          },
        ),
        label: Text(S.of(context).inventories),
      ),
      NavigationRailDestination(
        icon: Selector<NestProvider, int>(
          selector: (context, provider) => provider.nestsCount,
          builder: (context, nestsCount, child) {
            return Visibility(
              visible: nestsCount > 0,
              replacement: const Icon(Icons.egg_outlined),
              child: Badge.count(
                count: nestsCount,
                child: const Icon(Icons.egg_outlined),
              ),
            );
          },
        ),
        selectedIcon: Selector<NestProvider, int>(
          selector: (context, provider) => provider.nestsCount,
          builder: (context, nestsCount, child) {
            return Visibility(
              visible: nestsCount > 0,
              replacement: const Icon(Icons.egg),
              child: Badge.count(
                count: nestsCount,
                child: const Icon(Icons.egg),
              ),
            );
          },
        ),
        label: Text(S.of(context).nests),
      ),
      NavigationRailDestination(
        icon: Selector<SpecimenProvider, int>(
          selector: (context, provider) => provider.specimensCount,
          builder: (context, specimensCount, child) {
            return Visibility(
              visible: specimensCount > 0,
              replacement: const Icon(Icons.local_offer_outlined),
              child: Badge.count(
                backgroundColor: Colors.deepPurple[100],
                textColor: Colors.deepPurple[800],
                count: specimensCount,
                child: const Icon(Icons.local_offer_outlined),
              ),
            );
          },
        ),
        selectedIcon: Selector<SpecimenProvider, int>(
          selector: (context, provider) => provider.specimensCount,
          builder: (context, specimensCount, child) {
            return Visibility(
              visible: specimensCount > 0,
              replacement: const Icon(Icons.local_offer),
              child: Badge.count(
                backgroundColor: Colors.deepPurple[100],
                textColor: Colors.deepPurple[800],
                count: specimensCount,
                child: const Icon(Icons.local_offer),
              ),
            );
          },
        ),
        label: Text(S.of(context).specimens(2)),
      ),
    ];

      return Scaffold(
      key: _scaffoldKey,
      drawer: _buildNavigationDrawer(context),
        body: Row(
          children: [
            if (useSideNavRail || useFixedNavDrawer) NavigationRail(
              trailing: IconButton(
                icon: Theme.of(context).brightness == Brightness.light
                    ? const Icon(Icons.settings_outlined)
                    : const Icon(Icons.settings),
                onPressed: () {
                  if (MediaQuery.sizeOf(context).width > 600) {
                    SideSheet.right(
                      context: context,
                      width: 400,
                      body: const SettingsScreen(),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SettingsScreen()),
                    );
                  }
                },
              ),
              destinations: destinations,
              selectedIndex: _selectedIndex,
              labelType: NavigationRailLabelType.all,
              onDestinationSelected: (int index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
            ),
            Expanded(
              child: _widgetOptions.elementAt(_selectedIndex).call(context, _scaffoldKey),
            ),
          ],
        ),
    );
  }

  NavigationDrawer _buildNavigationDrawer(BuildContext context) {
    return NavigationDrawer(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (int index) {
        setState(() {
          _selectedIndex = index;
        });
        Navigator.pop(context);
      },
      children: <Widget>[
        DrawerHeader(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Xolmis', style: TextStyle(fontSize: 24)),
              SizedBox(height: 20),
              OutlinedButton.icon(
                icon: Theme.of(context).brightness == Brightness.light
                    ? const Icon(Icons.settings_outlined)
                    : const Icon(Icons.settings),
                label: Text(S.of(context).settings),
                onPressed: () {
                  if (MediaQuery.sizeOf(context).width > 600) {
                    SideSheet.right(
                      context: context,
                      width: 400,
                      body: const SettingsScreen(),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SettingsScreen()),
                    );
                  }
                },
              ),
            ],
          ),
        ),
        NavigationDrawerDestination(
          icon: const Icon(Icons.list_alt_outlined),
          label: Selector<InventoryProvider, int>(
            selector: (context, provider) => provider.inventoriesCount,
            builder: (context, inventoriesCount, child) {
              return inventoriesCount > 0
                  ? Badge.count(
                count: inventoriesCount,
                alignment: AlignmentDirectional.centerEnd,
                offset: const Offset(24, -8),
                child: Text(S.of(context).inventories),
              )
                  : Text(S.of(context).inventories);
            },
          ),
          selectedIcon: const Icon(Icons.list_alt),
        ),
        NavigationDrawerDestination(
          icon: const Icon(Icons.egg_outlined),
          label: Selector<NestProvider, int>(
            selector: (context, provider) => provider.nestsCount,
            builder: (context, nestsCount, child) {
              return nestsCount > 0
                  ? Badge.count(
                count: nestsCount,
                alignment: AlignmentDirectional.centerEnd,
                offset: const Offset(24, -8),
                child: Text(S.of(context).nests),
              )
                  : Text(S.of(context).nests);
            },
          ),
          selectedIcon: const Icon(Icons.egg),
        ),
        NavigationDrawerDestination(
          icon: const Icon(Icons.local_offer_outlined),
          label: Text(S.of(context).specimens(2)),
          selectedIcon: const Icon(Icons.local_offer),
        ),
      ],
    );
  }
}