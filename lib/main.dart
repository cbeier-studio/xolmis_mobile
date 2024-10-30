import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

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

import 'data/database/repositories/inventory_repository.dart';
import 'data/database/repositories/species_repository.dart';
import 'data/database/repositories/poi_repository.dart';
import 'data/database/repositories/vegetation_repository.dart';
import 'data/database/repositories/weather_repository.dart';
import 'data/database/repositories/nest_repository.dart';
import 'data/database/repositories/nest_revision_repository.dart';
import 'data/database/repositories/egg_repository.dart';
import 'data/database/repositories/specimen_repository.dart';

import 'providers/inventory_provider.dart';
import 'providers/species_provider.dart';
import 'providers/poi_provider.dart';
import 'providers/vegetation_provider.dart';
import 'providers/weather_provider.dart';
import 'providers/nest_provider.dart';
import 'providers/nest_revision_provider.dart';
import 'providers/egg_provider.dart';
import 'providers/specimen_provider.dart';

import 'screens/inventory/inventories_screen.dart';
import 'screens/nest/nests_screen.dart';
import 'screens/specimen/specimens_screen.dart';
import 'screens/utils.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('assets/license.txt');
    yield LicenseEntryWithLineBreaks(['xolmis'], license);
  });
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

  final themeMode = await getThemeMode();
  runApp(MyApp(
    themeMode: themeMode,
    inventoryRepository: inventoryRepository,
    speciesRepository: speciesRepository,
    poiRepository: poiRepository,
    vegetationRepository: vegetationRepository,
    weatherRepository: weatherRepository,
    nestRepository: nestRepository,
    nestRevisionRepository: nestRevisionRepository,
    eggRepository: eggRepository,
    specimenRepository: specimenRepository,
  ));
}

class MyApp extends StatelessWidget {
  final ThemeMode themeMode;
  final InventoryRepository inventoryRepository;
  final SpeciesRepository speciesRepository;
  final PoiRepository poiRepository;
  final VegetationRepository vegetationRepository;
  final WeatherRepository weatherRepository;
  final NestRepository nestRepository;
  final NestRevisionRepository nestRevisionRepository;
  final EggRepository eggRepository;
  final SpecimenRepository specimenRepository;

  const MyApp({
    super.key,
    required this.themeMode,
    required this.inventoryRepository,
    required this.speciesRepository,
    required this.poiRepository,
    required this.vegetationRepository,
    required this.weatherRepository,
    required this.nestRepository,
    required this.nestRevisionRepository,
    required this.eggRepository,
    required this.specimenRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => SpecimenProvider(specimenRepository)),
        ChangeNotifierProvider(create: (context) => NestRevisionProvider(nestRevisionRepository)),
        ChangeNotifierProvider(create: (context) => EggProvider(eggRepository)),
        ChangeNotifierProvider(create: (context) => PoiProvider(poiRepository)),
        ChangeNotifierProvider(create: (context) => SpeciesProvider(speciesRepository, inventoryRepository)),
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
      child: MaterialApp(
        title: 'Xolmis',
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        themeMode: themeMode,
        // theme: ThemeData(
        //   primarySwatch: Colors.deepPurple,
        // ),
        home: MainScreen(),
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
  int _selectedIndex = 0;
  // final ValueNotifier<int> activeInventoriesCount = ValueNotifier<int>(0);
  // final inventoryCountNotifier = InventoryCountNotifier();
  static final List<Widget Function(BuildContext)> _widgetOptions = <Widget Function(BuildContext)>[
        (context) => const InventoriesScreen(),
        (context) => const ActiveNestsScreen(),
        (context) => const SpecimensScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    initializeBackgroundExecution();
    // inventoryCountNotifier.updateCount();
    Provider.of<InventoryProvider>(context, listen: false).loadInventories();
    Provider.of<NestProvider>(context, listen: false).fetchNests();
    Provider.of<SpecimenProvider>(context, listen: false).fetchSpecimens();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    super.dispose();
  }

  Future<void> initializeBackgroundExecution() async {
    final androidConfig = FlutterBackgroundAndroidConfig(
      notificationTitle: 'Xolmis',
      notificationText: 'O Xolmis está rodando em segundo plano',
      notificationImportance: AndroidNotificationImportance.normal,
      notificationIcon: AndroidResource(name: 'background_icon', defType: 'drawable'),
    );
    bool success = await FlutterBackground.initialize(androidConfig: androidConfig);
    if (success) {
      await FlutterBackground.enableBackgroundExecution();
    }
  }

  // Future<void> updateActiveInventoriesCount() async {
  //   final count = await DatabaseHelper().getActiveInventoriesCount();
  //   activeInventoriesCount.value = count;
  // }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final useSideNavRail = MediaQuery.sizeOf(context).width >= 600;
    const List<NavigationRailDestination> destinations = [
      NavigationRailDestination(
        icon: Icon(Icons.list_alt_outlined),
        label: Text('Inventários'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.egg_outlined),
        label: Text('Ninhos'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.local_offer_outlined),
        label: Text('Espécimes'),
      ),
    ];

    return Scaffold(
        // appBar: AppBar(
        //   title: const Text('Xolmis'),
        // ),
        body: Row(
          children: [
            if (useSideNavRail) NavigationRail(
              destinations: destinations,
              selectedIndex: _selectedIndex,
              onDestinationSelected: (int index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
            ),
            Expanded(
              child: _widgetOptions.elementAt(_selectedIndex)(context),
            ),
          ],
        ),
        bottomNavigationBar: useSideNavRail
          ? null
          : BottomNavigationBar(
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Selector<InventoryProvider, int>(
                selector: (context, provider) => provider.inventoriesCount,
                builder: (context, inventoriesCount, child) {
                  return inventoriesCount > 0
                      ? Badge.count(
                    count: inventoriesCount,
                    child: const Icon(Icons.list_alt_outlined),
                  )
                      : const Icon(Icons.list_alt_outlined);
                },
              ),
              label: 'Inventários',
            ),
            BottomNavigationBarItem(
              icon: Selector<NestProvider, int>(
                selector: (context, provider) => provider.nestsCount,
                builder: (context, nestsCount, child) {
                  return nestsCount > 0
                      ? Badge.count(
                    count: nestsCount,
                    child: const Icon(Icons.egg_outlined),
                  )
                      : const Icon(Icons.egg_outlined);
                },
              ),
              label: 'Ninhos',
            ),
            BottomNavigationBarItem(
              icon: Selector<SpecimenProvider, int>(
                selector: (context, provider) => provider.specimensCount,
                builder: (context, specimensCount, child) {
                  return specimensCount > 0
                      ? Badge.count(
                    count: specimensCount,
                    child: const Icon(Icons.local_offer_outlined),
                  )
                      : const Icon(Icons.local_offer_outlined);
                },
              ),
              label: 'Espécimes',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.deepPurple,
          onTap: _onItemTapped,
        ),

    );
  }
}