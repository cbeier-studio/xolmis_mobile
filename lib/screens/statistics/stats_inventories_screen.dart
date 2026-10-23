import 'package:fl_chart/fl_chart.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/core_consts.dart';
import '../../data/models/inventory.dart';
import '../../generated/l10n.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/poi_provider.dart';
import '../../providers/species_provider.dart';
import '../../widgets/scrollable_chart_indicator.dart';
import '../../utils/statistics_logic.dart';
import '../../utils/themes.dart';
import '../../utils/utils.dart';
import 'inventory_report_screen.dart';

/// Loader screen that fetches full details for a list of inventory IDs before displaying [StatsInventoriesScreen].
class StatsInventoriesLoadingScreen extends StatefulWidget {
  final List<String> inventoryIds;

  const StatsInventoriesLoadingScreen({super.key, required this.inventoryIds});

  @override
  State<StatsInventoriesLoadingScreen> createState() => _StatsInventoriesLoadingScreenState();
}

class _StatsInventoriesLoadingScreenState extends State<StatsInventoriesLoadingScreen> {
  late final Future<List<Inventory>> _future;

  @override
  void initState() {
    super.initState();
    _future = Provider.of<InventoryProvider>(context, listen: false)
        .loadInventoriesDetails(widget.inventoryIds);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Inventory>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
          return StatsInventoriesScreen(
            inventories: snapshot.data ?? [],
          );
        } else if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: Text(S.of(context).statistics)),
            body: Center(
              child: Text('Error: ${snapshot.error}'),
            ),
          );
        } else {
          return Scaffold(
            appBar: AppBar(title: Text(S.of(context).statistics)),
            body: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
      },
    );
  }
}

/// Statistics screen focused on a selected set of inventories.
class StatsInventoriesScreen extends StatefulWidget {
  final List<Inventory> inventories;

  const StatsInventoriesScreen({super.key, required this.inventories});

  @override
  StatsInventoriesScreenState createState() => StatsInventoriesScreenState();
}

/// Computes and displays inventory-specific indicators and charts.
class StatsInventoriesScreenState extends State<StatsInventoriesScreen> {
  late InventoryProvider inventoryProvider;
  late SpeciesProvider speciesProvider;
  late PoiProvider poiProvider;
  late List<Inventory> _sortedInventories;
  late List<FlSpot> accumulatedSpeciesData = [];
  late List<FlSpot> accumulatedSpeciesWithinSampleData = [];
  late List<String> combinedSpeciesList = [];
  late double averageSpeciesCount = 0;
  late int distinctLocalitiesCount = 0;
  late Map<int, int> recordsPerHour = {};
  late List<String> sharedSpeciesAcrossAll = [];
  late int sharedSpeciesAcrossAllCount = 0;
  late Map<String, List<String>> sharedSpeciesByPair = {};
  late Map<String, List<String>> exclusiveSpeciesByInventory = {};
  late int exclusiveSpeciesCount = 0;
  late List<FlSpot> sampledSpots = [const FlSpot(0, 0)];
  late List<FlSpot> expectedSpots = [const FlSpot(0, 0)];
  late double maxRichness = 1;

  @override
  void initState() {
    super.initState();
    inventoryProvider = Provider.of<InventoryProvider>(context, listen: false);
    speciesProvider = Provider.of<SpeciesProvider>(context, listen: false);
    poiProvider = Provider.of<PoiProvider>(context, listen: false);
    _sortedInventories = _getSortedInventories(widget.inventories);
    _loadData();
  }

  @override
  void didUpdateWidget(covariant StatsInventoriesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.inventories, widget.inventories)) {
      _sortedInventories = _getSortedInventories(widget.inventories);
      _loadData();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  List<Inventory> _getSortedInventories(List<Inventory> inventories) {
    final sorted = List<Inventory>.from(inventories);
    sorted.sort((a, b) {
      final aDate = a.startTime ?? a.endTime;
      final bDate = b.startTime ?? b.endTime;

      if (aDate == null && bDate == null) {
        return a.id.compareTo(b.id);
      }
      if (aDate == null) {
        return 1;
      }
      if (bDate == null) {
        return -1;
      }

      final byDate = aDate.compareTo(bDate);
      if (byDate != 0) {
        return byDate;
      }
      return a.id.compareTo(b.id);
    });
    return sorted;
  }

  /// Loads precomputed metrics and chart datasets for inventories.
  Future<void> _loadData() async {
    accumulatedSpeciesData = prepareAccumulatedSpeciesData(_sortedInventories);
    accumulatedSpeciesWithinSampleData = prepareAccumulatedSpeciesWithinSample(_sortedInventories);
    combinedSpeciesList = _getSpeciesList(_sortedInventories);
    sharedSpeciesAcrossAll = _getSharedSpeciesAcrossAll(_sortedInventories);
    sharedSpeciesAcrossAllCount = sharedSpeciesAcrossAll.length;
    sharedSpeciesByPair = _getSharedSpeciesByPair(_sortedInventories);
    exclusiveSpeciesByInventory = _getExclusiveSpeciesByInventory(_sortedInventories);
    exclusiveSpeciesCount = exclusiveSpeciesByInventory.values.fold<int>(
      0,
      (sum, species) => sum + species.length,
    );
    if (_sortedInventories.isNotEmpty) {
      int totalRichnessSum = _sortedInventories.fold(0, (sum, inv) {
        final count = _getSpeciesRichnessForInventory(inv);
        return sum + count;
      });

      averageSpeciesCount = totalRichnessSum / _sortedInventories.length;
    } else {
      averageSpeciesCount = 0;
    }

    final allLocalities = _sortedInventories.map((inventory) => inventory.localityName).toList();
    final distinctLocalities = allLocalities.toSet();
    distinctLocalitiesCount = distinctLocalities.length;

    recordsPerHour = _getOccurrencesByHourOfDayWithFallback(_sortedInventories);

    final rarefaction = prepareRarefactionCurveSpots(_sortedInventories);
    sampledSpots = rarefaction.sampled;
    expectedSpots = rarefaction.expected;
    maxRichness = [
      ...sampledSpots.map((spot) => spot.y),
      ...expectedSpots.map((spot) => spot.y),
    ].fold<double>(1.0, (max, value) => value > max ? value : max);
  }

  bool _isDetectionInventory(Inventory inventory) {
    return inventory.type == InventoryType.invTransectDetection ||
        inventory.type == InventoryType.invPointDetection;
  }

  /// Detection inventories can contain repeated rows for the same species, so
  /// richness must be based on distinct names.
  int _getSpeciesRichnessForInventory(Inventory inventory) {
    if (_isDetectionInventory(inventory)) {
      return inventory.speciesList.map((s) => s.name).toSet().length;
    }
    if (inventory.speciesCount > 0) {
      return inventory.speciesCount;
    }
    return inventory.speciesList.length;
  }

  // Uses species.sampleTime when available, otherwise falls back to inventory.startTime.
  /// Builds hourly occurrence counts using species time or inventory start time.
  Map<int, int> _getOccurrencesByHourOfDayWithFallback(
    List<Inventory> inventories,
  ) {
    final Map<int, int> occurrences = {for (var i = 0; i < 24; i++) i: 0};

    for (final inventory in inventories) {
      for (final species in inventory.speciesList) {
        final DateTime? recordTime = species.sampleTime ?? inventory.startTime;
        if (recordTime != null) {
          final hour = recordTime.hour;
          occurrences[hour] = (occurrences[hour] ?? 0) + 1;
        }
      }
    }

    return occurrences;
  }

  /// Returns a chart width that adapts to the number of inventories.
  double _responsiveChartWidth(
    double availableWidth, {
    required double pixelsPerInventory,
  }) {
    final calculatedWidth = _sortedInventories.length * pixelsPerInventory;
    return calculatedWidth > availableWidth ? calculatedWidth : availableWidth;
  }

  List<String> _getSpeciesList(List<Inventory> inventories) {
    final speciesSet = <String>{};
    for (final inventory in inventories) {
      for (final species in inventory.speciesList) {
        speciesSet.add(species.name);
      }
    }
    return speciesSet.toList()..sort();
  }

  Set<String> _getSpeciesSetForInventory(Inventory inventory) {
    return inventory.speciesList.map((species) => species.name).toSet();
  }

  List<String> _sortedSpeciesList(Iterable<String> species) {
    final list = species.toList();
    list.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return list;
  }

  List<String> _getSharedSpeciesAcrossAll(List<Inventory> inventories) {
    if (inventories.isEmpty) {
      return [];
    }

    final shared = Set<String>.from(_getSpeciesSetForInventory(inventories.first));
    for (final inventory in inventories.skip(1)) {
      shared.retainAll(_getSpeciesSetForInventory(inventory));
    }

    return _sortedSpeciesList(shared);
  }

  Map<String, List<String>> _getSharedSpeciesByPair(List<Inventory> inventories) {
    final result = <String, List<String>>{};
    final sets = inventories.map(_getSpeciesSetForInventory).toList();

    for (var i = 0; i < inventories.length; i++) {
      for (var j = i + 1; j < inventories.length; j++) {
        final pairShared = sets[i].intersection(sets[j]);
        final pairLabel = '${inventories[i].id} × ${inventories[j].id}';
        result[pairLabel] = _sortedSpeciesList(pairShared);
      }
    }

    return result;
  }

  Map<String, List<String>> _getExclusiveSpeciesByInventory(List<Inventory> inventories) {
    final sets = inventories.map(_getSpeciesSetForInventory).toList();
    final occurrences = <String, int>{};

    for (final speciesSet in sets) {
      for (final species in speciesSet) {
        occurrences[species] = (occurrences[species] ?? 0) + 1;
      }
    }

    final result = <String, List<String>>{};
    for (var i = 0; i < inventories.length; i++) {
      final inventory = inventories[i];
      final exclusiveSpecies = sets[i].where((species) => occurrences[species] == 1);
      result[inventory.id] = _sortedSpeciesList(exclusiveSpecies);
    }

    return result;
  }

  List<BarChartGroupData> _createBarGroupsFromOccurrencesMap(
    Map<int, int> hourlyOccurrences,
    double barWidth,
  ) {
    final List<BarChartGroupData> barGroups = [];
    hourlyOccurrences.forEach((hour, count) {
      barGroups.add(
        BarChartGroupData(
          x: hour,
          barRods: [
            BarChartRodData(
              toY: count.toDouble(),
              color: XolmisColors.jacarandaCore,
              width: barWidth,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
            ),
          ],
        ),
      );
    });
    return barGroups;
  }

  Widget _buildSpeciesListSection({
    required String title,
    required List<String> species,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : XolmisColors.surfaceVariant.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : XolmisColors.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          if (species.length > 0) ...[
          const SizedBox(width: 8),
          Badge(
            backgroundColor: XolmisColors.primary,
              textColor: XolmisColors.onPrimary,
              label: Text(species.length.toString())),
    ],
          ],
          ),
          const SizedBox(height: 8),
          if (species.isEmpty)
            Text(
              '-',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
              ),
            )
          else
            ...species.map(
              (speciesName) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  speciesName,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey.shade200 : Colors.black87,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSpeciesDialogContent({
    required List<Widget> sections,
  }) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: sections,
      ),
    );
  }

  Future<void> _showSharedSpeciesDialog(BuildContext context, bool isDark) async {
    final sharedAcrossAll = sharedSpeciesAcrossAll;
    final sharedSections = <Widget>[
      _buildSpeciesListSection(
        title: '${S.of(context).sharedSpeciesAcrossAllSelected}',
        species: sharedAcrossAll,
        isDark: isDark,
      ),
      const SizedBox(height: 16),
      Text(
        S.of(context).sharedSpeciesByPair,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      const SizedBox(height: 10),
      if (sharedSpeciesByPair.isEmpty)
        Text(
          '-',
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
          ),
        )
      else
        ...sharedSpeciesByPair.entries.expand(
          (entry) => [
            _buildSpeciesListSection(
              title: '${entry.key}',
              species: entry.value,
              isDark: isDark,
            ),
            const SizedBox(height: 10),
          ],
        ),
    ];

    final isSmallScreen = MediaQuery.of(context).size.shortestSide < 600;

    if (isSmallScreen) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return Dialog.fullscreen(
            child: Scaffold(
              appBar: AppBar(
                title: Text(S.of(dialogContext).sharedSpecies),
              ),
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: _buildSpeciesDialogContent(sections: sharedSections),
              ),
            ),
          );
        },
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(S.of(dialogContext).sharedSpecies),
          content: SizedBox(
            width: 520,
            height: 520,
            child: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: _buildSpeciesDialogContent(sections: sharedSections),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(MaterialLocalizations.of(dialogContext).closeButtonLabel),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showExclusiveSpeciesDialog(BuildContext context, bool isDark) async {
    final exclusiveSections = <Widget>[
      Text(
        S.of(context).exclusiveSpeciesByInventory,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      const SizedBox(height: 10),
      if (_sortedInventories.isEmpty)
        Text(
          '-',
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
          ),
        )
      else
        ..._sortedInventories.asMap().entries.expand(
          (entry) => [
            _buildSpeciesListSection(
              title: '${entry.value.id}',
              species: exclusiveSpeciesByInventory[entry.value.id] ?? const <String>[],
              isDark: isDark,
            ),
            const SizedBox(height: 10),
          ],
        ),
    ];

    final isSmallScreen = MediaQuery.of(context).size.shortestSide < 600;

    if (isSmallScreen) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return Dialog.fullscreen(
            child: Scaffold(
              appBar: AppBar(
                title: Text(S.of(dialogContext).exclusiveSpecies),
              ),
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: _buildSpeciesDialogContent(sections: exclusiveSections),
              ),
            ),
          );
        },
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(S.of(dialogContext).exclusiveSpecies),
          content: SizedBox(
            width: 520,
            height: 520,
            child: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: _buildSpeciesDialogContent(sections: exclusiveSections),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(MaterialLocalizations.of(dialogContext).closeButtonLabel),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
          title: Text(S.of(context).statistics),
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.print_outlined),
        //     onPressed: () {
        //       Navigator.push(
        //         context,
        //         MaterialPageRoute(
        //           builder: (context) => InventoryPdfReportPreviewScreen(
        //             inventories: widget.inventories,
        //           ),
        //         ),
        //       );
        //     },
        //   ),
        // ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildKpiMetricsGrid(isDark),
                const SizedBox(height: 16),

                _buildAccumulationCurveCard(context, isDark),
                const SizedBox(height: 16),

                _buildHourlyRecordsCard(isDark),
                const SizedBox(height: 16),

                _buildRichnessPerInventoryCard(isDark),
                const SizedBox(height: 16),

                _buildConservationStatusCard(isDark),
                const SizedBox(height: 16),

                _buildBiodiversityIndicesCard(context, isDark),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
    );
  }

  Widget _buildKpiMetricsGrid(bool isDark) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      mainAxisExtent: 118,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildKpiTile(
          label: S.of(context).selectedInventories,
          value: '${_sortedInventories.length}',
          // subtext: '',
          valueColor: XolmisColors.primary,
          isDark: isDark,
        ),
        _buildKpiTile(
          label: S.of(context).localitiesSurveyed(distinctLocalitiesCount),
          value: '${distinctLocalitiesCount}',
          // subtext: '',
          valueColor: XolmisColors.primary,
          isDark: isDark,
        ),
        _buildKpiTile(
          label: S.of(context).totalRichness,
          value: '${combinedSpeciesList.length}',
          // subtext: '',
          valueColor: XolmisColors.primary,
          isDark: isDark,
        ),
        _buildKpiTile(
          label: S.of(context).averageRichness,
          value: averageSpeciesCount.toStringAsFixed(1),
          // subtext: '',
          valueColor: XolmisColors.primary,
          isDark: isDark,
        ),
        _buildKpiTile(
          label: S.of(context).sharedSpecies.toLowerCase(),
          value: '$sharedSpeciesAcrossAllCount',
          valueColor: XolmisColors.primary,
          isDark: isDark,
          actionLabel: S.of(context).details,
          onPressed: () => _showSharedSpeciesDialog(context, isDark),
        ),
        _buildKpiTile(
          label: S.of(context).exclusiveSpecies.toLowerCase(),
          value: '$exclusiveSpeciesCount',
          valueColor: XolmisColors.primary,
          isDark: isDark,
          actionLabel: S.of(context).details,
          onPressed: () => _showExclusiveSpeciesDialog(context, isDark),
        ),
      ],
    );
  }

  Widget _buildKpiTile({
    required String label,
    required String value,
    // required String subtext,
    required Color valueColor,
    required bool isDark,
    String? actionLabel,
    VoidCallback? onPressed,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.grey.shade900.withValues(alpha: 0.6)
            : XolmisColors.secondaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : XolmisColors.borderSubtle,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: Theme.of(context).textTheme.headlineSmall?.fontSize,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey.shade400 : XolmisColors.secondary,
            ),
          ),
          if (actionLabel != null && onPressed != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 28,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  // padding: const EdgeInsets.symmetric(vertical: 4),
                  backgroundColor: isDark
                      ? XolmisColors.primary.withValues(alpha: 0.15)
                      : XolmisColors.primaryContainer.withValues(alpha: 0.5),
                  side: BorderSide(
                    color: isDark
                        ? Colors.grey.shade800
                        : XolmisColors.outlineVariant.withValues(alpha: 0.5),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: onPressed,
                child: Text(
                  actionLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? XolmisColors.primaryContainer
                        : XolmisColors.onPrimaryContainer,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAccumulationCurveCard(BuildContext context, bool isDark) {
    final accumulationMaxY = [
      ...accumulatedSpeciesData.map((spot) => spot.y),
      ...accumulatedSpeciesWithinSampleData.map((spot) => spot.y),
    ].fold<double>(1.0, (max, value) => value > max ? value : max) * 1.15;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.white,
        border: Border.all(color: isDark ? Colors.grey.shade800 : XolmisColors.borderSubtle),
        borderRadius: BorderRadius.circular(16),
        shape: BoxShape.rectangle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.show_chart,
                    size: 18,
                    color: XolmisColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    S.of(context).speciesAccumulationCurve,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  _buildLegendIndicator(S.of(context).total, XolmisColors.primary, isDark),
                  const SizedBox(width: 8),
                  _buildLegendIndicator(S.of(context).sample, XolmisColors.pinkAccent, isDark),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 300,
            child: ScrollableChartIndicator(
              builder: (context, scrollController) {
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final chartWidth = _responsiveChartWidth(
                      constraints.maxWidth - 16,
                      pixelsPerInventory: 20,
                    );
                    return SingleChildScrollView(
                      controller: scrollController,
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsetsGeometry.fromLTRB(0, 8, 8, 8),
                      child: SizedBox(
                        width: chartWidth,
                        height: 300,
                        child: LineChart(
                          LineChartData(
                            minX: 0,
                            minY: 0,
                            maxX: _sortedInventories.length > 1 ? _sortedInventories.length.toDouble() : 1.0,
                            maxY: accumulationMaxY,
                            lineBarsData: [
                              LineChartBarData(
                                spots: accumulatedSpeciesData,
                                isCurved: false,
                                color:
                                Theme
                                    .of(context)
                                    .brightness ==
                                    Brightness.light
                                    ? Colors.deepPurple
                                    : Colors.deepPurple[200],
                                barWidth: 2,
                                isStrokeCapRound: true,
                                dotData: FlDotData(show: true),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: Colors.deepPurpleAccent
                                      .withAlpha(12),
                                ),
                              ),
                              LineChartBarData(
                                spots:
                                accumulatedSpeciesWithinSampleData,
                                isCurved: false,
                                color:
                                Theme
                                    .of(context)
                                    .brightness ==
                                    Brightness.light
                                    ? Colors.pink
                                    : Colors.pink[200],
                                barWidth: 2,
                                isStrokeCapRound: true,
                                dotData: FlDotData(show: true),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: Colors.pinkAccent.withAlpha(
                                    12,
                                  ),
                                ),
                              ),
                            ],
                            titlesData: FlTitlesData(
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 22,
                                  interval: 1.0,
                                  getTitlesWidget: (value, meta) {
                                    final idx = value.toInt();
                                    if (idx >= 0 && idx <= _sortedInventories.length) {
                                      return Text(
                                        '${idx}',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                          color: isDark
                                              ? Colors.grey.shade400
                                              : Colors.grey.shade600,
                                        ),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 28,
                                  interval: 5.0,
                                  getTitlesWidget: (value, meta) {
                                    // if (value % 20 == 0) {
                                      return Text(
                                        value.toInt().toString(),
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: isDark
                                              ? Colors.grey.shade400
                                              : Colors.grey.shade600,
                                        ),
                                      );
                                    // }
                                    // return const SizedBox.shrink();
                                  },
                                ),
                              ),
                              rightTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: false,
                                ),
                              ),
                              topTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: false,
                                ),
                              ),
                            ),
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: true,
                              getDrawingHorizontalLine: (value) => FlLine(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : Colors.black.withValues(alpha: 0.05),
                                strokeWidth: 1,
                              ),
                              verticalInterval: 1.0,
                              getDrawingVerticalLine: (value) => FlLine(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : Colors.black.withValues(alpha: 0.05),
                                strokeWidth: 1,
                              ),
                            ),
                            borderData: FlBorderData(
                              show: true,
                              border: Border(
                                bottom: BorderSide(
                                  color: isDark
                                      ? Colors.grey.shade800
                                      : XolmisColors.outlineVariant,
                                  width: 1,
                                ),
                                left: BorderSide(
                                  color: isDark
                                      ? Colors.grey.shade800
                                      : XolmisColors.outlineVariant,
                                  width: 1,
                                ),
                                top: BorderSide(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.05)
                                      : Colors.black.withValues(alpha: 0.05),
                                  width: 1,
                                ),
                              ),
                            ),
                            lineTouchData: LineTouchData(
                              handleBuiltInTouches: true,
                              touchTooltipData: LineTouchTooltipData(
                                getTooltipColor: (spot) => Colors.white.withAlpha(200),
                                tooltipBorderRadius: BorderRadius.all(
                                  Radius.circular(8),
                                ),
                                fitInsideVertically: true,
                                fitInsideHorizontally: true,
                                getTooltipItems: (List<LineBarSpot> touchedSpots,) {
                                  if (touchedSpots.isEmpty) {
                                    return [];
                                  }

                                  return touchedSpots.map((spot) {
                                    final spotColor = spot.bar.gradient?.colors.first ??
                                        spot.bar.color ?? Colors.black87;
                                    return LineTooltipItem(
                                      '',
                                      const TextStyle(
                                        color: Colors.black87,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: '${spot.y.toInt()}',
                                          style: TextStyle(
                                            color: spotColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        // TextSpan(
                                        //   text: '\n$inventoryId',
                                        //   style: const TextStyle(
                                        //     color: Colors.black87,
                                        //     fontWeight: FontWeight.normal,
                                        //     fontSize: 10,
                                        //   ),
                                        // ),
                                      ],
                                    );
                                  }).toList();
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: isDark
                    ? XolmisColors.primary.withValues(alpha: 0.15)
                    : XolmisColors.primaryContainer.withValues(alpha: 0.5),
                side: BorderSide(
                  color: isDark
                      ? Colors.grey.shade800
                      : XolmisColors.outlineVariant.withValues(alpha: 0.5),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(
                Icons.table_chart_outlined,
                size: 16,
                color: XolmisColors.primary,
              ),
              label: Text(
                S.of(context).viewSpeciesTable,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? XolmisColors.primaryContainer
                      : XolmisColors.onPrimaryContainer,
                ),
              ),
              onPressed: () {
                final inventories =
                    _sortedInventories;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => InventoryReportScreen(
                      selectedInventories:
                      inventories
                          .whereType<Inventory>()
                          .toList(),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendIndicator(String label, Color color, bool isDark) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildHourlyRecordsCard(bool isDark) {
    final maxHourlyValue = recordsPerHour.values.fold<int>(0, (max, value) => value > max ? value : max);
    final yAxisMax = maxHourlyValue > 0 ? (maxHourlyValue * 1.15).ceilToDouble() : 4.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.white,
        border: Border.all(color: isDark ? Colors.grey.shade800 : XolmisColors.borderSubtle),
        borderRadius: BorderRadius.circular(16),
        shape: BoxShape.rectangle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.access_time_outlined,
                size: 18,
                color: XolmisColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                S.of(context).recordsByHour,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: yAxisMax,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => XolmisColors.jacarandaDeep,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${groupIndex.toString().padLeft(2, '0')} h: ${rod.toY.round()} ${S.of(context).recordsCount(rod.toY.round())}',
                        TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (value, meta) {
                        final hour = value.toInt();
                        if (hour % 4 == 0) {
                          return Text(
                            '${hour.toString().padLeft(2, '0')}h',
                            style: TextStyle(
                              fontSize: 9,
                              color: isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            fontSize: 9,
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.05),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    left: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200, width: 2),
                    bottom: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200, width: 2),
                  ),
                ),
                barGroups: _createBarGroupsFromOccurrencesMap(
                  recordsPerHour,
                  12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRichnessPerInventoryCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.white,
        border: Border.all(color: isDark ? Colors.grey.shade800 : XolmisColors.borderSubtle),
        borderRadius: BorderRadius.circular(16),
        shape: BoxShape.rectangle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.bar_chart_rounded,
                    size: 18,
                    color: XolmisColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    S.of(context).speciesRichness,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
              // Text(
              //   'Total: 4 listas',
              //   style: TextStyle(
              //     fontSize: 11,
              //     color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              //   ),
              // ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: ScrollableChartIndicator(
              builder: (context, scrollController) {
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final chartWidth = _responsiveChartWidth(
                      constraints.maxWidth,
                      pixelsPerInventory: 20,
                    );
                    return SingleChildScrollView(
                      controller: scrollController,
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: chartWidth,
                        height: 150,
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            barTouchData: BarTouchData(
                              enabled: true,
                              touchTooltipData: BarTouchTooltipData(
                                fitInsideVertically: true,
                                fitInsideHorizontally: true,
                                getTooltipColor: (spot) => Colors.white.withAlpha(200),
                                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                  final inventoryId = _sortedInventories[groupIndex].id;
                                  return BarTooltipItem(
                                      '',
                                      TextStyle(
                                        color: Colors.deepPurple,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: '${rod.toY.toInt()}\n',
                                        ),
                                        TextSpan(
                                          text: inventoryId,
                                          style: const TextStyle(
                                            color: Colors.black87,
                                            fontWeight: FontWeight.normal,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ]
                                  );
                                },
                              ),
                            ),
                            titlesData: FlTitlesData(
                              show: true,
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 22,
                                  getTitlesWidget: (value, meta) {
                                    final idx = value.toInt();
                                    if (idx >= 0 && idx < _sortedInventories.length) {
                                      return Text(
                                        '${idx + 1}',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: isDark
                                              ? Colors.grey.shade400
                                              : Colors.grey.shade600,
                                        ),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 24,
                                  getTitlesWidget: (value, meta) {
                                    return Text(
                                      value.toInt().toString(),
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: isDark
                                            ? Colors.grey.shade400
                                            : Colors.grey.shade600,
                                      ),
                                    );
                                  },
                                ),
                              ),
                              topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                            ),
                            barGroups: _sortedInventories
                                .asMap()
                                .map((index, inventory) =>
                                MapEntry(
                                  index,
                                  BarChartGroupData(
                                    x: index,
                                    barRods: [
                                      BarChartRodData(
                                        toY: _getSpeciesRichnessForInventory(inventory).toDouble(),
                                        width: 12,
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(6),
                                          topRight: Radius.circular(6),
                                        ),
                                        color: XolmisColors.jacarandaCore,
                                      ),
                                    ],
                                  ),
                                ))
                                .values
                                .toList(),
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              getDrawingHorizontalLine: (value) => FlLine(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : Colors.black.withValues(alpha: 0.05),
                                strokeWidth: 1,
                              ),
                            ),
                            borderData: FlBorderData(
                              show: true,
                              border: Border(
                                left: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200, width: 2),
                                bottom: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200, width: 2),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // const SizedBox(height: 12),
          // Divider(
          //   height: 1,
          //   color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          // ),
          // const SizedBox(height: 12),
          // Column(
          //   children: widget.inventories.map((inv) {
          //     return Padding(
          //       padding: const EdgeInsets.only(bottom: 6.0),
          //       child: Row(
          //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //         children: [
          //           RichText(
          //             text: TextSpan(
          //               style: TextStyle(
          //                 fontSize: 11,
          //                 color: isDark
          //                     ? Colors.grey.shade300
          //                     : Colors.grey.shade800,
          //               ),
          //               children: [
          //                 // TextSpan(
          //                 //   text: '${} ',
          //                 //   style: const TextStyle(fontWeight: FontWeight.bold),
          //                 // ),
          //                 TextSpan(
          //                   text: '(${inv.id})',
          //                   style: TextStyle(
          //                     color: isDark
          //                         ? Colors.grey.shade500
          //                         : Colors.grey.shade600,
          //                     fontSize: 10,
          //                   ),
          //                 ),
          //               ],
          //             ),
          //           ),
          //           Text(
          //             '${inv.speciesCount} spp',
          //             style: TextStyle(
          //               fontSize: 11,
          //               fontWeight: FontWeight.bold,
          //               color: isDark
          //                   ? XolmisColors.primaryContainer
          //                   : XolmisColors.primary,
          //             ),
          //           ),
          //         ],
          //       ),
          //     );
          //   }).toList(),
          // ),
        ],
      ),
    );
  }

  Map<String, int> _getConservationStatusCounts(List<Inventory> inventories) {
    final speciesSet = <String>{};
    for (final inventory in inventories) {
      for (final species in inventory.speciesList) {
        speciesSet.add(species.name);
      }
    }

    final counts = {
      'LC': 0,
      'NT': 0,
      'VU': 0,
      'EN': 0,
      'CR': 0,
      'DD': 0,
    };

    for (final speciesName in speciesSet) {
      final status = allSpeciesConservationStatus[speciesName]?.trim().toUpperCase();
      if (status != null && counts.containsKey(status)) {
        counts[status] = (counts[status] ?? 0) + 1;
      }
    }

    return counts;
  }

  Map<String, List<String>> _getThreatenedSpeciesByCategory(
    List<Inventory> inventories,
  ) {
    final categories = ['NT', 'VU', 'EN', 'CR', 'DD'];
    final grouped = {for (final category in categories) category: <String>{}};

    final speciesSet = <String>{};
    for (final inventory in inventories) {
      for (final species in inventory.speciesList) {
        speciesSet.add(species.name);
      }
    }

    for (final speciesName in speciesSet) {
      final status = allSpeciesConservationStatus[speciesName]?.trim().toUpperCase();
      if (status != null && grouped.containsKey(status)) {
        grouped[status]!.add(speciesName);
      }
    }

    return {
      for (final entry in grouped.entries)
        entry.key: (entry.value.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase())))
    };
  }

  Map<String, Color> _getConservationCategoryColors() {
    return {
      'LC': Colors.green[700]!,
      'NT': Colors.amber[700]!,
      'VU': Colors.orange[900]!,
      'EN': Colors.red,
      'CR': Colors.red[900]!,
      'DD': Colors.grey[700]!,
    };
  }

  Widget _buildThreatenedSpeciesListContent({
    required Map<String, List<String>> threatenedByCategory,
    required bool isDark,
  }) {
    final categories = ['NT', 'VU', 'EN', 'CR', 'DD'];
    final nonEmptyCategories = categories
        .where((category) => (threatenedByCategory[category]?.isNotEmpty ?? false))
        .toList();
    final colors = _getConservationCategoryColors();
    final contentTextColor = isDark ? Colors.grey.shade200 : Colors.black87;

    if (nonEmptyCategories.isEmpty) {
      return Center(
        child: Text(
          '-',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
          ),
        ),
      );
    }

    return ListView(
      children: [
        for (final category in nonEmptyCategories) ...[
          Builder(
            builder: (context) {
              final color = colors[category] ?? Colors.grey;
              final count = threatenedByCategory[category]!.length;
              final badgeTextColor = category == 'NT' ? Colors.black87 : Colors.white;

              return Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 8),
                child: Row(
                  children: [
                    Text(
                      category,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: badgeTextColor,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          ...threatenedByCategory[category]!.map(
            (speciesName) => Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Text(
                speciesName,
                style: TextStyle(color: contentTextColor),
              ),
            ),
          ),
          Divider(
            height: 16,
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
          ),
        ],
      ],
    );
  }

  Future<void> _showThreatenedSpeciesDialog(BuildContext context, bool isDark) async {
    final threatenedByCategory = _getThreatenedSpeciesByCategory(_sortedInventories);
    final isSmallScreen = MediaQuery.of(context).size.shortestSide < 600;

    final content = _buildThreatenedSpeciesListContent(
      threatenedByCategory: threatenedByCategory,
      isDark: isDark,
    );

    if (isSmallScreen) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return Dialog.fullscreen(
            child: Scaffold(
              appBar: AppBar(
                title: Text(S.of(context).threatenedSpecies),
              ),
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: content,
              ),
            ),
          );
        },
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(S.of(context).threatenedSpecies),
          content: SizedBox(
            width: 460,
            height: 460,
            child: content,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(MaterialLocalizations.of(dialogContext).closeButtonLabel),
            ),
          ],
        );
      },
    );
  }

  Widget _buildConservationStatusCard(bool isDark) {
    final statusCounts = _getConservationStatusCounts(_sortedInventories);
    final categories = ['LC', 'NT', 'VU', 'EN', 'CR', 'DD'];
    final colors = _getConservationCategoryColors();

    final speciesSet = <String>{};
    for (final inventory in _sortedInventories) {
      for (final species in inventory.speciesList) {
        speciesSet.add(species.name);
      }
    }
    final totalSpecies = speciesSet.length;
    final threatenedCount = ['NT', 'VU', 'EN', 'CR', 'DD']
        .fold<int>(0, (sum, category) => sum + (statusCounts[category] ?? 0));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.white,
        border: Border.all(color: isDark ? Colors.grey.shade800 : XolmisColors.borderSubtle),
        borderRadius: BorderRadius.circular(16),
        shape: BoxShape.rectangle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.shield_outlined,
                size: 18,
                color: XolmisColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                S.of(context).conservationStatus,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...categories.map((category) {
            final count = statusCounts[category] ?? 0;
            final color = colors[category] ?? Colors.grey;
            final double percentage = totalSpecies > 0 ? count / totalSpecies : 0.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: Row(
                children: [
                  SizedBox(
                    width: 36,
                    child: Text(
                      category,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: percentage,
                        minHeight: 12,
                        backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 30,
                    child: Text(
                      count.toString(),
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          if (threatenedCount > 0) ...[
            const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: isDark
                    ? XolmisColors.primary.withValues(alpha: 0.15)
                    : XolmisColors.primaryContainer.withValues(alpha: 0.5),
                side: BorderSide(
                  color: isDark
                      ? Colors.grey.shade800
                      : XolmisColors.outlineVariant.withValues(alpha: 0.5),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(
                Icons.table_chart_outlined,
                size: 16,
                color: XolmisColors.primary,
              ),
              label: Text(
                S.of(context).viewSpeciesTable,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? XolmisColors.primaryContainer
                      : XolmisColors.onPrimaryContainer,
                ),
              ),
              onPressed: threatenedCount > 0
                  ? () => _showThreatenedSpeciesDialog(context, isDark)
                  : null,
            ),
          ),
    ],
        ],
      ),
    );
  }

  Widget _buildBiodiversityIndicesCard(BuildContext context, bool isDark) {
    final allSpecies = <Species>[];
    for (final inv in _sortedInventories) {
      allSpecies.addAll(inv.speciesList);
    }
    final combinedMetrics = computeDiversityMetrics(S.of(context).total, allSpecies);
    final perInventoryMetrics = _sortedInventories.map((inv) {
      return computeDiversityMetrics(
        inv.id,
        inv.speciesList,
        ignoreZeroCountSpeciesInChao1: inv.speciesList.any((species) => species.count <= 0),
      );
    }).toList();


    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.white,
        border: Border.all(color: isDark ? Colors.grey.shade800 : XolmisColors.borderSubtle),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.analytics_outlined,
                size: 18,
                color: XolmisColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                S.of(context).biodiversityIndices,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Combined metrics summary
          // Container(
          //   width: double.infinity,
          //   padding: const EdgeInsets.all(12),
          //   decoration: BoxDecoration(
          //     color: isDark ? Colors.grey.shade900 : XolmisColors.secondaryContainer.withValues(alpha: 0.3),
          //     borderRadius: BorderRadius.circular(12),
          //     border: Border.all(color: isDark ? Colors.grey.shade800 : XolmisColors.outlineVariant.withValues(alpha: 0.5)),
          //   ),
          //   child: Column(
          //     crossAxisAlignment: CrossAxisAlignment.start,
          //     children: [
          //       Text(
          //         '${S.of(context).total} (${_sortedInventories.length} ${S.of(context).inventories.toLowerCase()})',
          //         style: TextStyle(
          //           fontSize: 12,
          //           fontWeight: FontWeight.bold,
          //           color: isDark ? XolmisColors.primaryContainer : XolmisColors.primary,
          //         ),
          //       ),
          //       const SizedBox(height: 10),
          //
          //     ],
          //   ),
          // ),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildMetricChip(S.of(context).speciesRichness, '${combinedMetrics.richness}', isDark),
              _buildMetricChip(S.of(context).totalIndividuals, '${combinedMetrics.totalIndividuals}', isDark),
              _buildMetricChip(S.of(context).shannonWienerIndex, combinedMetrics.shannonWiener.toStringAsFixed(3), isDark),
              _buildMetricChip(S.of(context).pielouEvennessIndex, combinedMetrics.pielouEvenness.toStringAsFixed(3), isDark),
              _buildMetricChip(S.of(context).chao1Estimator, combinedMetrics.chao1.toStringAsFixed(1), isDark),
            ],
          ),
          const SizedBox(height: 20),
          // Rarefaction curve (observed vs sample-based expectation)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                S.of(context).expectedRichness,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey.shade200 : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: ScrollableChartIndicator(
              builder: (context, scrollController) {
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final chartWidth = _responsiveChartWidth(
                      constraints.maxWidth - 16,
                      pixelsPerInventory: 25,
                    );
                    return SingleChildScrollView(
                      controller: scrollController,
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: chartWidth,
                        height: 220,
                        child: LineChart(
                          LineChartData(
                            minX: 0,
                            minY: 0,
                            maxX: _sortedInventories.length > 1 ? _sortedInventories.length.toDouble() : 1.0,
                            maxY: maxRichness * 1.15,
                            lineBarsData: [
                              // LineChartBarData(
                              //   spots: sampledSpots,
                              //   isCurved: false,
                              //   color: Colors.deepPurple,
                              //   barWidth: 2,
                              //   dotData: FlDotData(show: true),
                              //   belowBarData: BarAreaData(
                              //     show: true,
                              //     color: Colors.deepPurple.withAlpha(20),
                              //   ),
                              // ),
                              LineChartBarData(
                                spots: expectedSpots,
                                isCurved: true,
                                color: Colors.teal,
                                barWidth: 2,
                                // dashArray: [5, 5],
                                dotData: FlDotData(show: true),
                              ),
                            ],
                            titlesData: FlTitlesData(
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 22,
                                  interval: 1.0,
                                  getTitlesWidget: (value, meta) {
                                    final idx = value.toInt();
                                    if (idx >= 0 && idx <= _sortedInventories.length) {
                                      return Text(
                                        '${idx}',
                                        style: TextStyle(fontSize: 10, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 28,
                                  getTitlesWidget: (value, meta) {
                                    return Text(
                                      value.toInt().toString(),
                                      style: TextStyle(fontSize: 9, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                                    );
                                  },
                                ),
                              ),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            gridData: FlGridData(show: true, drawVerticalLine: true),
                            borderData: FlBorderData(show: true),
                            lineTouchData: LineTouchData(
                              handleBuiltInTouches: true,
                              touchTooltipData: LineTouchTooltipData(
                                getTooltipColor: (spot) => Colors.white.withAlpha(200),
                                tooltipBorderRadius: BorderRadius.all(
                                  Radius.circular(8),
                                ),
                                fitInsideVertically: true,
                                fitInsideHorizontally: true,
                                getTooltipItems: (List<LineBarSpot> touchedSpots,) {
                                  if (touchedSpots.isEmpty) {
                                    return [];
                                  }

                                  return touchedSpots.map((spot) {
                                    final spotColor = spot.bar.gradient?.colors.first ??
                                        spot.bar.color ?? Colors.black87;
                                    return LineTooltipItem(
                                      '',
                                      const TextStyle(
                                        color: Colors.black87,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: '${spot.y.toInt()}',
                                          style: TextStyle(
                                            color: spotColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        // TextSpan(
                                        //   text: '\n$inventoryId',
                                        //   style: const TextStyle(
                                        //     color: Colors.black87,
                                        //     fontWeight: FontWeight.normal,
                                        //     fontSize: 10,
                                        //   ),
                                        // ),
                                      ],
                                    );
                                  }).toList();
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // Row(
          //   mainAxisAlignment: MainAxisAlignment.center,
          //   children: [
          //     _buildLegendIndicator(S.of(context).sampledRichness, Colors.deepPurple, isDark),
          //     const SizedBox(width: 8),
          //     _buildLegendIndicator(S.of(context).expectedRichness, Colors.teal, isDark),
          //   ],
          // ),
          const SizedBox(height: 20),
          // Per-inventory table title
          Text(
            S.of(context).diversityTable,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey.shade200 : Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          // Table of metrics per inventory
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              horizontalMargin: 8,
              columnSpacing: 20,
              headingRowHeight: 34,
              dataRowMinHeight: 28,
              dataRowMaxHeight: 32,
              border: TableBorder(
                verticalInside: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
                horizontalInside: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
                top: BorderSide(width: 2, color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
                bottom: BorderSide(width: 2, color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
                left: BorderSide(width: 2, color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
                right: BorderSide(width: 2, color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
              ),
              headingRowColor: WidgetStateProperty.all(
                isDark ? Colors.grey.shade900 : XolmisColors.surfaceVariant.withValues(alpha: 0.5),
              ),
              columns: [
                DataColumn(label: Text(S.of(context).inventories, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                DataColumn(label: Text('S', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)), headingRowAlignment: MainAxisAlignment.end),
                DataColumn(label: Text('N', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)), headingRowAlignment: MainAxisAlignment.end),
                DataColumn(label: Text("H'", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)), headingRowAlignment: MainAxisAlignment.end),
                DataColumn(label: Text("J'", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)), headingRowAlignment: MainAxisAlignment.end),
                DataColumn(label: Text('Chao1', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)), headingRowAlignment: MainAxisAlignment.end),
              ],
              rows: perInventoryMetrics.map((m) {
                return DataRow(
                  cells: [
                    DataCell(Text(m.label, style: const TextStyle(fontSize: 11))),
                    DataCell(Container(
                      alignment: Alignment.centerRight,
                      // padding: const EdgeInsets.symmetric(
                      //     horizontal: 4, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('${m.richness}', style: const TextStyle(fontSize: 11)),
                    ),
                    ),
                    DataCell(Container(
                      alignment: Alignment.centerRight,
                      // padding: const EdgeInsets.symmetric(
                      //   horizontal: 4, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('${m.totalIndividuals}', style: const TextStyle(fontSize: 11)),
                    ),
                    ),
                    DataCell(
                Container(
                alignment: Alignment.centerRight,
                // padding: const EdgeInsets.symmetric(
                // horizontal: 4, vertical: 4),
                decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                ),
                child: Text(m.shannonWiener.toStringAsFixed(3), style: const TextStyle(fontSize: 11)),
                ),
                ),
                    DataCell(Container(
                alignment: Alignment.centerRight,
                // padding: const EdgeInsets.symmetric(
                // horizontal: 4, vertical: 4),
                decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                ),
                child: Text(m.pielouEvenness.toStringAsFixed(3), style: const TextStyle(fontSize: 11)),
                ),
                ),
                    DataCell(Container(
                alignment: Alignment.centerRight,
                // padding: const EdgeInsets.symmetric(
                // horizontal: 4, vertical: 4),
                decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                ),
                child: Text(m.chao1.toStringAsFixed(1), style: const TextStyle(fontSize: 11)),
                ),
                ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricChip(String label, String value, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : XolmisColors.surfaceVariant.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? Colors.grey.shade800 : XolmisColors.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? XolmisColors.primaryContainer : XolmisColors.primary,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
