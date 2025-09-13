import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:xolmis/generated/l10n.dart';

import '../../data/models/inventory.dart';

class SpeciesCountChartScreen extends StatelessWidget {
  final List<Inventory> selectedInventories;

  const SpeciesCountChartScreen({super.key, required this.selectedInventories});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.current.speciesCounted),
      ),
      body: SafeArea(
        child: Center(
        child: Container(
          // height: 400,
          padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 56.0),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: (selectedInventories.map((inventory) => inventory.speciesList.length).reduce((a, b) => a > b ? a : b) / 10).ceil() * 10.0,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      rod.toY.toString(),
                      TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  axisNameWidget: Text(S.current.inventories),
                  sideTitles: SideTitles(
                  showTitles: true,
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
                axisNameWidget: Text(S.current.speciesCounted),
                sideTitles: SideTitles(
                  showTitles: true,
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
              barGroups: selectedInventories
                  .asMap()
                  .map((index, inventory) => MapEntry(
                        index,
                        BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: inventory.speciesList.length.toDouble(),
                              width: 16,
                              borderRadius: BorderRadius.circular(4),
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
              border: Border.all(color: Colors.grey, width: 1),
            ),
            ),
          ),
        ),
      ),
      ),
    );
  }
}
