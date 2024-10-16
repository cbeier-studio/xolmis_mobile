import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'database_helper.dart';
import 'inventory_provider.dart';
import 'home_screen.dart';
import 'history_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() =>_MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final List<Widget> _screens = [const HomeScreen(), const HistoryScreen()];

  void _navigateToScreen(int index) {
    setState(() {
      _currentIndex = index;
    });
    // Add transition animation logic here, if necessary
  }

  @override
  void initState() {
    super.initState();
    DatabaseHelper().initDatabase().then((_) {
      Provider.of<InventoryProvider>(context, listen: false).loadInventories();
    });
  }

  @override
  void dispose() {
    DatabaseHelper().closeDatabase();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => InventoryProvider(),
      child: Scaffold(
        body: _screens[_currentIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _navigateToScreen,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history),
              label: 'Histórico',
            ),
          ],
        ),
      ),
    );
  }
}