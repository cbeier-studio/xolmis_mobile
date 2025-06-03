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

      // Convert JSON data to Inventory object
      final inventory = Inventory.fromJson(jsonData);

      if (!context.mounted) return;
      final inventoryProvider = Provider.of<InventoryProvider>(context, listen: false);
      // Save the inventory to the database
      final success = await inventoryProvider.importInventory(inventory);

      // Close the loading dialog
      if (isDialogShown) {
        if (context.mounted) {
          Navigator.of(context).pop();
        }
        isDialogShown = false; // Dialog is now closed
      }

      if (!context.mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.current.inventoryImportedSuccessfully)),
        );
      } 
      else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.current.inventoryImportFailed)),
        );
      }
    } else {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.current.noFileSelected)),
      );
    }
  } catch (error) {
    debugPrint('Error importing inventory: $error');
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Row(
        children: [
          Icon(Icons.error_outlined, color: Colors.red),
          SizedBox(width: 8),
          Text('${S.current.errorImportingInventory} {$error}'),
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