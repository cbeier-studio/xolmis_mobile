import 'dart:io';
import 'package:flutter/material.dart';

import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:xolmis/generated/l10n.dart';

import '../../data/models/inventory.dart';

class InventoryReportScreen extends StatelessWidget {
  final List<Inventory> selectedInventories;

  const InventoryReportScreen({super.key, required this.selectedInventories});

  @override
  Widget build(BuildContext context) {
    final speciesList = _getSpeciesList(selectedInventories);
    final reportData = _generateReportData(speciesList, selectedInventories);

    return Scaffold(
      appBar: AppBar(
        title: Text(S.current.reportSpeciesByInventory),
        actions: [
          IconButton(
            icon: Icon(Icons.file_download_outlined),
            onPressed: () async {
              await _exportReportToCsv(reportData);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: _buildColumns(selectedInventories),
          rows: _buildRows(speciesList, reportData),
        ),
      ),
    );
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

  List<List<dynamic>> _generateReportData(List<String> speciesList, List<Inventory> inventories) {
    final reportData = <List<dynamic>>[];

    for (final species in speciesList) {
      final row = <dynamic>[species];
      int totalIndividuals = 0;

      for (final inventory in inventories) {
        final speciesInInventory = inventory.speciesList.firstWhere(
          (s) => s.name == species,
          orElse: () => Species(name: '', count: 0, inventoryId: inventory.id, isOutOfInventory: false),
        );

        if (speciesInInventory.name.isNotEmpty) {
          final speciesCount = speciesInInventory.count;
          row.add(speciesCount > 0 ? speciesCount : 'X');
          totalIndividuals += speciesCount;
        } else {
          row.add('');
        }
      }

      row.add(totalIndividuals);
      reportData.add(row);
    }

    final totalSpeciesRow = [S.current.totalSpecies];
    for (final inventory in inventories) {
      totalSpeciesRow.add(inventory.speciesList.length.toString());
    }
    totalSpeciesRow.add(reportData.fold(0, (sum, row) => sum + (row.last as int)).toString());

    reportData.add(totalSpeciesRow);

    return reportData;
  }

  List<DataColumn> _buildColumns(List<Inventory> inventories) {
    final columns = <DataColumn>[
      DataColumn(label: Text(S.current.species(2))),
    ];

    for (final inventory in inventories) {
      final parts = inventory.id.split('-');
      final displayId = parts.length > 1 ? '${parts.first}-${parts.last}' : inventory.id;
      columns.add(DataColumn(label: Text(displayId)));
    }

    columns.add(DataColumn(label: Text(S.current.totalIndividuals)));

    return columns;
  }

  List<DataRow> _buildRows(List<String> speciesList, List<List<dynamic>> reportData) {
    return reportData.map((row) {
      return DataRow(cells: row.map((cell) => DataCell(Text(cell.toString()))).toList());
    }).toList();
  }

  Future<void> _exportReportToCsv(List<List<dynamic>> reportData) async {
    final csv = const ListToCsvConverter().convert(reportData);
    final directory = await getExternalStorageDirectory();
    final path = '${directory?.path}/inventory_report_${DateTime.now().toIso8601String()}.csv';
    final file = File(path);
    await file.writeAsString(csv);

    await Share.shareXFiles([XFile(path)], text: S.current.reportSpeciesByInventory);
  }
}