import 'package:fl_chart/fl_chart.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/core_consts.dart';
import '../../data/models/inventory.dart';
import '../../generated/l10n.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/poi_provider.dart';
import '../../providers/species_provider.dart';
import '../../reports/selected_inventories_pdf_report.dart';
import '../../widgets/scrollable_chart_indicator.dart';
import '../../utils/statistics_logic.dart';
import '../../utils/themes.dart';
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
            appBar: AppBar(title: Text(S.current.statistics)),
            body: Center(
              child: Text('Error: ${snapshot.error}'),
            ),
          );
        } else {
          return Scaffold(
            appBar: AppBar(title: Text(S.current.statistics)),
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
  late List<FlSpot> accumulatedSpeciesData = [];
  late List<FlSpot> accumulatedSpeciesWithinSampleData = [];
  late List<String> combinedSpeciesList = [];
  late double averageSpeciesCount = 0;
  late int distinctLocalitiesCount = 0;
  late Map<int, int> recordsPerHour = {};

  @override
  void initState() {
    super.initState();
    inventoryProvider = Provider.of<InventoryProvider>(context, listen: false);
    speciesProvider = Provider.of<SpeciesProvider>(context, listen: false);
    poiProvider = Provider.of<PoiProvider>(context, listen: false);
    _loadData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// Loads precomputed metrics and chart datasets for inventories.
  Future<void> _loadData() async {
    accumulatedSpeciesData = prepareAccumulatedSpeciesData(widget.inventories);
    accumulatedSpeciesWithinSampleData = prepareAccumulatedSpeciesWithinSample(widget.inventories);
    combinedSpeciesList = _getSpeciesList(widget.inventories);
    if (widget.inventories.isNotEmpty) {
      int totalRichnessSum = widget.inventories.fold(0, (sum, inv) {
        final count = _getSpeciesRichnessForInventory(inv);
        return sum + count;
      });

      averageSpeciesCount = totalRichnessSum / widget.inventories.length;
    } else {
      averageSpeciesCount = 0;
    }

    final allLocalities = widget.inventories.map((inventory) => inventory.localityName).toList();
    final distinctLocalities = allLocalities.toSet();
    distinctLocalitiesCount = distinctLocalities.length;

    recordsPerHour = _getOccurrencesByHourOfDayWithFallback(widget.inventories);
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
    final calculatedWidth = widget.inventories.length * pixelsPerInventory;
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
              color: XolmisColors.primary,
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
          title: Text(S.current.statistics),
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
      childAspectRatio: 2.1,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildKpiTile(
          label: S.current.selectedInventories,
          value: '${widget.inventories.length}',
          // subtext: '',
          valueColor: XolmisColors.primary,
          isDark: isDark,
        ),
        _buildKpiTile(
          label: S.current.localitiesSurveyed(distinctLocalitiesCount),
          value: '${distinctLocalitiesCount}',
          // subtext: '',
          valueColor: XolmisColors.primary,
          isDark: isDark,
        ),
        _buildKpiTile(
          label: S.current.totalRichness,
          value: '${combinedSpeciesList.length}',
          // subtext: '',
          valueColor: XolmisColors.primary,
          isDark: isDark,
        ),
        _buildKpiTile(
          label: S.current.averageRichness,
          value: averageSpeciesCount.toStringAsFixed(1),
          // subtext: '',
          valueColor: XolmisColors.primary,
          isDark: isDark,
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
          // Row(
          //   textBaseline: TextBaseline.alphabetic,
          //   crossAxisAlignment: CrossAxisAlignment.baseline,
          //   children: [
          //
          //     const SizedBox(width: 6),
          //     Expanded(
          //       child: Text(
          //         subtext,
          //         style: TextStyle(
          //           fontSize: 10,
          //           color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          //         ),
          //         overflow: TextOverflow.ellipsis,
          //       ),
          //     ),
          //   ],
          // ),
        ],
      ),
    );
  }

  Widget _buildAccumulationCurveCard(BuildContext context, bool isDark) {
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
                    S.current.speciesAccumulationCurve,
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
                  _buildLegendIndicator(S.current.total, XolmisColors.primary, isDark),
                  const SizedBox(width: 8),
                  _buildLegendIndicator(S.current.sample, XolmisColors.pinkAccent, isDark),
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
                            maxX:
                            widget.inventories.length.toDouble() -
                                1,
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
                                    if (idx >= 0 && idx < widget.inventories.length) {
                                      return Text(
                                        '${value.toInt() + 1}',
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
                                  final spotIndex = touchedSpots.first.spotIndex;
                                  final inventoryId = widget.inventories[spotIndex].id;

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
                                        TextSpan(
                                          text: '\n$inventoryId',
                                          style: const TextStyle(
                                            color: Colors.black87,
                                            fontWeight: FontWeight.normal,
                                            fontSize: 10,
                                          ),
                                        ),
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
                S.current.viewSpeciesTable,
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
                    widget.inventories;
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
                S.current.recordsByHour,
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
                        '${groupIndex.toString().padLeft(2, '0')} h: ${rod.toY.round()} ${S.current.recordsCount(rod.toY.round())}',
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
                    S.current.speciesRichness,
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
                                  final inventoryId = widget.inventories[groupIndex].id;
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
                                    if (idx >= 0 && idx < widget.inventories.length) {
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
                            barGroups: widget.inventories
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
                                        color: Theme
                                            .of(context)
                                            .brightness == Brightness.light
                                            ? Colors.deepPurple
                                            : Colors.deepPurple[200],
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
}
