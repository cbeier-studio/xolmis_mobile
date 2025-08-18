// import 'package:equations/equations.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:xolmis/generated/l10n.dart';

import '../../data/models/inventory.dart';

class SpeciesChartScreen extends StatefulWidget {
  final Inventory inventory;

  const SpeciesChartScreen({super.key, required this.inventory});

  @override
  State<SpeciesChartScreen> createState() => _SpeciesChartScreenState();
}

class _SpeciesChartScreenState extends State<SpeciesChartScreen> {
  late List<SpeciesAccumulationData> speciesAccumulationData;
  List<FlSpot> trendLineSpots = [];
  late double minX;
  late double maxX;
  late double maxY;

  @override
  void initState() {
    super.initState();
    _initializeChartData();
  }

  // Initialize the chart data
  void _initializeChartData() {
    speciesAccumulationData = _prepareSpeciesAccumulationData(widget.inventory);
    _calculateChartBounds();
    // _calculateTrendLine();
  }

  // Set the chart bounds
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

  // EXPERIMENTAL
  // Prepare the data for the trend line
  // void _calculateTrendLine() {
  //   if (speciesAccumulationData.isEmpty) {
  //     trendLineSpots = [];
  //     return;
  //   }
  //
  //   final List<InterpolationNode> nodes = speciesAccumulationData
  //       .map((point) => InterpolationNode(
  //       x: point.interval.toDouble(), y: point.speciesCount.toDouble()))
  //       .toList();
  //
  //   final splineInterpolation = PolynomialInterpolation(nodes: nodes);
  //
  //   trendLineSpots = [];
  //   final step = (nodes.last.x - nodes.first.x) / 1000;
  //   for (double x = nodes.first.x; x <= nodes.last.x; x += step) {
  //     final y = splineInterpolation.compute(x);
  //     trendLineSpots.add(FlSpot(x, y));
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).speciesAccumulationCurve),        
      ),
      body: SafeArea(
        child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: speciesAccumulationData.isEmpty
          // Show a message if there is no data
            ? Center(child: Text(S.current.noDataAvailable))
            : LineChart(          
          LineChartData(
            minX: minX,
            maxX: maxX,
            maxY: maxY,
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                axisNameWidget: Text(S.current.timeMinutes),
                sideTitles: SideTitles(
                  showTitles: true,
                  // interval: 3,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) {
                    final minutes = value.toInt();
                    return Text('$minutes');
                  },
                ),
              ),
              leftTitles: AxisTitles(
                axisNameWidget: Text(S.current.speciesAccumulated),
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 5,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) {
                    return Text(value.toInt().toString());
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
              // Show the trend/smoothed line
              // LineChartBarData(
              //   show: true,
              //       spots: trendLineSpots,
              //       isCurved: false,
              //       color: Colors.red,
              //       barWidth: 2,
              //       isStrokeCapRound: true,
              //       dotData: FlDotData(show: false),
              //     ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  // Prepare the data for the species accumulation curve
  List<SpeciesAccumulationData> _prepareSpeciesAccumulationData(Inventory inventory) {
    final speciesAccumulationData = <SpeciesAccumulationData>[];
    final speciesByInterval = <int, Set<String>>{};

    // Calculate the total elapsed minutes and the total intervals
    final startTime = inventory.startTime!;
    final currentTime = inventory.isFinished ? inventory.endTime! : DateTime.now();
    final totalElapsedMinutes = currentTime.difference(startTime).inMinutes;
    final totalIntervals = (totalElapsedMinutes / 10).ceil();

    for (final species in inventory.speciesList) {
      final sampleTime = species.sampleTime;

      // Skip species without sample time
      if (sampleTime == null) {
        continue;
      }

      // Calculate the interval for the species
      final elapsedMinutes = sampleTime.difference(startTime).inMinutes;
      final interval = elapsedMinutes ~/ 10;

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
      speciesAccumulationData.add(SpeciesAccumulationData(i * 10, cumulativeSpeciesCount));
    }

    return speciesAccumulationData;
  }
}

// Data class for the species accumulation curve
class SpeciesAccumulationData {
  final int interval;
  final int speciesCount;

  SpeciesAccumulationData(this.interval, this.speciesCount);
}
