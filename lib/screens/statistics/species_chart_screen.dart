import 'package:material_ui/material_ui.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:xolmis/generated/l10n.dart';

import '../../data/models/inventory.dart';
import '../../providers/species_provider.dart';

/// Displays the species accumulation curve for a single inventory.
class SpeciesChartScreen extends StatefulWidget {
  final Inventory inventory;

  const SpeciesChartScreen({super.key, required this.inventory});

  @override
  State<SpeciesChartScreen> createState() => _SpeciesChartScreenState();
}

/// Prepares curve data and renders the species accumulation chart.
class _SpeciesChartScreenState extends State<SpeciesChartScreen> {
  late List<SpeciesAccumulationData> speciesAccumulationData;
  List<FlSpot> trendLineSpots = [];
  late double minX;
  late double maxX;
  late double maxY;
  late int intervalSize;
  late double inventoryDurationSeconds;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeChartData();
    });
  }

  /// Initializes chart points and axis bounds.
  void _initializeChartData() {
    final speciesProvider = Provider.of<SpeciesProvider>(context, listen: false);
    final speciesList = speciesProvider.getSpeciesForInventory(widget.inventory.id);
    setState(() {
      speciesAccumulationData = _prepareSpeciesAccumulationData(widget.inventory, speciesList);
      _calculateChartBounds();
    });
  }

  /// Calculates min/max axis values from accumulated points.
  void _calculateChartBounds() {
    minX = 0.0;
    maxX = speciesAccumulationData.isNotEmpty
        ? speciesAccumulationData
        .map((data) => data.interval.toDouble())
        .reduce((a, b) => a > b ? a : b)
        : 0.0;
    maxY = speciesAccumulationData.isNotEmpty
        ? speciesAccumulationData
        .map((data) => data.speciesCount.toDouble())
        .reduce((a, b) => a > b ? a : b)
        : 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).speciesAccumulationCurve),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 56.0),
          child: Consumer<SpeciesProvider>(
            builder: (context, speciesProvider, child) {
              final speciesList = speciesProvider.getSpeciesForInventory(widget.inventory.id);
              speciesAccumulationData = _prepareSpeciesAccumulationData(widget.inventory, speciesList);
              _calculateChartBounds();

              return speciesAccumulationData.isEmpty
                // Show a message if there is no data
                  ? Center(child: Text(S.current.noDataAvailable))
                  : LineChart(
                LineChartData(
                  minX: minX,
                  maxX: maxX,
                  maxY: maxY,
                  extraLinesData: ExtraLinesData(
                    verticalLines: maxX > inventoryDurationSeconds
                        ? [
                           VerticalLine(
                             x: inventoryDurationSeconds,
                             color: Theme.of(context).brightness == Brightness.light
                                 ? Colors.pink
                                 : Colors.pink[200],
                             strokeWidth: 2,
                             dashArray: [6, 4],
                           ),
                         ]
                        : [],
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      axisNameSize: 20,
                      axisNameWidget: Text(
                        intervalSize == 10
                            ? S.current.timeSeconds
                            : intervalSize == 60
                                ? S.current.timeMinutes
                                : '${S.current.timeMinutes} (×10)',
                      ),
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          // Convert seconds to appropriate display unit
                          final displayValue = intervalSize == 10
                              ? value.toInt()           // show raw seconds
                              : (value / 60).round();   // convert to minutes
                          return SideTitleWidget(meta: meta, child: Text('$displayValue'));
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      axisNameSize: 20,
                      axisNameWidget: Text(S.current.speciesAccumulated),
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: maxY > 10 ? 5 : 1,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return SideTitleWidget(meta: meta, child: Text(value.toInt().toString()));
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(show: false, horizontalInterval: 1, verticalInterval: 1),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.grey, width: 1),
                  ),
                  lineBarsData: [
                    // Show the line of accumulated species
                    LineChartBarData(
                      spots: speciesAccumulationData
                          .map((data) => FlSpot(data.interval.toDouble(), data.speciesCount.toDouble()))
                          .toList(),
                      isCurved: false,
                      barWidth: 2,
                      color: Theme.of(context).brightness == Brightness.light
                          ? Colors.deepPurple
                          : Colors.deepPurple[200],
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.deepPurpleAccent.withAlpha(30),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    handleBuiltInTouches: true,
                    touchTooltipData: LineTouchTooltipData(
                      tooltipBorderRadius: BorderRadius.all(Radius.circular(8)),
                      getTooltipItems: (List<LineBarSpot> touchedSpots) {
                        return touchedSpots.map((LineBarSpot touchedSpot) {
                          final textStyle = TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          );
                          return LineTooltipItem(
                            '${touchedSpot.y.toInt()}',
                            textStyle,
                            textAlign: TextAlign.left,
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Aggregates species richness by intervals.
  /// - elapsed < 2 min  → 10-second intervals
  /// - elapsed < 20 min → 1-minute intervals (60 s)
  /// - elapsed >= 20 min → 10-minute intervals (600 s)
  ///
  /// [interval] values stored in [SpeciesAccumulationData] are in **seconds**.
  List<SpeciesAccumulationData> _prepareSpeciesAccumulationData(Inventory inventory, List<Species> speciesList) {
    final speciesAccumulationData = <SpeciesAccumulationData>[];
    final speciesByInterval = <int, Set<String>>{};

    // Work entirely in seconds for uniform precision across all interval sizes.
    final startTime = inventory.startTime;
    if (startTime == null) return [];

    final endTime = inventory.isFinished ? inventory.endTime! : DateTime.now();
    final wallClockDuration = endTime.difference(startTime).inSeconds;

    // Find the latest species registration time among all registered species
    int maxSpeciesElapsed = 0;
    for (final species in speciesList) {
      if (species.sampleTime != null) {
        final elapsed = species.sampleTime!.difference(startTime).inSeconds;
        if (elapsed > maxSpeciesElapsed) {
          maxSpeciesElapsed = elapsed;
        }
      }
    }

    // The chart should extend to cover the latest species OR the inventory wall-clock duration.
    // This ensures species registered after the timer/finish are visible.
    final totalElapsedSeconds = maxSpeciesElapsed > wallClockDuration ? maxSpeciesElapsed : wallClockDuration;

    // Use the wallClockDuration as the marker for the inventory's end.
    inventoryDurationSeconds = wallClockDuration.toDouble();
    final totalElapsedMinutes = totalElapsedSeconds ~/ 60;

    // Choose interval size in seconds:
    //   < 5 min  → 10 s
    //   < 60 min → 60 s (1 min)
    //   >= 60 min → 600 s (10 min)
    if (totalElapsedMinutes < 5) {
      intervalSize = 10;
    } else if (totalElapsedMinutes < 60) {
      intervalSize = 60;
    } else {
      intervalSize = 600;
    }

    final totalIntervals = (totalElapsedSeconds / intervalSize).ceil();

    for (final species in speciesList) {
      final sampleTime = species.sampleTime;

      // Skip species without sample time
      if (sampleTime == null) {
        continue;
      }

      // Calculate the interval index for the species
      final elapsedSeconds = sampleTime.difference(startTime).inSeconds;
      final interval = elapsedSeconds ~/ intervalSize;

      if (!speciesByInterval.containsKey(interval)) {
        speciesByInterval[interval] = <String>{};
      }

      // Add the species to the interval
      speciesByInterval[interval]!.add(species.name);
    }

    int cumulativeSpeciesCount = 0;
    final seenSpecies = <String>{};

    // Calculate the cumulative species count for each interval
    for (int i = 0; i <= totalIntervals; i++) {
      if (speciesByInterval.containsKey(i)) {
        for (final species in speciesByInterval[i]!) {
          if (!seenSpecies.contains(species)) {
            seenSpecies.add(species);
            cumulativeSpeciesCount++;
          }
        }
      }
      // X value stored in seconds
      speciesAccumulationData.add(SpeciesAccumulationData(i * intervalSize, cumulativeSpeciesCount));
    }

    return speciesAccumulationData;
  }
}

/// Immutable point used by the accumulation curve.
class SpeciesAccumulationData {
  final int interval;
  final int speciesCount;

  SpeciesAccumulationData(this.interval, this.speciesCount);
}
