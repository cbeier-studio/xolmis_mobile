import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_background/flutter_background.dart';
import 'screens/home_screen.dart';
import 'screens/history_screen.dart';
import 'models/database_helper.dart';
import 'models/inventory.dart';
import 'providers/inventory_provider.dart';
import 'providers/species_provider.dart';
import 'providers/poi_provider.dart';
import 'providers/vegetation_provider.dart';
import 'providers/weather_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper().initDatabase();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
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
      ],
      child: MaterialApp(
        title: 'Xolmis',
        theme: ThemeData(
          primarySwatch: Colors.deepPurple,
        ),
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
    const HistoryScreen(),
  ];

  @override
  void initState() {
    super.initState();
    initializeBackgroundExecution();
    inventoryCountNotifier.updateCount();
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
        appBar: AppBar(
          title: const Text('Inventários'),
        ),
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
                    child: const Icon(Icons.home),
                  )
                      : const Icon(Icons.home);
                },
              ),
              label: 'Home',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.history),
              label: 'Histórico',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.amber[800],
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}