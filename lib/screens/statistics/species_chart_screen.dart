import 'package:material_ui/material_ui.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:xolmis/generated/l10n.dart';

import '../../data/models/inventory.dart';
import '../../providers/species_provider.dart';
import '../../utils/chart_utils.dart';

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
      final chartData = prepareSpeciesAccumulationData(widget.inventory, speciesList);
      speciesAccumulationData = chartData['data'];
      intervalSize = chartData['intervalSize'];
      inventoryDurationSeconds = chartData['duration'];
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
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: Consumer<SpeciesProvider>(
            builder: (context, speciesProvider, child) {
              final speciesList = speciesProvider.getSpeciesForInventory(widget.inventory.id);
              final chartData = prepareSpeciesAccumulationData(widget.inventory, speciesList);
              speciesAccumulationData = chartData['data'];
              intervalSize = chartData['intervalSize'];
              inventoryDurationSeconds = chartData['duration'];
              _calculateChartBounds();

              return Hero(
                tag: 'species_chart_${widget.inventory.id}',
                flightShuttleBuilder: (flightContext, animation, flightDirection, fromHeroContext, toHeroContext) {
                  return Material(
                    type: MaterialType.transparency,
                    child: toHeroContext.widget,
                  );
                },
                child: Material(
                  type: MaterialType.transparency,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final bool canShowTitles = constraints.maxWidth > 150 && constraints.maxHeight > 150;
                      
                      return speciesAccumulationData.isEmpty
                        // Show a message if there is no data
                          ? Center(child: Column(
                            children: [
                              Icon(
                                Icons.grid_off_outlined,
                                size: 24,
                                color: Theme.of(context).disabledColor,
                              ),
                              const SizedBox(height: 8),
                              Text(S.current.noDataAvailable)
                            ],
                          ))
                          : LineChart(
                              LineChartData(
                                minX: minX,
                                maxX: maxX == 0 ? 1 : maxX,
                                // minY: 0,
                                maxY: maxY == 0 ? 5 : maxY,
                                extraLinesData: ExtraLinesData(
                                  verticalLines: maxX > inventoryDurationSeconds
                                      ? [
                                         VerticalLine(
                                           x: inventoryDurationSeconds,
                                           // label: VerticalLineLabel(
                                           //   show: true,
                                           //   alignment: Alignment.topLeft,
                                           //   direction: LabelDirection.vertical,
                                           //   style: TextStyle(
                                           //     color: Theme.of(context).brightness == Brightness.light
                                           //         ? Colors.pink
                                           //         : Colors.pink[200],
                                           //   ),
                                           //   labelResolver: (line) => S.current.finished,
                                           // ),
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
                                  show: canShowTitles,
                                  bottomTitles: AxisTitles(
                                    axisNameSize: 24,
                                    axisNameWidget: Text(
                                      intervalSize == 10
                                          ? S.current.timeSeconds
                                          : S.current.timeMinutes,
                                    ),
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 36,
                                      getTitlesWidget: (value, meta) {
                                        // Convert seconds to appropriate display unit
                                        final displayValue = intervalSize == 10
                                            ? value.toInt()           // show raw seconds
                                            : (value / 60).round();   // convert to minutes
                                        return SideTitleWidget(
                                          meta: meta,
                                          space: 8,
                                          child: Text('$displayValue'),
                                        );
                                      },
                                    ),
                                  ),
                                  leftTitles: AxisTitles(
                                    axisNameSize: 24,
                                    axisNameWidget: Text(S.current.speciesAccumulated),
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      interval: maxY > 10 ? 5 : 1,
                                      reservedSize: 48,
                                      getTitlesWidget: (value, meta) {
                                        return SideTitleWidget(
                                          meta: meta,
                                          space: 8,
                                          child: Text(value.toInt().toString()),
                                        );
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
                                    getTooltipColor: (spot) => Colors.white.withAlpha(200),
                                    tooltipBorderRadius: BorderRadius.all(
                                      Radius.circular(8),
                                    ),
                                    fitInsideVertically: true,
                                    fitInsideHorizontally: true,
                                    getTooltipItems: (List<LineBarSpot> touchedSpots) {
                                      if (touchedSpots.isEmpty) {
                                        return [];
                                      }
                                      return touchedSpots.map((LineBarSpot touchedSpot) {
                                        final spotColor = touchedSpot.bar.gradient?.colors.first ??
                                            touchedSpot.bar.color ?? Colors.black87;
                                        final textStyle = TextStyle(
                                          color: spotColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        );
                                        return LineTooltipItem(
                                          '',
                                          textStyle,
                                          children: [
                                            TextSpan(
                                              text: '${touchedSpot.y.toInt()} ${S.current.speciesAcronym(touchedSpot.y.toInt())}',
                                              style: TextStyle(
                                                color: spotColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                            TextSpan(
                                              text: intervalSize == 10
                                                  ? '\n${touchedSpot.x.toInt()} s'
                                                  : '\n${(touchedSpot.x.toInt() / 60).round()} min',
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
                            );

                  },
                ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
