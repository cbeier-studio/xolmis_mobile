import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:side_sheet/side_sheet.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'providers/inventory_provider.dart';
import 'providers/nest_provider.dart';
import 'providers/specimen_provider.dart';
import 'providers/journal_provider.dart';

import 'data/database/database_helper.dart';
import 'data/daos/inventory_dao.dart';
import 'data/daos/species_dao.dart';
import 'services/species_update_service.dart';

import 'main.dart';
import 'screens/inventory/inventories_screen.dart';
import 'screens/journal/journals_screen.dart';
import 'screens/nest/nests_screen.dart';
import 'screens/specimen/specimens_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/statistics/stats_screen.dart';

import 'core/core_consts.dart';
import 'generated/l10n.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _NavigationItem {
  final String Function(BuildContext) labelBuilder;
  final IconData icon;
  final IconData selectedIcon;
  final Widget Function(BuildContext, GlobalKey<ScaffoldState>) screenBuilder;
  // final int Function(BuildContext)? countSelector; // Optional: for badges
  final BadgeProviderType? badgeProviderType;

  _NavigationItem({
    required this.labelBuilder,
    required this.icon,
    required this.selectedIcon,
    required this.screenBuilder,
    // this.countSelector,
    this.badgeProviderType,
  });
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late final List<_NavigationItem> _navItems;
  int _selectedIndex = 0;
  String _appVersion = '';
  late InventoryProvider inventoryProvider;
  late InventoryDao inventoryDao;
  late SpeciesDao speciesDao;

  @override
  void initState() {
    super.initState();

    inventoryProvider = context.read<InventoryProvider>();
    inventoryDao = context.read<InventoryDao>();
    speciesDao = context.read<SpeciesDao>();

    // Register the observer to listen to changes in the app state
    WidgetsBinding.instance.addObserver(this);
    debugPrint('[MAIN_SCREEN] initState: WidgetsBindingObserver registered.');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('[MAIN_SCREEN] initState: addPostFrameCallback triggered. Scheduling _resumeAllActiveTimers.');
      Future.delayed(Duration.zero, ()
      {
        // Synchronize and restart the timers when start the screen
        _resumeAllActiveTimers();
      });
    });

    // Initialize _navItems here if labels depend on S.of(context)
    // Or make labelBuilder accept S instance if _navItems is static/final top-level
    _navItems = [
      _NavigationItem(
        labelBuilder: (context) => S.of(context).inventories,
        icon: Icons.list_alt_outlined,
        selectedIcon: Icons.list_alt,
        screenBuilder:
            (context, scaffoldKey) =>
                InventoriesScreen(scaffoldKey: scaffoldKey),
        // countSelector: (context) => Provider.of<InventoryProvider>(context, listen: false).inventoriesCount,
        badgeProviderType: BadgeProviderType.inventory,
      ),
      _NavigationItem(
        labelBuilder: (context) => S.of(context).nests,
        icon: Icons.egg_outlined,
        selectedIcon: Icons.egg,
        screenBuilder:
            (context, scaffoldKey) => NestsScreen(scaffoldKey: scaffoldKey),
        // countSelector: (context) => Provider.of<NestProvider>(context, listen: false).nestsCount,
        badgeProviderType: BadgeProviderType.nest,
      ),
      _NavigationItem(
        labelBuilder:
            (context) => S
                .of(context)
                .specimens(2), // Assuming plural '2' is for general case
        icon: Icons.local_offer_outlined,
        selectedIcon: Icons.local_offer,
        screenBuilder:
            (context, scaffoldKey) => SpecimensScreen(scaffoldKey: scaffoldKey),
      ),
      _NavigationItem(
        labelBuilder: (context) => S.of(context).fieldJournal,
        icon: Icons.book_outlined,
        selectedIcon: Icons.book,
        screenBuilder:
            (context, scaffoldKey) => JournalsScreen(scaffoldKey: scaffoldKey),
      ),
      _NavigationItem(
        labelBuilder: (context) => S.of(context).statistics,
        icon: Icons.assessment_outlined,
        selectedIcon: Icons.assessment,
        screenBuilder:
            (context, scaffoldKey) =>
                StatsScreen(scaffoldKey: scaffoldKey),
      ),
    ];

    _initializeApp();
  }

  void _initializeApp() async {
    _requestNotificationPermission();
    _fetchAppVersion();

    await _checkForSpeciesUpdate();

    try {
      // Provider.of<InventoryProvider>(
      //   context,
      //   listen: false,
      // ).fetchInventories(context);
      Provider.of<NestProvider>(context, listen: false).fetchNests();
      Provider.of<SpecimenProvider>(context, listen: false).fetchSpecimens();
      Provider.of<FieldJournalProvider>(
        context,
        listen: false,
      ).fetchJournalEntries();
    } catch (e, s) {
      debugPrint("Error during initial provider fetch invocation: $e\n$s");
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          // Ensure widget is still in the tree
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              persist: true,
              showCloseIcon: true,
              backgroundColor: Theme.of(context).colorScheme.error,
              content: Text(
                "Error during initial provider fetch invocation: $e\n$s",
              ),
            ),
          );
        }
      });
      debugPrint("Error fetching initial data: $e");
    }
  }

  @override
  void dispose() {
    // Remove the observer to avoid memory leaks
    debugPrint('[MAIN_SCREEN] dispose: InventoriesScreen is being disposed.');
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Method to handle changes in app state
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    debugPrint('[MAIN_SCREEN] App Lifecycle Changed: $state');
    // If the app was resumed (came back to foreground)
    if (state == AppLifecycleState.resumed) {
      // Synchronize and restart all active timers
      debugPrint('[MAIN_SCREEN] App Resumed! Triggering _resumeAllActiveTimers...');
      _resumeAllActiveTimers();
    }
  }

  // Function to synchronize and restart the timers
  void _resumeAllActiveTimers() async {
    if (!mounted) {
      debugPrint('[RESUME_LOGIC] _resumeAllActiveTimers ABORTED: Screen not mounted.');
      return;
    }
    debugPrint('[RESUME_LOGIC] ----------------------------------');
    debugPrint('[RESUME_LOGIC] Starting _resumeAllActiveTimers...');

    // 1. BUSCA os dados do banco de dados primeiro.
    debugPrint('[RESUME_LOGIC] Step 1: Calling fetchInventories...');
    await inventoryProvider.fetchInventories(context);
    debugPrint('[RESUME_LOGIC] ...Step 1 Complete: fetchInventories finished.');

    debugPrint('[RESUME_LOGIC] Step 2: Starting loop through ${inventoryProvider.activeInventories.length} active inventories to recalculate state.');
    for (var inventory in inventoryProvider.activeInventories) {
      debugPrint('[RESUME_LOGIC]  -> Processing inventory: ${inventory.id}');
      // Ignore if the inventory is paused or finished
      if (inventory.isPaused || inventory.isFinished) {
        debugPrint('[RESUME_LOGIC]  -> SKIPPED ${inventory.id}: isPaused=${inventory.isPaused}, isFinished=${inventory.isFinished}');
        continue;
      }

      if (inventory.startTime == null) {
        debugPrint('[RESUME_LOGIC]  -> SKIPPED ${inventory.id}: startTime is null.');
        continue;
      }

      final netActiveTimeInSeconds = DateTime.now().difference(inventory.startTime!).inSeconds.toDouble()
          - inventory.totalPausedTimeInSeconds;

      // Logic for inventories with intervals (invIntervalQualitative)
      if (inventory.type == InventoryType.invIntervalQualitative) {
        // Ensures that the duration and start time of inventory exist to calculate
        if (inventory.duration > 0 && inventory.startTime != null) {
          // final now = DateTime.now();

          // 1. Calculate the total elapsed time since the start of the inventory.
          // final totalElapsedTimeInSeconds = now.difference(inventory.startTime!).inSeconds.toDouble();
          final intervalDurationInSeconds = (inventory.duration * 60).toDouble();

          // 2. Determine in which interval the inventory should be now.
          final preciseCurrentInterval = (netActiveTimeInSeconds / intervalDurationInSeconds).floor() + 1;

          // 3. Calculate the elapsed time of the CURRENT interval.
          final timeOfCompletedIntervals = (preciseCurrentInterval - 1) * intervalDurationInSeconds;
          final elapsedTimeOfCurrentInterval = netActiveTimeInSeconds - timeOfCompletedIntervals;

          // 4. Find the date/time of last added species in the inventory.
          int recalculatedSpeciesCount = 0;
          int preciseIntervalsWithoutNewSpecies = 0;

          final lastSpeciesTime = await speciesDao.getLastSpeciesTimeByInventory(inventory.id);

          if (lastSpeciesTime != null) {
            // Calcula o tempo líquido ATÉ a última espécie
            // (Esta aproximação é geralmente suficiente)
            final grossSecondsToLastSpecies = lastSpeciesTime.difference(inventory.startTime!).inSeconds;
            final netSecondsToLastSpecies = grossSecondsToLastSpecies - inventory.totalPausedTimeInSeconds;

            // Calcula em qual intervalo a última espécie foi registrada
            final intervalOfLastSpecies = (netSecondsToLastSpecies / intervalDurationInSeconds).floor() + 1;

            if (intervalOfLastSpecies == preciseCurrentInterval) {
              // Se a última espécie foi neste intervalo, sabemos que o contador de espécies é >= 1.
              // Não precisamos saber o número exato, apenas que não é zero.
              recalculatedSpeciesCount = 1;
              // Como uma espécie foi adicionada no intervalo atual, o contador de intervalos
              // sem espécies novas é, por definição, 0.
              preciseIntervalsWithoutNewSpecies = 0;
            } else {
              // A última espécie foi em um intervalo anterior.
              // O contador para o intervalo ATUAL é 0.
              recalculatedSpeciesCount = 0;
              // A sua fórmula brilhante para calcular os intervalos completos que se passaram.
              preciseIntervalsWithoutNewSpecies = preciseCurrentInterval - intervalOfLastSpecies - 1;
            }
          } else {
            // No species have been added yet.
            recalculatedSpeciesCount = 0;
            // All finished intervals up to now have had no species.
            preciseIntervalsWithoutNewSpecies = preciseCurrentInterval - 1;
          }

          // Garante que o contador nunca seja negativo
          preciseIntervalsWithoutNewSpecies = preciseIntervalsWithoutNewSpecies < 0 ? 0 : preciseIntervalsWithoutNewSpecies;

          // 8. Update the complete state of inventory with recalculated values.
          inventory.updateCurrentInterval(preciseCurrentInterval);
          inventory.updateElapsedTime(elapsedTimeOfCurrentInterval);
          inventory.updateIntervalsWithoutNewSpecies(preciseIntervalsWithoutNewSpecies);
          inventory.currentIntervalSpeciesCount = recalculatedSpeciesCount;
          debugPrint('[RESUME_LOGIC]  -> Recalculated state for ${inventory.id}: elapsedTime=${inventory.elapsedTime.toStringAsFixed(2)}, currentInterval=${inventory.currentInterval}, intervalsWithoutNewSpecies=${inventory.intervalsWithoutNewSpecies}');

          // Checks if the finishing condition was reached while the app was in background
          if (inventory.intervalsWithoutNewSpecies >= 3) {
            debugPrint('[RESUME_LOGIC] !!! FINISH CONDITION MET for ${inventory.id} during resume. intervalsWithoutNewSpecies is ${inventory.intervalsWithoutNewSpecies}.');
            await inventory.stopTimer(context, inventoryDao);
            await inventory.showNotification(flutterLocalNotificationsPlugin);
            // final completionService = InventoryCompletionService(
            //   context: context,
            //   inventory: inventory,
            //   inventoryProvider: inventoryProvider,
            //   inventoryDao: inventoryDao,
            // );
            // await completionService.attemptFinishInventory(context);
            debugPrint('[RESUME_LOGIC]  -> Inventory ${inventory.id} finished by completion service.');
            continue;
          }
        }

        // Restart the Stream.periodic for the UI
        inventoryProvider.startInventoryTimer(context, inventory, inventoryDao);

        // Logic for other inventories with duration (timer)
      } else if (inventory.duration > 0) {

        // Update the notifier of total elapsed time
        inventory.updateElapsedTime(netActiveTimeInSeconds);
        debugPrint('[RESUME_LOGIC]  -> Recalculated state for ${inventory.id}: elapsedTime=${inventory.elapsedTime.toStringAsFixed(2)}, currentInterval=${inventory.currentInterval}, intervalsWithoutNewSpecies=${inventory.intervalsWithoutNewSpecies}');

        // Checks if the finishing condition was reached while the app was in background
        if (inventory.elapsedTime >= (inventory.duration * 60)) {
          debugPrint('[RESUME_LOGIC] !!! FINISH CONDITION MET for ${inventory.id} during resume. elapsedTime is ${inventory.elapsedTime / 60} minutes.');
          await inventory.stopTimer(context, inventoryDao);
          await inventory.showNotification(flutterLocalNotificationsPlugin);
          // final completionService = InventoryCompletionService(
          //   context: context,
          //   inventory: inventory,
          //   inventoryProvider: inventoryProvider,
          //   inventoryDao: inventoryDao,
          // );
          // await completionService.attemptFinishInventory(context);
          debugPrint('[RESUME_LOGIC]  -> Inventory ${inventory.id} finished by completion service.');
          continue;
        }

        // Restart the Stream.periodic for the UI
        inventoryProvider.startInventoryTimer(context, inventory, inventoryDao);
      }
    }

    // Force the UI to rebuild
    if (mounted) {
      debugPrint('[RESUME_LOGIC] Step 3: Recalculation loop finished. Calling setState() to rebuild UI.');
      setState(() {});
    }
    debugPrint('[RESUME_LOGIC] _resumeAllActiveTimers finished.');
    debugPrint('[RESUME_LOGIC] ----------------------------------');
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
    if (screenWidth > kTabletBreakpoint) {
      // Or a more specific breakpoint for SideSheet
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
                  alignment:
                      isForIcon
                          ? AlignmentDirectional.topEnd
                          : AlignmentDirectional.centerEnd,
                  offset:
                      isForIcon
                          ? null
                          : const Offset(
                            24,
                            -8,
                          ), // Specific offset for text labels
                  child: child,
                )
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
                  alignment:
                      isForIcon
                          ? AlignmentDirectional.topEnd
                          : AlignmentDirectional.centerEnd,
                  offset: isForIcon ? null : const Offset(24, -8),
                  child: child,
                )
                : child;
          },
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final useSideNavRail = screenWidth >= kDesktopBreakpoint;
    final useFixedNavDrawer = screenWidth >= kDesktopBreakpoint;

    // Generate NavigationRailDestinations
    List<NavigationRailDestination> railDestinations =
        _navItems.asMap().entries.map((entry) {
          // int idx = entry.key;
          _NavigationItem item = entry.value;

          return NavigationRailDestination(
            icon: _buildBadgeWrapper(
              context,
              child: Icon(item.icon),
              providerType: item.badgeProviderType,
              isForIcon: true,
            ),
            selectedIcon: _buildBadgeWrapper(
              context,
              child: Icon(item.selectedIcon),
              providerType: item.badgeProviderType,
              isForIcon: true,
            ),
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
              scrollable: true,
              trailingAtBottom: true,
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Expanded(child: SizedBox.shrink()),
                  IconButton(
                    icon:
                        Theme.of(context).brightness == Brightness.light
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
          if (useSideNavRail || useFixedNavDrawer)
            VerticalDivider(),
          Expanded(
            child: _navItems[_selectedIndex].screenBuilder.call(
              context,
              _scaffoldKey,
            ),
          ),
        ],
      ),
    );
  }

  NavigationDrawer _buildNavigationDrawer(BuildContext context) {
    final headerTextColor =
        Theme.of(context).brightness == Brightness.dark
            ? Colors.black
            : Colors.white;
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
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Xolmis',
              style:
                  textTheme.headlineSmall?.copyWith(color: headerTextColor) ??
                  TextStyle(fontSize: 30, color: headerTextColor),
            ),
            Text(
              _appVersion,
              style:
                  textTheme.bodyMedium?.copyWith(color: headerTextColor) ??
                  TextStyle(color: headerTextColor),
            ),
          ],
        ),
      ),
      footer: SafeArea(
        child: ListTile(
          leading:
              Theme.of(context).brightness == Brightness.light
                  ? const Icon(Icons.settings_outlined)
                  : const Icon(Icons.settings),
          title: Text(S.of(context).settings,
              style: textTheme.bodyMedium),
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
            label: _buildBadgeWrapper(
              context,
              child: Text(item.labelBuilder(context)),
              providerType: item.badgeProviderType,
              isForIcon: false,
            ),
          );
        }),
      ],
    );
  }

  /// Verifica se uma atualização de nomenclatura de espécies é necessária e a executa.
  Future<void> _checkForSpeciesUpdate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Lê o ano da última atualização. O padrão é 0 para garantir que a primeira verificação sempre ocorra.
      final lastUpdateVersion = prefs.getInt('speciesUpdateVersion') ?? 0;

      if (lastUpdateVersion < kCurrentSpeciesUpdateVersion) {
        debugPrint(
            'Iniciando atualização de espécies: da versão $lastUpdateVersion para $kCurrentSpeciesUpdateVersion');

        // Injeta a instância do DatabaseHelper no serviço
        final speciesUpdater =
        SpeciesUpdateService(dbHelper: DatabaseHelper.instance);

        // Executa a atualização para o ano definido na constante
        final summary =
        await speciesUpdater.applySpeciesUpdates(kCurrentSpeciesUpdateVersion);

        // Se a atualização foi bem-sucedida (não lançou exceção), grava a nova versão.
        await prefs.setInt(
            'speciesUpdateVersion', kCurrentSpeciesUpdateVersion);

        debugPrint('Atualização de espécies para o ano $kCurrentSpeciesUpdateVersion concluída com sucesso.');
        debugPrint(summary.toString());
      } else {
        debugPrint(
            'Nenhuma atualização de espécies necessária. Versão atual: $lastUpdateVersion');
      }
    } catch (e, s) {
      // Se a atualização falhar, a versão não é gravada, e a tentativa ocorrerá na próxima inicialização.
      debugPrint('Falha crítica durante a verificação de atualização de espécies: $e\n$s');
      // Opcional: mostrar uma notificação de erro para o usuário se a falha for crítica
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            persist: true,
            showCloseIcon: true,
            content: Text(S.of(context).speciesUpgradeFailed),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}
