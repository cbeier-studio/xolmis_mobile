import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'home_screen.dart';
import 'history_screen.dart';
import 'database_helper.dart';
import 'inventory.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper().initDatabase();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Xolmis',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      home: const MainScreen(),
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
    inventoryCountNotifier.updateCount();
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
              icon: Consumer<InventoryCountNotifier>(
                builder: (context, inventoryCount, child) {
                  return inventoryCount.count > 0
                      ? Badge.count(
                    count: inventoryCount.count,
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