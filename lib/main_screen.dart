import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:side_sheet/side_sheet.dart';
import 'package:workmanager/workmanager.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'providers/inventory_provider.dart';
import 'providers/nest_provider.dart';
import 'providers/specimen_provider.dart';
import 'providers/journal_provider.dart';

import 'screens/inventory/inventories_screen.dart';
import 'screens/journal/journals_screen.dart';
import 'screens/nest/nests_screen.dart';
import 'screens/specimen/specimens_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/statistics_screen.dart';

import 'generated/l10n.dart';

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
  String _appVersion = '';

  static final List<Widget Function(BuildContext, GlobalKey<ScaffoldState>)> _widgetOptions = <Widget Function(BuildContext, GlobalKey<ScaffoldState>)>[
        (context, scaffoldKey) => InventoriesScreen(scaffoldKey: scaffoldKey),
        (context, scaffoldKey) => NestsScreen(scaffoldKey: scaffoldKey),
        (context, scaffoldKey) => SpecimensScreen(scaffoldKey: scaffoldKey),
        (context, scaffoldKey) => JournalsScreen(scaffoldKey: scaffoldKey),
        (context, scaffoldKey) => StatisticsScreen(scaffoldKey: scaffoldKey),
  ];

  @override
  void initState() {
    super.initState();
    scheduleKeepAwakeTask();
    _requestNotificationPermission();
    _fetchAppVersion();

    Provider.of<InventoryProvider>(context, listen: false).fetchInventories();
    Provider.of<NestProvider>(context, listen: false).fetchNests();
    Provider.of<SpecimenProvider>(context, listen: false).fetchSpecimens();
    Provider.of<FieldJournalProvider>(context, listen: false).fetchJournalEntries();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void scheduleKeepAwakeTask() {
    Workmanager().registerPeriodicTask(
      "keepAwakeTask", // Um identificador único para sua tarefa
      "wakeup", // O nome da tarefa. Deve coincidir com o nome no dispatcher
      frequency: Duration(minutes: 15), // Idealmente, ajuste isso para 15 minutos (mínimo)
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

  Future<void> _fetchAppVersion() async { 
    final packageInfo = await PackageInfo.fromPlatform(); 
    setState(() { 
      _appVersion = '${packageInfo.version}+${packageInfo.buildNumber}'; 
    }); 
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
        icon: const Icon(Icons.local_offer_outlined),
        selectedIcon: const Icon(Icons.local_offer),
        label: Text(S.of(context).specimens(2)),
      ),
      NavigationRailDestination(
        icon: const Icon(Icons.book_outlined),
        selectedIcon: const Icon(Icons.book),
        label: Text(S.of(context).fieldJournal),
      ),
      NavigationRailDestination(
        icon: const Icon(Icons.assessment_outlined),
        selectedIcon: const Icon(Icons.assessment),
        label: Text(S.of(context).statistics),
      ),
    ];

      return Scaffold(
      key: _scaffoldKey,
      // EXPERIMENTAL, not implemented
      // >> Use BottomNavigationBar to navigate between main features
      // bottomNavigationBar: (!useSideNavRail || !useFixedNavDrawer) ? BottomNavigationBar(
      //   type: BottomNavigationBarType.fixed,
      //   useLegacyColorScheme: false,
      //   selectedItemColor:  Theme.of(context).brightness == Brightness.light ? Colors.deepPurple : Colors.deepPurple[300],
      //   showSelectedLabels: true,
      //   showUnselectedLabels: true,
      //   items: <BottomNavigationBarItem>[
      //     BottomNavigationBarItem(
      //       icon: Icon(Icons.list_alt_outlined), 
      //       activeIcon: Icon(Icons.list_alt),
      //       label: S.current.inventories
      //     ),
      //     BottomNavigationBarItem(
      //       icon: Icon(Icons.egg_outlined), 
      //       activeIcon: Icon(Icons.egg),
      //       label: S.current.nests
      //     ),
      //     BottomNavigationBarItem(
      //       icon: Icon(Icons.local_offer_outlined), 
      //       activeIcon: Icon(Icons.local_offer),
      //       label: S.current.specimens(2)
      //     ),
      //     BottomNavigationBarItem(
      //       icon: Icon(Icons.book_outlined), 
      //       activeIcon: Icon(Icons.book),
      //       label: S.current.notes
      //     ),
      //   ],
      //   currentIndex: _selectedIndex,
      //   onTap: (index) {
      //     setState(() {
      //       _selectedIndex = index;
      //     });
      //   },
      // ) : null,
      drawer: _buildNavigationDrawer(context),
        body: Row(
          children: [
            if (useSideNavRail || useFixedNavDrawer)
            NavigationRail(
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Expanded(child: SizedBox.shrink()),
                  IconButton(
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
                          MaterialPageRoute(
                              builder: (context) => const SettingsScreen()),
                        );
                      }
                    },
                  ),
                ],
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
        UserAccountsDrawerHeader(
          accountName: Text('Xolmis', style: TextStyle(fontSize: 30, color: Brightness.dark == Theme.of(context).brightness ? Colors.black : Colors.white)), 
          accountEmail: Text(_appVersion, style: TextStyle(color: Brightness.dark == Theme.of(context).brightness ? Colors.black : Colors.white)),          
          otherAccountsPictures: [
            IconButton(
                icon: Theme.of(context).brightness == Brightness.light
                    ? const Icon(Icons.settings_outlined)
                    : const Icon(Icons.settings),
                tooltip: S.of(context).settings,
                color: Colors.white,
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
        NavigationDrawerDestination(
          icon: const Icon(Icons.book_outlined),
          label: Text(S.of(context).fieldJournal),
          selectedIcon: const Icon(Icons.book),
        ),
        NavigationDrawerDestination(
          icon: const Icon(Icons.assessment_outlined),
          label: Text(S.of(context).statistics),
          selectedIcon: const Icon(Icons.assessment),
        ),
      ],
    );
  }
}