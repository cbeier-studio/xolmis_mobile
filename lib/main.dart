import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
// import 'package:flutter_background/flutter_background.dart';
import 'package:side_sheet/side_sheet.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:wakelock_plus/wakelock_plus.dart';
// import 'package:flutter_foreground_service/flutter_foreground_service.dart';

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
import 'screens/utils.dart';

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) {
    // Realize uma operação mínima, como registrar um log
    debugPrint('Xolmis acordado pelo WorkManager');
    return Future.value(true);
  });
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('assets/license.txt');
    yield LicenseEntryWithLineBreaks(['xolmis'], license);
  });
  Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: false,
  );
  const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@drawable/ic_notification');
  const DarwinInitializationSettings initializationSettingsIOS =
    DarwinInitializationSettings();
  const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid, iOS: initializationSettingsIOS);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

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
    appImageRepository: appImageRepository,
  ));
  // startForegroundService();
}

// void startForegroundService() async {
//   ForegroundService().start();
//   debugPrint("Started service");
// }

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
  final AppImageRepository appImageRepository;

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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;
  // final ValueNotifier<int> activeInventoriesCount = ValueNotifier<int>(0);
  // final inventoryCountNotifier = InventoryCountNotifier();
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
    // WakelockPlus.enable();
    // initializeBackgroundExecution();
    // inventoryCountNotifier.updateCount();
    Provider.of<InventoryProvider>(context, listen: false).fetchInventories();
    Provider.of<NestProvider>(context, listen: false).fetchNests();
    Provider.of<SpecimenProvider>(context, listen: false).fetchSpecimens();
  }

  @override
  void dispose() {
    // WakelockPlus.disable();
    // ForegroundService().stop();
    super.dispose();
  }

  void scheduleWakeupTask() {
    Workmanager().registerPeriodicTask(
      "wakeupTask",
      "wakeup",
      frequency: Duration(minutes: 5),
      constraints: Constraints(
        networkType: NetworkType.not_required,
        requiresBatteryNotLow: false,
      ),
    );
  }

  Future<void> _requestNotificationPermission() async {
    final status = await Permission.notification.request();
    if (status.isGranted) {
      // A permissão foi concedida
    } else if (status.isDenied) {
      // A permissão foi negada
    } else if (status.isPermanentlyDenied) {
      // A permissão foi negada permanentemente
    }
  }

  // void _onItemTapped(int index) {
  //   setState(() {
  //     _selectedIndex = index;
  //   });
  // }

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
            return inventoriesCount > 0
                ? Badge.count(
              count: inventoriesCount,
              child: const Icon(Icons.list_alt_outlined),
            )
                : const Icon(Icons.list_alt_outlined);
          },
        ),
        label: Text('Inventários'),
      ),
      NavigationRailDestination(
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
        label: Text('Ninhos'),
      ),
      NavigationRailDestination(
        icon: Selector<SpecimenProvider, int>(
          selector: (context, provider) => provider.specimensCount,
          builder: (context, specimensCount, child) {
            return specimensCount > 0
                ? Badge.count(
              backgroundColor: Colors.deepPurple[100],
              textColor: Colors.deepPurple[800],
              count: specimensCount,
              child: const Icon(Icons.local_offer_outlined),
            )
                : const Icon(Icons.local_offer_outlined);
          },
        ),
        label: Text('Espécimes'),
      ),
    ];

    // if (useFixedNavDrawer) {
    //   return Row(
    //     children: [
    //       _buildNavigationDrawer(context),
    //       Expanded(
    //           child: _widgetOptions.elementAt(_selectedIndex).call(context, _scaffoldKey),
    //       ),
    //     ],
    //   );
    // } else {
      return Scaffold(
      key: _scaffoldKey,
        // appBar: AppBar(
        //   title: const Text('Xolmis'),
        // ),
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
        // bottomNavigationBar: useSideNavRail
        //   ? null
        //   : BottomNavigationBar(
        //   items: <BottomNavigationBarItem>[
        //     BottomNavigationBarItem(
        //       icon: Selector<InventoryProvider, int>(
        //         selector: (context, provider) => provider.inventoriesCount,
        //         builder: (context, inventoriesCount, child) {
        //           return inventoriesCount > 0
        //               ? Badge.count(
        //             count: inventoriesCount,
        //             child: const Icon(Icons.list_alt_outlined),
        //           )
        //               : const Icon(Icons.list_alt_outlined);
        //         },
        //       ),
        //       label: 'Inventários',
        //     ),
        //     BottomNavigationBarItem(
        //       icon: Selector<NestProvider, int>(
        //         selector: (context, provider) => provider.nestsCount,
        //         builder: (context, nestsCount, child) {
        //           return nestsCount > 0
        //               ? Badge.count(
        //             count: nestsCount,
        //             child: const Icon(Icons.egg_outlined),
        //           )
        //               : const Icon(Icons.egg_outlined);
        //         },
        //       ),
        //       label: 'Ninhos',
        //     ),
        //     BottomNavigationBarItem(
        //       icon: Selector<SpecimenProvider, int>(
        //         selector: (context, provider) => provider.specimensCount,
        //         builder: (context, specimensCount, child) {
        //           return specimensCount > 0
        //               ? Badge.count(
        //             backgroundColor: Colors.deepPurple[100],
        //             textColor: Colors.deepPurple[800],
        //             count: specimensCount,
        //             child: const Icon(Icons.local_offer_outlined),
        //           )
        //               : const Icon(Icons.local_offer_outlined);
        //         },
        //       ),
        //       label: 'Espécimes',
        //     ),
        //   ],
        //   currentIndex: _selectedIndex,
        //   selectedItemColor: Theme.of(context).brightness == Brightness.light
        //       ? Colors.deepPurple
        //       : Colors.deepPurpleAccent,
        //   onTap: _onItemTapped,
        // ),

    );
      // }
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
                label: Text('Configurações'),
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
                child: const Text('Inventários'),
              )
                  : const Text('Inventários');
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
                child: const Text('Ninhos'),
              )
                  : const Text('Ninhos');
            },
          ),
          selectedIcon: const Icon(Icons.egg),
        ),
        NavigationDrawerDestination(
          icon: const Icon(Icons.local_offer_outlined),
          label: const Text('Espécimes'),
          selectedIcon: const Icon(Icons.local_offer),
        ),
        // const Padding(
        //   padding: EdgeInsets.symmetric(horizontal: 16),
        //   child: Divider(),
        // ),
        // ListTile(
        //   leading: Theme.of(context).brightness == Brightness.light
        //       ? const Icon(Icons.settings_outlined)
        //       : const Icon(Icons.settings),
        //   title: const Text('Configurações'),
        //   onTap: () {
        //     if (MediaQuery.sizeOf(context).width > 600) {
        //       SideSheet.right(
        //         context: context,
        //         width: 400,
        //         body: const SettingsScreen(),
        //       );
        //     } else {
        //       Navigator.push(
        //         context,
        //         MaterialPageRoute(builder: (context) => const SettingsScreen()),
        //       );
        //     }
        //   },
        // ),
      ],
    );
  }
}