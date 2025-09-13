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
    // Load the species list and generate the report data
    final speciesSet = _getSpeciesList(selectedInventories);
    final reportData = _generateReportData(speciesSet, selectedInventories);

    return Scaffold(
      appBar: AppBar(
        title: Text(S.current.reportSpeciesByInventory),
        actions: [
          // Option to export the report to a CSV file
          IconButton(
            icon: Icon(Icons.file_upload_outlined),
            onPressed: () async {
              await _exportReportToCsv(context, reportData);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          // Build table with the report data
          child: DataTable(
            columns: _buildColumns(selectedInventories),
            rows: _buildRows(speciesSet, reportData),
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

  // Generate the report data
  List<List<dynamic>> _generateReportData(List<String> speciesSet, List<Inventory> inventories) {
    final reportData = <List<dynamic>>[];

    for (final species in speciesSet) {
      final row = <dynamic>[species];
      int totalIndividuals = 0;

      for (final inventory in inventories) {
        // Find the species in the inventory
        final speciesInInventory = inventory.speciesList.firstWhere(
          (s) => s.name == species,
          orElse: () => Species(name: '', count: 0, inventoryId: inventory.id, isOutOfInventory: false),
        );

        if (speciesInInventory.name.isNotEmpty) {
          // Add the species count to the row
          final speciesCount = speciesInInventory.count;
          // Add 'X' if the species is in the inventory, 'O' if it is out of inventory, if count is 0
          row.add(speciesCount > 0 ? speciesCount : !speciesInInventory.isOutOfInventory ? 'X' : 'O');
          // Add the species count to the total
          totalIndividuals += speciesCount;
        } else {
          row.add('');
        }
      }

      row.add(totalIndividuals);
      reportData.add(row);
    }

    // Add the total species row
    final totalSpeciesRow = ['${S.current.totalSpecies}: ${speciesSet.length}'];
    for (final inventory in inventories) {
      totalSpeciesRow.add(inventory.speciesList.length.toString());
    }
    totalSpeciesRow.add(reportData.fold(0, (sum, row) => sum + (row.last as int)).toString());

    reportData.add(totalSpeciesRow);

    return reportData;
  }

  // Build the columns for the DataTable
  List<DataColumn> _buildColumns(List<Inventory> inventories) {
    final columns = <DataColumn>[
      DataColumn(label: Text(S.current.species(2))),
    ];

    for (final inventory in inventories) {
      // Remove the date from the inventory ID
      final parts = inventory.id.split('-');
      final displayId = parts.length > 1 ? '${parts.first}-${parts[1]}-${parts.last}' : inventory.id;
      columns.add(DataColumn(label: Text(displayId)));
    }

    columns.add(DataColumn(label: Text(S.current.totalIndividuals)));

    return columns;
  }

  // Build the rows for the DataTable
  List<DataRow> _buildRows(List<String> speciesList, List<List<dynamic>> reportData) {
    return reportData.map((row) {
      return DataRow(cells: row.map((cell) => DataCell(Text(cell.toString()))).toList());
    }).toList();
  }

  // Export the report data to a CSV file
  Future<void> _exportReportToCsv(BuildContext context, List<List<dynamic>> reportData) async {
    bool isDialogShown = false;

    if (selectedInventories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.current.noDataToExport)),
      );
      return;
    }

    try {
      // Show a loading dialog
      if (!context.mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(year2023: false,),
                  SizedBox(width: 16),
                  Text(S.current.exporting),
                ],
              ),
            ),
          );
        },
      );
      isDialogShown = true;

      final headers = _buildColumns(selectedInventories).map((column) => column.label.toString()).toList();
      final csvData = [headers, ...reportData];
      final csv = const ListToCsvConverter().convert(csvData);
      final directory = await getExternalStorageDirectory();
      final path = '${directory?.path}/inventory_report_${DateTime.now().toIso8601String()}.csv';
      final file = File(path);
      await file.writeAsString(csv);
      
      if (isDialogShown) {
        if (context.mounted) {
          Navigator.of(context).pop();
        }
        isDialogShown = false; // Dialog is now closed
      }

      await SharePlus.instance.share(
        ShareParams(files: [XFile(path)], text: S.current.reportSpeciesByInventory)
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Row(
        children: [
          Icon(Icons.error_outlined, color: Colors.red),
          SizedBox(width: 8),
          Text(S.current.errorExportingInventory(2, error.toString())),
        ],
        ),
        ),
      );
    } finally {
      // Ensure the dialog is always closed if it was shown and an error occurred,
      // or if the function returned early while the dialog was up.
      if (isDialogShown && context.mounted) {
        Navigator.of(context).pop();
      }
    }
  }  
}