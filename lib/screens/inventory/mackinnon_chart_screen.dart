import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:xolmis/generated/l10n.dart';

import '../../data/models/inventory.dart';

class MackinnonChartScreen extends StatelessWidget {
  final List<Inventory> selectedInventories;

  const MackinnonChartScreen({super.key, required this.selectedInventories});

  @override
  Widget build(BuildContext context) {
    final accumulatedSpeciesData = _prepareAccumulatedSpeciesData(selectedInventories);

    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).speciesAccumulationCurve),
      ),
      body: SafeArea(
        child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: LineChart(
          LineChartData(
            // minX: 0,
            maxX: selectedInventories.length.toDouble() - 1,
            // minY: 0,
            // maxY: accumulatedSpeciesData.isNotEmpty
            //     ? accumulatedSpeciesData.map((data) => data.y).reduce((a, b) => a > b ? a : b)
            //     : 0,
            lineBarsData: [
              LineChartBarData(
                spots: accumulatedSpeciesData,
                isCurved: false,
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.deepPurple
                    : Colors.deepPurple[200],
                barWidth: 2,
                isStrokeCapRound: true,
                dotData: FlDotData(show: true),
                belowBarData: BarAreaData(
                  show: true,
                  color: Colors.deepPurpleAccent.withAlpha(30),
                ),
              ),
            ],
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                axisNameWidget: Text(S.current.inventories),
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index >= 0 && index < selectedInventories.length) {
                      final parts = selectedInventories[index].id.split('-');
                      final listNumber = parts.length > 1
                          ? parts.last
                          : selectedInventories[index].id;
                      return Text(listNumber);
                    } else {
                      return Text('');
                    }
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
            gridData: FlGridData(show: false, horizontalInterval: 1, verticalInterval: 1),
            borderData: FlBorderData(
              show: true,
              border: Border.all(color: Colors.grey, width: 1),
            ),
          ),
        ),
      ),
      ),
    );
  }

  List<FlSpot> _prepareAccumulatedSpeciesData(List<Inventory> selectedInventories) {
    final speciesSet = <String>{};
    final accumulatedSpeciesData = <FlSpot>[];

    for (var i = 0; i < selectedInventories.length; i++) {
      final inventory = selectedInventories[i];
      inventory.speciesList.where((species) => speciesSet.add(species.name));
      accumulatedSpeciesData.add(FlSpot(i.toDouble(), speciesSet.length.toDouble()));
    }

    return accumulatedSpeciesData;
  }
}