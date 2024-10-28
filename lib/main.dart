import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'models/database_helper.dart';
import 'models/inventory.dart';

import 'providers/inventory_provider.dart';
import 'providers/species_provider.dart';
import 'providers/poi_provider.dart';
import 'providers/vegetation_provider.dart';
import 'providers/weather_provider.dart';
import 'providers/nest_provider.dart';
import 'providers/nest_revision_provider.dart';
import 'providers/egg_provider.dart';

import 'screens/home_screen.dart';
import 'screens/nests_screen.dart';
import 'screens/utils.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('assets/license.txt');
    yield LicenseEntryWithLineBreaks(['xolmis'], license);
  });
  await DatabaseHelper().initDatabase();
  final themeMode = await getThemeMode();
  runApp(MyApp(themeMode: themeMode));
}

class MyApp extends StatelessWidget {
  final ThemeMode themeMode;

  const MyApp({super.key, required this.themeMode});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => NestRevisionProvider()),
        ChangeNotifierProvider(create: (context) => EggProvider()),
        ChangeNotifierProvider(create: (context) => PoiProvider()),
        ChangeNotifierProvider(create: (context) => SpeciesProvider()),
        ChangeNotifierProvider(create: (context) => VegetationProvider()),
        ChangeNotifierProvider(create: (context) => WeatherProvider()),
        ChangeNotifierProvider(
          create: (context) => InventoryProvider(
            context.read<SpeciesProvider>(),
            context.read<VegetationProvider>(),
            context.read<WeatherProvider>(),
          ),
        ),
        ChangeNotifierProvider(create: (_) => NestProvider()),
      ],
      child: MaterialApp(
        title: 'Xolmis',
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        themeMode: themeMode,
        // theme: ThemeData(
        //   primarySwatch: Colors.deepPurple,
        // ),
        home: const MainScreen(),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final ValueNotifier<int> activeInventoriesCount = ValueNotifier<int>(0);
  final inventoryCountNotifier = InventoryCountNotifier();
  static final List<Widget> _widgetOptions = <Widget>[
    const HomeScreen(),
    const ActiveNestsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    initializeBackgroundExecution();
    inventoryCountNotifier.updateCount();
    Provider.of<NestProvider>(context, listen: false).fetchNests();
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

  Future<void> updateActiveInventoriesCount() async {
    final count = await DatabaseHelper().getActiveInventoriesCount();
    activeInventoriesCount.value = count;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: inventoryCountNotifier,
      child: Scaffold(
        // appBar: AppBar(
        //   title: const Text('Inventários'),
        // ),
        body: Center(
          child: _widgetOptions.elementAt(_selectedIndex),
        ),
        bottomNavigationBar: BottomNavigationBar(
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Consumer<InventoryProvider>(
                builder: (context, inventoryProvider, child) {
                  return inventoryProvider.inventoriesCount > 0 ? Badge.count(
                    count: inventoryProvider.inventoriesCount,
                    child: const Icon(Icons.list_alt),
                  )
                      : const Icon(Icons.list_alt);
                },
              ),
              label: 'Inventários',
            ),
            BottomNavigationBarItem(
              icon: Consumer<NestProvider>(
                builder: (context, nestProvider, child) {
                  return nestProvider.nestsCount > 0 ? Badge.count(
                    count: nestProvider.nestsCount,
                    child: const Icon(Icons.egg),
                  )
                      : const Icon(Icons.egg);
                },
              ),
              label: 'Ninhos',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.deepPurple,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}