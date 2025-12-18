import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/inventory.dart';
import '../../generated/l10n.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/poi_provider.dart';
import '../../providers/species_provider.dart';
import '../../utils/statistics_logic.dart';

class StatsInventoriesScreen extends StatefulWidget {
  final List<Inventory> inventories;

  const StatsInventoriesScreen({super.key, required this.inventories});

  @override
  StatsInventoriesScreenState createState() => StatsInventoriesScreenState();
}

class StatsInventoriesScreenState extends State<StatsInventoriesScreen> {
  late InventoryProvider inventoryProvider;
  late SpeciesProvider speciesProvider;
  late PoiProvider poiProvider;
  late List<FlSpot> accumulatedSpeciesData = [];
  late List<FlSpot> accumulatedSpeciesWithinSampleData = [];
  late List<String> combinedSpeciesList = [];
  late double averageSpeciesCount = 0;
  late int distinctLocalitiesCount = 0;

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

  Future<void> _loadData() async {
    accumulatedSpeciesData = prepareAccumulatedSpeciesData(widget.inventories);
    accumulatedSpeciesWithinSampleData = prepareAccumulatedSpeciesWithinSample(widget.inventories);
    combinedSpeciesList = _getSpeciesList(widget.inventories);
    averageSpeciesCount = combinedSpeciesList.length / widget.inventories.length;

    final allLocalities = widget.inventories.map((inventory) => inventory.localityName).toList();
    final distinctLocalities = allLocalities.toSet();
    distinctLocalitiesCount = distinctLocalities.length;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.current.statistics)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // Number of selected inventories
                    Expanded(child:
                    Card(
                      surfaceTintColor: Colors.deepPurple,
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.inventories.length.toString(),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: Theme.of(context).textTheme.headlineSmall?.fontWeight,
                                fontSize: Theme.of(context).textTheme.headlineSmall?.fontSize,
                              ),
                            ),
                            Text(S.current.selectedInventories),
                          ],
                        ),
                      ),
                    ),
                    ),
                    // Localities surveyed
                    Expanded(child:
                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              distinctLocalitiesCount.toString(),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: Theme.of(context).textTheme.headlineSmall?.fontWeight,
                                fontSize: Theme.of(context).textTheme.headlineSmall?.fontSize,
                              ),
                            ),
                            Text(S.current.localitiesSurveyed(distinctLocalitiesCount)),
                          ],
                        ),
                      ),
                    ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // Total species richness
                    Expanded(child:
                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              combinedSpeciesList.length.toString(),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: Theme.of(context).textTheme.headlineSmall?.fontWeight,
                                fontSize: Theme.of(context).textTheme.headlineSmall?.fontSize,
                              ),
                            ),
                            Text(S.current.totalRichness),
                          ],
                        ),
                      ),
                    ),
                    ),
                    // Average species richness
                    Expanded(child:
                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              averageSpeciesCount.toStringAsFixed(1),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: Theme.of(context).textTheme.headlineSmall?.fontWeight,
                                fontSize: Theme.of(context).textTheme.headlineSmall?.fontSize,
                              ),
                            ),
                            Text(S.current.averageRichness),
                          ],
                        ),
                      ),
                    ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Text(
                                S.current.speciesAccumulationCurve,
                                style: TextTheme.of(context).titleMedium,
                              ),
                              const SizedBox(height: 8,),
                              SizedBox(
                                height: 400,
                                child: LineChart(
                                  LineChartData(
                                    // minX: 0,
                                    maxX:
                                        widget.inventories.length.toDouble() -
                                        1,
                                    // minY: 0,
                                    // maxY: accumulatedSpeciesData.isNotEmpty
                                    //     ? accumulatedSpeciesData.map((data) => data.y).reduce((a, b) => a > b ? a : b)
                                    //     : 0,
                                    lineBarsData: [
                                      LineChartBarData(
                                        spots: accumulatedSpeciesData,
                                        isCurved: false,
                                        color:
                                            Theme.of(context).brightness ==
                                                    Brightness.light
                                                ? Colors.deepPurple
                                                : Colors.deepPurple[200],
                                        barWidth: 2,
                                        isStrokeCapRound: true,
                                        dotData: FlDotData(show: true),
                                        belowBarData: BarAreaData(
                                          show: true,
                                          color: Colors.deepPurpleAccent
                                              .withAlpha(30),
                                        ),
                                      ),
                                      LineChartBarData(
                                        spots:
                                            accumulatedSpeciesWithinSampleData,
                                        isCurved: false,
                                        color:
                                            Theme.of(context).brightness ==
                                                    Brightness.light
                                                ? Colors.pink
                                                : Colors.pink[200],
                                        barWidth: 2,
                                        isStrokeCapRound: true,
                                        dotData: FlDotData(show: true),
                                        belowBarData: BarAreaData(
                                          show: true,
                                          color: Colors.pinkAccent.withAlpha(
                                            30,
                                          ),
                                        ),
                                      ),
                                    ],
                                    titlesData: FlTitlesData(
                                      bottomTitles: AxisTitles(
                                        // axisNameWidget: Text(
                                        //   S.current.inventories,
                                        // ),
                                        sideTitles: SideTitles(
                                          showTitles: false,
                                          interval: 1,
                                          getTitlesWidget: (value, meta) {
                                            final index = value.toInt();
                                            if (index >= 0 &&
                                                index <
                                                    widget.inventories
                                                        .length) {
                                              final parts =
                                                  widget.inventories[index].id
                                                      .split('-');
                                              final listNumber =
                                                  parts.length > 1
                                                      ? parts.last
                                                      : widget.inventories[index]
                                                          .id;
                                              return Text(listNumber);
                                            } else {
                                              return Text('');
                                            }
                                          },
                                        ),
                                      ),
                                      leftTitles: AxisTitles(
                                        // axisNameWidget: Text(
                                        //   S.current.speciesAccumulated,
                                        // ),
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          interval: 5,
                                          reservedSize: 40,
                                          getTitlesWidget: (value, meta) {
                                            return Align(
                                              alignment: Alignment.center,
                                              child: Text(
                                                value.toInt().toString(),
                                              ),
                                            );
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
                                      show: false,
                                      horizontalInterval: 1,
                                      verticalInterval: 1,
                                    ),
                                    borderData: FlBorderData(
                                      show: true,
                                      border: Border(
                                        bottom: BorderSide(
                                          color: Colors.grey,
                                          width: 1,
                                        ),
                                        left: BorderSide(
                                          color: Colors.grey,
                                          width: 1,
                                        ),
                                        top: BorderSide.none,
                                        right: BorderSide.none,
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
                                        getTooltipItems: (
                                          List<LineBarSpot> touchedSpots,
                                        ) {
                                          if (touchedSpots.isEmpty) {
                                            return [];
                                          }
                                          final spotIndex = touchedSpots.first.spotIndex;
                                          final inventoryId = widget.inventories[spotIndex].id;

                                          return touchedSpots.map((spot) {
                                            final spotColor = spot.bar.gradient?.colors.first ?? spot.bar.color ?? Colors.black87;
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
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
            Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
            Expanded(
            child: Card(
            child: Padding(
                padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
              Text(
              S.current.speciesRichness,
              style: TextTheme.of(context).titleMedium,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 150,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  // maxY: (widget.inventories.map((inventory) => inventory.speciesList.length).reduce((a, b) => a > b ? a : b) / 10).ceil() * 10.0,
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
                          // rod.toY.toString(),
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
                      // axisNameWidget: Text(S.current.inventories),
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt() + 1;
                          return Text('$index');
                          // if (index >= 0 && index < widget.inventories.length) {
                          //   final parts = widget.inventories[index].id.split('-');
                          //   final listNumber = parts.length > 1
                          //       ? parts.last
                          //       : widget.inventories[index].id;
                          //   return Text(listNumber);
                          // } else {
                          //   return Text('');
                          // }
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      // axisNameWidget: Text(S.current.speciesCounted),
                      sideTitles: SideTitles(
                        showTitles: false,
                        interval: 10,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Align(
                              alignment: Alignment.center,
                              child: Text(value.toInt().toString())
                          );
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  barGroups: widget.inventories
                      .asMap()
                      .map((index, inventory) => MapEntry(
                    index,
                    BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: inventory.speciesList.length.toDouble(),
                          width: 12,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(6),
                            topRight: Radius.circular(6),
                          ),
                          color: Theme.of(context).brightness == Brightness.light
                              ? Colors.deepPurple
                              : Colors.deepPurple[200],
                        ),
                      ],
                    ),
                  ))
                      .values
                      .toList(),
                  gridData: FlGridData(show: false, horizontalInterval: 1, verticalInterval: 1),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      bottom: BorderSide(
                          color: Colors.grey,
                        width: 1,
                      ),
                        // left: BorderSide(
                        //   color: Colors.grey,
                        //   width: 1,
                        // ),
                        // top: BorderSide.none,
                        // right: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),
              ],
            ),
            ),
            ),
            ),
                ],
            ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
