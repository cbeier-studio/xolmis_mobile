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
import 'screens/settings/settings_screen.dart';
import 'screens/statistics/statistics_screen.dart';

import 'core/core_consts.dart';
import 'generated/l10n.dart';

class MainScreen extends StatefulWidget {

  const MainScreen({
    super.key,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _NavigationItem {
  final String Function(BuildContext) labelBuilder;
  final IconData icon;
  final IconData selectedIcon;
  final Widget Function(BuildContext, GlobalKey<ScaffoldState>) screenBuilder;
  final int Function(BuildContext)? countSelector; // Optional: for badges
  final BadgeProviderType? badgeProviderType;

  _NavigationItem({
    required this.labelBuilder,
    required this.icon,
    required this.selectedIcon,
    required this.screenBuilder,
    this.countSelector,
    this.badgeProviderType,
  });
}

class _MainScreenState extends State<MainScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final List<_NavigationItem> _navItems;
  int _selectedIndex = 0;
  String _appVersion = '';

  @override
  void initState() {
    super.initState();

    // Initialize _navItems here if labels depend on S.of(context)
  // Or make labelBuilder accept S instance if _navItems is static/final top-level
  _navItems = [
    _NavigationItem(
      labelBuilder: (context) => S.of(context).inventories,
      icon: Icons.list_alt_outlined,
      selectedIcon: Icons.list_alt,
      screenBuilder: (context, scaffoldKey) => InventoriesScreen(scaffoldKey: scaffoldKey),
      // countSelector: (context) => Provider.of<InventoryProvider>(context, listen: false).inventoriesCount,
      badgeProviderType: BadgeProviderType.inventory,
    ),
    _NavigationItem(
      labelBuilder: (context) => S.of(context).nests,
      icon: Icons.egg_outlined,
      selectedIcon: Icons.egg,
      screenBuilder: (context, scaffoldKey) => NestsScreen(scaffoldKey: scaffoldKey),
      // countSelector: (context) => Provider.of<NestProvider>(context, listen: false).nestsCount,
      badgeProviderType: BadgeProviderType.nest,
    ),
    _NavigationItem(
      labelBuilder: (context) => S.of(context).specimens(2), // Assuming plural '2' is for general case
      icon: Icons.local_offer_outlined,
      selectedIcon: Icons.local_offer,
      screenBuilder: (context, scaffoldKey) => SpecimensScreen(scaffoldKey: scaffoldKey),
    ),
    _NavigationItem(
      labelBuilder: (context) => S.of(context).fieldJournal,
      icon: Icons.book_outlined,
      selectedIcon: Icons.book,
      screenBuilder: (context, scaffoldKey) => JournalsScreen(scaffoldKey: scaffoldKey),
    ),
    _NavigationItem(
      labelBuilder: (context) => S.of(context).statistics,
      icon: Icons.assessment_outlined,
      selectedIcon: Icons.assessment,
      screenBuilder: (context, scaffoldKey) => StatisticsScreen(scaffoldKey: scaffoldKey),
    ),
  ];

    scheduleKeepAwakeTask();
    _requestNotificationPermission();
    _fetchAppVersion();

    try {
    Provider.of<InventoryProvider>(context, listen: false).fetchInventories(context);
    Provider.of<NestProvider>(context, listen: false).fetchNests();
    Provider.of<SpecimenProvider>(context, listen: false).fetchSpecimens();
    Provider.of<FieldJournalProvider>(context, listen: false).fetchJournalEntries();
  } catch (e, s) {
    debugPrint("Error during initial provider fetch invocation: $e\n$s");
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) { // Ensure widget is still in the tree
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error during initial provider fetch invocation: $e\n$s")));
      }
    });
    debugPrint("Error fetching initial data: $e");
  }
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
        networkType: NetworkType.notRequired,
        requiresBatteryNotLow: false,
      ),
    );
  }

  Future<void> _requestNotificationPermission() async {
    final status = await Permission.notification.request();
    if (status.isGranted) {
    // Permission granted
    debugPrint("Notification permission granted.");
  } else if (status.isDenied) {
    // Permission denied
    // Optionally show a dialog explaining why the permission is useful
    debugPrint("Notification permission denied.");
  } else if (status.isPermanentlyDenied) {
    // Permission permanently denied
    // Guide user to app settings if they want to enable it later
    debugPrint("Notification permission permanently denied.");
    // Example: openAppSettings(); (from permission_handler)
  }
  }

  void _navigateToSettings(BuildContext context) {
  final screenWidth = MediaQuery.sizeOf(context).width;
  if (screenWidth > kTabletBreakpoint) { // Or a more specific breakpoint for SideSheet
    SideSheet.right(
      context: context,
      width: kSideSheetWidth,
      body: const SettingsScreen(),
    );
  } else {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }
}

  Future<void> _fetchAppVersion() async { 
    final packageInfo = await PackageInfo.fromPlatform(); 
    setState(() { 
      _appVersion = '${packageInfo.version}+${packageInfo.buildNumber}'; 
    }); 
  }

  Widget _buildBadgeWrapper(
    BuildContext context, {
    required Widget child,
    required BadgeProviderType? providerType,
    required bool isForIcon, // To adjust badge properties if needed
  }) {
    if (providerType == null) return child;

    switch (providerType) {
      case BadgeProviderType.inventory:
        return Selector<InventoryProvider, int>(
          selector: (_, provider) => provider.inventoriesCount,
          builder: (ctx, count, _) {
            return count > 0
                ? Badge.count(
                    count: count,
                    alignment: isForIcon ? AlignmentDirectional.topEnd : AlignmentDirectional.centerEnd,
                    offset: isForIcon ? null : const Offset(24, -8), // Specific offset for text labels
                    child: child)
                : child;
          },
        );
      case BadgeProviderType.nest:
        return Selector<NestProvider, int>(
          selector: (_, provider) => provider.nestsCount,
          builder: (ctx, count, _) {
            return count > 0
                ? Badge.count(
                    count: count,
                    alignment: isForIcon ? AlignmentDirectional.topEnd : AlignmentDirectional.centerEnd,
                    offset: isForIcon ? null : const Offset(24, -8),
                    child: child)
                : child;
          },
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final useSideNavRail = screenWidth >= kTabletBreakpoint && screenWidth < kDesktopBreakpoint;
    final useFixedNavDrawer = screenWidth >= kDesktopBreakpoint;

    // Generate NavigationRailDestinations
  List<NavigationRailDestination> railDestinations = _navItems.asMap().entries.map((entry) {
    int idx = entry.key;
    _NavigationItem item = entry.value;

    return NavigationRailDestination(
      icon: _buildBadgeWrapper(context,
          child: Icon(item.icon),
          providerType: item.badgeProviderType,
          isForIcon: true),
      selectedIcon: _buildBadgeWrapper(context,
          child: Icon(item.selectedIcon),
          providerType: item.badgeProviderType,
          isForIcon: true),
      label: Text(item.labelBuilder(context)),
    );
  }).toList();

      return Scaffold(
      key: _scaffoldKey,
      drawer: _buildNavigationDrawer(context),
        body: Row(
          children: [
            if (useSideNavRail || useFixedNavDrawer)
            NavigationRail(
              trailingAtBottom: true,
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Expanded(child: SizedBox.shrink()),
                  IconButton(
                    icon: Theme.of(context).brightness == Brightness.light
                        ? const Icon(Icons.settings_outlined)
                        : const Icon(Icons.settings),
                    onPressed: () => _navigateToSettings(context),
                  ),
                  // const SizedBox(height: 8),
                  // Text(S.current.settings),
                ],
              ),
              groupAlignment: 0.0,
              destinations: railDestinations,
              selectedIndex: _selectedIndex,
              labelType: NavigationRailLabelType.all,
              onDestinationSelected: (int index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
            ),
            Expanded(
              child: _navItems[_selectedIndex].screenBuilder.call(context, _scaffoldKey),
            ),
          ],
        ),
    );
  }

  NavigationDrawer _buildNavigationDrawer(BuildContext context) {
    final headerTextColor = Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white;
    final textTheme = Theme.of(context).textTheme;

    return NavigationDrawer(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (int index) {
        setState(() {
          _selectedIndex = index;
        });
        Navigator.pop(context);
      },
      header: DrawerHeader(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Xolmis', style: textTheme.headlineSmall?.copyWith(color: headerTextColor) ?? TextStyle(fontSize: 30, color: headerTextColor)),
            Text(_appVersion, style: textTheme.bodyMedium?.copyWith(color: headerTextColor) ?? TextStyle(color: headerTextColor)),
          ],
        ),
      ),
      footer: SafeArea(
        child: ListTile(
          leading: Theme.of(context).brightness == Brightness.light
          ? const Icon(Icons.settings_outlined)
          : const Icon(Icons.settings),
          title: Text(S.of(context).settings),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24.0),
          onTap: () => _navigateToSettings(context),
      ),
      ),
      children: <Widget>[
        // Generate NavigationDrawerDestinations from _navItems
      ..._navItems.asMap().entries.map((entry) {
        _NavigationItem item = entry.value;
        
        return NavigationDrawerDestination(
          icon: Icon(item.icon),
          selectedIcon: Icon(item.selectedIcon),
          label: _buildBadgeWrapper(context,
              child: Text(item.labelBuilder(context)),
              providerType: item.badgeProviderType,
              isForIcon: false),
        );
      }),      
      ],
    );
  }
}