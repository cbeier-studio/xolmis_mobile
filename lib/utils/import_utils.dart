import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:xolmis/generated/l10n.dart';

import '../data/models/inventory.dart';

import '../providers/inventory_provider.dart';

Future<void> importInventoryFromJson(BuildContext context) async {
  bool isDialogShown = false;
  int successfullyImportedCount = 0;
  int totalInventoriesToImport = 0;
  List<String> importErrors = [];
  
  try {
    // Pick a JSON file
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result != null && result.files.single.path != null) {
      final filePath = result.files.single.path!;
      final file = File(filePath);

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
                  Text(S.current.importingInventory),
                ],
              ),
            ),
          );
        },
      );
      isDialogShown = true;

      // Read the JSON file
      final jsonString = await file.readAsString();
      final jsonData = jsonDecode(jsonString);

      final inventoryProvider = Provider.of<InventoryProvider>(context, listen: false);
      List<Inventory> inventoriesToImport = [];

      if (jsonData is List) {
        // Case 1: JSON is an array of inventories
        totalInventoriesToImport = jsonData.length;
        for (final item in jsonData) {
          if (item is Map<String, dynamic>) {
            try {
              inventoriesToImport.add(Inventory.fromJson(item));
            } catch (e) {
              importErrors.add("Erro ao parsear item do array: ${e.toString()} \nItem: $item");
            }
          } else {
            importErrors.add("Item inesperado no array JSON: $item");
          }
        }
      } else if (jsonData is Map<String, dynamic>) {
        // Case 2: JSON is an inventory only (or have a key "inventories")
        if (jsonData.containsKey('inventories') && jsonData['inventories'] is List) {
          // Subcase 2.1: JSON have a key "inventories" and it's a list
          final List<dynamic> inventoriesJsonList = jsonData['inventories'];
          totalInventoriesToImport = inventoriesJsonList.length;
          for (final item in inventoriesJsonList) {
            if (item is Map<String, dynamic>) {
              try {
                inventoriesToImport.add(Inventory.fromJson(item));
              } catch (e) {
                importErrors.add("Erro ao parsear item da lista 'inventories': ${e.toString()} \nItem: $item");
              }
            } else {
              importErrors.add("Item inesperado na lista 'inventories': $item");
            }
          }
        } else {
          // Subcase 2.2: JSON is an inventory only
          totalInventoriesToImport = 1;
          try {
            inventoriesToImport.add(Inventory.fromJson(jsonData));
          } catch (e) {
            importErrors.add("Erro ao parsear objeto JSON único: ${e.toString()}");
          }
        }
      } else {
        throw FormatException(S.current.invalidJsonFormatExpectedObjectOrArray);
      }

      if (!context.mounted) return;
      // Save the inventory to the database
      for (final inventory in inventoriesToImport) {
        final success = await inventoryProvider.importInventory(inventory);
        if (success) {
          successfullyImportedCount++;
        } else {
          importErrors.add("${S.current.failedToImportInventoryWithId(inventory.id)}");
        }
      }

      // Close the loading dialog
      if (isDialogShown) {
        if (context.mounted) {
          Navigator.of(context).pop();
        }
        isDialogShown = false; // Dialog is now closed
      }

      if (!context.mounted) return;

      // Show import summary
      String summaryMessage;
      if (importErrors.isEmpty) {
        summaryMessage = S.current.inventoriesImportedSuccessfully(successfullyImportedCount);
      } else {
        summaryMessage = S.current.importCompletedWithErrors(successfullyImportedCount, importErrors.length);
        // Opcional: mostrar os erros detalhados em um diálogo de expansão ou log
        debugPrint("Erros de importação: \n${importErrors.join('\n')}");
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(summaryMessage),
          duration: Duration(seconds: importErrors.isEmpty ? 2 : 5),
        ),
      );
    } else {
      if (isDialogShown && context.mounted) Navigator.of(context).pop();
      isDialogShown = false;
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.current.noFileSelected)),
      );
    }
  } catch (error) {
    debugPrint('Error importing inventory: $error');
    if (isDialogShown && context.mounted) Navigator.of(context).pop();
    isDialogShown = false;

    if (!context.mounted) return;
    String errorMessage = '${S.current.errorImportingInventory}: ${error.toString()}';
    if (error is FormatException) {
      errorMessage = S.current.errorImportingInventoryWithFormatError(error.message);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outlined, color: Colors.red),
            SizedBox(width: 8),
            Text(errorMessage),
          ],
        ),
        duration: Duration(seconds: 5),
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