import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:xolmis/generated/l10n.dart';

import '../../data/models/inventory.dart';

class SpeciesChartScreen extends StatelessWidget {
  final Inventory inventory;

  const SpeciesChartScreen({super.key, required this.inventory});

  @override
  Widget build(BuildContext context) {
    final speciesAccumulationData = _prepareSpeciesAccumulationData(inventory);

    final minX = 0.0;
    final maxX = speciesAccumulationData.isNotEmpty
        ? speciesAccumulationData.map((data) => data.interval.toDouble()).reduce((a, b) => a > b ? a : b)
        : 0.0;
    final maxY = speciesAccumulationData.isNotEmpty
        ? speciesAccumulationData.map((data) => data.speciesCount.toDouble()).reduce((a, b) => a > b ? a : b)
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).speciesAccumulationCurve),        
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: speciesAccumulationData.isEmpty
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
                  getTitlesWidget: (value, meta) {
                    final minutes = value.toInt() * 5;
                    return Text('$minutes');
                  },
                ),
              ),
              leftTitles: AxisTitles(
                axisNameWidget: Text(S.current.speciesAccumulated),
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    return Text(value.toInt().toString());
                  },
                ),
              ),
            ),
            gridData: FlGridData(show: false, horizontalInterval: 1, verticalInterval: 1),
            borderData: FlBorderData(
              show: true,
              border: Border.all(color: Colors.grey, width: 1),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: speciesAccumulationData
                    .map((data) => FlSpot(data.interval.toDouble(), data.speciesCount.toDouble()))
                    .toList(),
                isCurved: false,
                barWidth: 2,
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.deepPurple
                    : Colors.deepPurple[200],
                belowBarData: BarAreaData(show: false),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<SpeciesAccumulationData> _prepareSpeciesAccumulationData(Inventory inventory) {
    final speciesAccumulationData = <SpeciesAccumulationData>[];
    final speciesByInterval = <int, Set<String>>{};

    final startTime = inventory.startTime!;
    final currentTime = inventory.isFinished ? inventory.endTime! : DateTime.now();
    final totalElapsedMinutes = currentTime.difference(startTime).inMinutes;
    final totalIntervals = (totalElapsedMinutes / 5).ceil();

    for (final species in inventory.speciesList) {
      final sampleTime = species.sampleTime;

      if (sampleTime == null) {
        continue;
      }

      final elapsedMinutes = sampleTime.difference(startTime).inMinutes;
      final interval = elapsedMinutes ~/ 5; // Intervalo de 5 minutos

      if (!speciesByInterval.containsKey(interval)) {
        speciesByInterval[interval] = <String>{};
      }

      speciesByInterval[interval]!.add(species.name);
    }

    int cumulativeSpeciesCount = 0;
    final seenSpecies = <String>{};

    for (int i = 0; i <= totalIntervals; i++) {
      if (speciesByInterval.containsKey(i)) {
        for (final species in speciesByInterval[i]!) {
          if (!seenSpecies.contains(species)) {
            seenSpecies.add(species);
            cumulativeSpeciesCount++;
          }
        }
      }
      speciesAccumulationData.add(SpeciesAccumulationData(i * 5, cumulativeSpeciesCount));
    }

    return speciesAccumulationData;
  }
}

class SpeciesAccumulationData {
  final int interval;
  final int speciesCount;

  SpeciesAccumulationData(this.interval, this.speciesCount);
}
