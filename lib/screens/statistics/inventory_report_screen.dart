import 'dart:io';
import 'dart:convert';
import 'package:material_ui/material_ui.dart';

import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:xolmis/generated/l10n.dart';
import 'package:xolmis/utils/utils.dart';

import '../../data/models/inventory.dart';
import '../../providers/inventory_provider.dart';
import '../../utils/themes.dart';

/// Builds a cross-inventory species report and allows CSV export.
class InventoryReportScreen extends StatefulWidget {
  final List<Inventory> selectedInventories;

  const InventoryReportScreen({super.key, required this.selectedInventories});

  @override
  State<InventoryReportScreen> createState() => _InventoryReportScreenState();
}

class _InventoryReportScreenState extends State<InventoryReportScreen> {
  late final Future<List<Inventory>> _future;

  @override
  void initState() {
    super.initState();
    _future = Provider.of<InventoryProvider>(context, listen: false)
        .loadInventoriesDetails(widget.selectedInventories.map((e) => e.id).toList());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FutureBuilder<List<Inventory>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
              title: Text(S.of(context).reportSpeciesByInventory),
            ),
            body: const Center(
              child: CircularProgressIndicator(
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: Text(S.of(context).reportSpeciesByInventory),
            ),
            body: Center(
              child: Text(snapshot.error.toString()),
            ),
          );
        }

        final inventories = snapshot.data ?? [];
        // Load the species list and generate the report data
        final speciesSet = _getSpeciesList(inventories);
        final reportData = _generateReportData(speciesSet, inventories);

        return Scaffold(
          appBar: AppBar(
            title: Text(S.of(context).reportSpeciesByInventory),
            actions: [
              // Option to export the report to a CSV file
              IconButton(
                icon: const Icon(Icons.share_outlined),
                onPressed: () async {
                  await _exportReportToCsv(context, reportData, inventories);
                },
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
              Expanded(
            child:
            SingleChildScrollView(
              padding: const EdgeInsets.all(8),
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                // Build table with the report data
                child: DataTable(
                  columnSpacing: 16,
                  horizontalMargin: 8,
                  headingRowHeight: 38,
                  dataRowMinHeight: 28,
                  dataRowMaxHeight: 32,
                  headingRowColor: WidgetStateProperty.all(
                    isDark
                        ? Colors.grey.shade900
                        : XolmisColors.surfaceVariant.withValues(alpha: 0.5),
                  ),
                  columns: _buildColumns(inventories),
                  rows: _buildRows(speciesSet, reportData),
                ),
              ),
            ),
              ),
            Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
            padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.white,
        border: Border.all(color: isDark ? Colors.grey.shade800 : XolmisColors.borderSubtle),
        borderRadius: BorderRadius.circular(16),
        shape: BoxShape.rectangle,
        ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Text(
          //   'Legenda',
          //   style: const TextStyle(
          //     fontSize: 12,
          //     fontWeight: FontWeight.bold,
          //   ),
          // ),
          // const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'X',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                S.of(context).presenceWithinSample,
                style: const TextStyle(
                  fontSize: 12,
                ),
              ),
              Text(
                'O',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                S.of(context).presenceOutsideSample,
                style: const TextStyle(
                  fontSize: 12,
                ),
              ),
            ],
          ),
          Text(
            S.of(context).parenthesisIsOutsideSample,
            style: const TextStyle(
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            S.of(context).firstOccurrenceIsHighlighted,
            style: const TextStyle(
              fontSize: 12,
            ),
          ),
        ],
        ),
        ),
            ),
            ],
            ),
          ),
        );
      },
    );
  }

  // Load the species list from the selected inventories
  /// Collects and sorts distinct species names from the selected inventories.
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
  /// Creates table rows for species presence/abundance across inventories.
  List<List<dynamic>> _generateReportData(List<String> speciesSet, List<Inventory> inventories) {
    final reportData = <List<dynamic>>[];

    for (final species in speciesSet) {
      final conservationStatus = allSpeciesConservationStatus[species] ?? '';
      final row = <dynamic>[species, conservationStatus];
      int totalIndividuals = 0;
      int inventoriesWithSpecies = 0;

      for (final inventory in inventories) {
        // Find the species in the inventory
        final speciesInInventory = inventory.speciesList.firstWhere(
          (s) => s.name == species,
          orElse: () => Species(name: '', count: 0, inventoryId: inventory.id, isOutOfInventory: false),
        );

        if (speciesInInventory.name.isNotEmpty) {
          inventoriesWithSpecies++;
          // Add the species count to the row
          final speciesCount = speciesInInventory.count;
          // Add 'X' if the species is in the inventory, 'O' if it is out of inventory, if count is 0
          if (speciesCount > 0) {
            if (speciesInInventory.isOutOfInventory) {
              row.add('($speciesCount)');
            } else {
              row.add(speciesCount);
            }
            totalIndividuals += speciesCount;
          } else {
            if (speciesInInventory.isOutOfInventory) {
              row.add('O');
            } else {
              row.add('X');
            }
          }
        } else {
          row.add('');
        }
      }

      row.add(totalIndividuals);
      final double frequency = inventories.isNotEmpty
          ? (inventoriesWithSpecies / inventories.length) * 100
          : 0.0;
      row.add('${frequency.toStringAsFixed(1)}%');
      reportData.add(row);
    }

    // Add the total species row
    final totalSpeciesRow = <dynamic>['${S.of(context).totalSpecies}: ${speciesSet.length}', ''];
    for (final inventory in inventories) {
      var totalSpeciesWithinSample = 0;
      var totalSpeciesOutsideSample = 0;
      for (final species in inventory.speciesList) {
        if (species.isOutOfInventory) {
          totalSpeciesOutsideSample = totalSpeciesOutsideSample + 1;
        } else {
          totalSpeciesWithinSample = totalSpeciesWithinSample + 1;
        }
      }
      if (totalSpeciesOutsideSample > 0) {
        totalSpeciesRow.add('$totalSpeciesWithinSample + ($totalSpeciesOutsideSample)');
      } else {
        totalSpeciesRow.add(totalSpeciesWithinSample.toString());
      }
    }
    totalSpeciesRow.add(reportData.fold(0, (sum, row) => sum + (row[row.length - 2] as int)).toString());
    totalSpeciesRow.add('');

    reportData.add(totalSpeciesRow);

    return reportData;
  }

  // Build the columns for the DataTable
  /// Builds DataTable headers for species, inventories, and totals.
  List<DataColumn> _buildColumns(List<Inventory> inventories) {
    final headerLabels = _buildHeaderLabels(inventories);
    return headerLabels.map((label) => DataColumn(
        label: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        )
      )
    ).toList();
  }

  /// Builds plain-text header labels for table and CSV export.
  List<String> _buildHeaderLabels(List<Inventory> inventories) {
    final labels = <String>[S.of(context).species(2), S.of(context).conservationStatus];

    for (final inventory in inventories) {
      // Remove the date from the inventory ID
      final parts = inventory.id.split('-');
      final displayId = parts.length > 1 ? '${parts.first}-${parts[1]}-${parts.last}' : inventory.id;
      labels.add(displayId);
    }

    labels.add(S.of(context).totalIndividuals);
    labels.add(S.of(context).relativeFrequency);

    return labels;
  }

  /// Builds styled rows for the inventory species report table.
  List<DataRow> _buildRows(List<String> speciesList, List<List<dynamic>> reportData) {
    return reportData.asMap().entries.map((entry) {
      int rowIndex = entry.key;
      List<dynamic> row = entry.value;

      // Ignora a última linha (que é o total de espécies) para o destaque
      bool isTotalRow = rowIndex == reportData.length - 1;

      int? firstOccurrenceIndex;
      if (!isTotalRow) {
        // Encontra o índice da primeira coluna de inventário (após espécie e status) que não está vazia
        for (int i = 2; i < row.length - 2; i++) {
          if (row[i].toString().isNotEmpty) {
            firstOccurrenceIndex = i;
            break;
          }
        }
      }

      return DataRow(
        color: WidgetStateProperty.all(
          isTotalRow
              ? Theme.of(context).brightness == Brightness.dark
                ? Colors.grey.shade900
                : XolmisColors.surfaceVariant.withValues(alpha: 0.5)
              : Colors.transparent,
        ),
        cells: row.asMap().entries.map((cellEntry) {
          int colIndex = cellEntry.key;
          String cellValue = cellEntry.value.toString();

          // Estilo padrão
          TextStyle style = const TextStyle(
            fontSize: 11,
          );

          // Highlights species not found
          if (colIndex == 0 && rowIndex != reportData.length - 1) {
            style = const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
            );
            if (!allSpeciesNames.contains(cellEntry.value.toString())) {
              style = const TextStyle(
                fontSize: 11,
                color: Colors.red,
                fontWeight: FontWeight.w500,
              );
            }
          }

          // Coloring for conservation status column (colIndex == 1)
          if (colIndex == 1 && !isTotalRow && cellValue.isNotEmpty && cellValue != '-') {
            final upperStatus = cellValue.toUpperCase();
            Color statusColor;
            switch (upperStatus) {
              case 'CR':
                statusColor = Colors.red[900]!;
                break;
              case 'EN':
                statusColor = Colors.red;
                break;
              case 'VU':
                statusColor = Colors.orange[900]!;
                break;
              case 'NT':
                statusColor = Colors.amber[700]!;
                break;
              case 'DD':
                statusColor = Colors.grey[700]!;
                break;
              case 'LC':
                statusColor = Colors.green[700]!;
                break;
              default:
                statusColor = Theme.of(context).colorScheme.onSurface;
                break;
            }
            style = TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: statusColor,
            );
          }

          // Aplica o destaque se for a primeira ocorrência
          if (colIndex == firstOccurrenceIndex) {
            style = const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: XolmisColors.primary,
            );
          }

          if (colIndex == reportData[rowIndex].length - 1) {
            style = const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
            );
          }

          if (isTotalRow) {
            style = const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
            );
          }

          if (cellValue == '') {
            style = const TextStyle(
              fontSize: 11,
              color: Colors.grey,
            );
          }

          return DataCell(
            Container(
              alignment: colIndex == 0
                  ? Alignment.centerLeft
                  : colIndex == 1
                      ? Alignment.center
                      : Alignment.centerRight,
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colIndex == firstOccurrenceIndex
                    ? XolmisColors.primaryContainer.withValues(alpha: 0.4)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                cellValue == '' ? '-' : cellValue,
                style: style,
              ),
            ),
          );
        }).toList(),
      );
    }).toList();
  }

  // Export the report data to a CSV file
  Future<void> _exportReportToCsv(BuildContext context, List<List<dynamic>> reportData, List<Inventory> inventories) async {
    bool isDialogShown = false;

    final hasSpeciesRows = reportData.length > 1;
    if (inventories.isEmpty || !hasSpeciesRows) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).noDataToExport)),
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
                  const CircularProgressIndicator(),
                  const SizedBox(width: 16),
                  Text(S.of(context).exporting),
                ],
              ),
            ),
          );
        },
      );
      isDialogShown = true;

      final headers = _buildHeaderLabels(inventories);
      final csvData = [headers, ...reportData];
      final csv = Csv().encode(csvData);
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = '${directory.path}/inventory_report_$timestamp.csv';
      final file = File(path);
      await file.writeAsString(csv, encoding: utf8, flush: true);

      if (isDialogShown) {
        if (context.mounted) {
          Navigator.of(context).pop();
        }
        isDialogShown = false; // Dialog is now closed
      }

      await SharePlus.instance.share(
        ShareParams(files: [XFile(path)], text: S.of(context).reportSpeciesByInventory)
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        persist: true,
              showCloseIcon: true,
        backgroundColor: Theme.of(context).colorScheme.error,
        content: Text(S.of(context).errorExportingInventory(2, error.toString())),
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