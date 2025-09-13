import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:xolmis/generated/l10n.dart';

import '../../data/models/inventory.dart';

class IndividualsCountChartScreen extends StatelessWidget {
  final List<Inventory> selectedInventories;

  const IndividualsCountChartScreen({
    super.key, 
    required this.selectedInventories,
  });

  @override
  Widget build(BuildContext context) {
    final species = _getSpeciesList(selectedInventories);
    final barsData = _populateInventoryCounts(species, selectedInventories);
    return Scaffold(
      appBar: AppBar(
        title: Text(S.current.individualsCounted),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 56.0),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: (barsData.expand((i) => i).reduce((a, b) => a > b ? a : b) / 10).ceil() * 10.0,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final speciesName = species[group.x.toInt()];
                    return BarTooltipItem(
                      '$speciesName\n',
                      TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      children: <TextSpan>[
                        TextSpan(
                          text: rod.toY.toString(),
                          style: TextStyle(
                            color: Colors.yellow,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  axisNameWidget: Text(S.current.species(2)),
                  sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
  //                 getTitlesWidget: (value, meta) {                    
  //                   final speciesName = species[value.toInt()];
  // final words = speciesName.split(' ');

  // if (words.length >= 2) {
  //   final firstWord = words[0];
  //   final secondWord = words[1];
  //   final displayText = '${firstWord.substring(0, 3)}${secondWord.substring(0, 3)}';
  //   return Text(displayText);
  // } else {
  //   // Caso o nome da espécie não tenha duas palavras, exiba o nome completo
  //   return Text(speciesName, overflow: TextOverflow.fade,);
  // }
  //                 },
                ),
                ),
                leftTitles: AxisTitles(
                axisNameWidget: Text(S.current.individualsCounted),
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
              barGroups: _buildBarGroups(species, barsData),
            ),
          ),
        ),
      ),
    );
  }

  // Load the species list from the selected inventories
  List<String> _getSpeciesList(List<Inventory> inventories) {
    final speciesSet = <String>{};
    for (final inventory in inventories) {
      for (final species in inventory.speciesList) {
        speciesSet.add(species.name);
      }
    }
    return speciesSet.toList()..sort();
  }

  List<BarChartGroupData> _buildBarGroups(List<String> species, List<List<int>> inventoryCounts) {
    return List.generate(species.length, (i) => _buildBarGroup(i, inventoryCounts));
  }

  BarChartGroupData _buildBarGroup(int index, List<List<int>> inventoryCounts) {
    return BarChartGroupData(
      x: index,
      barRods: _buildBarRods(index, inventoryCounts),
      showingTooltipIndicators: [],
    );
  }

  List<BarChartRodData> _buildBarRods(int index, List<List<int>> inventoryCounts) {
    final colors = [
      Colors.blue,
      Colors.red,
      Colors.orange,
      Colors.purple,
      Colors.green,
      Colors.yellow,
      Colors.cyan,
      Colors.pink,
      Colors.teal,
      Colors.lime,
    ];

    return List.generate(inventoryCounts.length, (j) {
      if (index < inventoryCounts[j].length) {
        return BarChartRodData(
          toY: inventoryCounts[j][index].toDouble(),
          borderRadius: BorderRadius.circular(4),
          color: colors[j % colors.length],
          // width: 15,
        );
      } else {
        return BarChartRodData(
          toY: 0.0,
          borderRadius: BorderRadius.circular(4),
          color: colors[j % colors.length],
          // width: 15,
        );
      }
    });
  }

  List<List<int>> _populateInventoryCounts(List<String> speciesList, List<Inventory> inventories) {
  final inventoryCounts = List.generate(inventories.length, (_) => List<int>.filled(speciesList.length, 0));

  for (int i = 0; i < speciesList.length; i++) {
    final speciesName = speciesList[i];
    for (int j = 0; j < inventories.length; j++) {
      final inventory = inventories[j];
      final speciesInInventory = inventory.speciesList.firstWhere(
        (s) => s.name == speciesName,
        orElse: () => Species(name: '', count: 0, inventoryId: inventory.id, isOutOfInventory: false),
      );
      inventoryCounts[j][i] = speciesInInventory.count;
    }
  }

  return inventoryCounts;
}
}