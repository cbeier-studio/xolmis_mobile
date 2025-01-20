import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:xolmis/generated/l10n.dart';

import '../data/models/inventory.dart';

import '../providers/inventory_provider.dart';

Future<void> importInventoryFromJson(BuildContext context) async {
  
  try {
    // Pick a JSON file
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result != null && result.files.single.path != null) {
      final filePath = result.files.single.path!;
      final file = File(filePath);

      // Read the JSON file
      final jsonString = await file.readAsString();
      final jsonData = jsonDecode(jsonString);

      // Convert JSON data to Inventory object
      final inventory = Inventory.fromJson(jsonData);

      final inventoryProvider = Provider.of<InventoryProvider>(context, listen: false);
      // Save the inventory to the database
      final success = await inventoryProvider.importInventory(inventory);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.current.inventoryImportedSuccessfully)),
        );
      } 
      // else {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(content: Text('Failed to import inventory')),
      //   );
      // }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.current.noFileSelected)),
      );
    }
  } catch (error) {
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
  }
}