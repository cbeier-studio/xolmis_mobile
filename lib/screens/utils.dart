import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/inventory.dart';
import '../data/database/repositories/inventory_repository.dart';
import '../providers/species_provider.dart';

import 'inventory/add_inventory_screen.dart';

void Function(String)? onInventoryStopped;

Future<List<String>> loadSpeciesSearchData() async {
  final jsonString = await rootBundle.loadString('assets/species_data.json');
  final jsonData = json.decode(jsonString) as List<dynamic>;
  return jsonData.map((species) => species['scientificName'].toString())
      .toList();
}

String getNextInventoryId(String currentId) {
  // 1. Split the string in parts using '-' as delimiter
  final parts = currentId.split('-');

  // 2. Check if it has at least one part
  if (parts.isEmpty) {
    return currentId; // Return the original ID if it has no parts
  }

  // 3. Get the last part of the string
  var lastPart = parts.last;

  // 4. Extract the last two digits as integer
  var numericPart = int.tryParse(lastPart.substring(max(0, lastPart.length - 2)));

  // 5. Check if the extraction was successful
  if (numericPart == null) {
    return currentId; // Return the original ID if the extraction was unsuccessful
  }

  // 6. Increment the number in 1
  numericPart++;

  // 7. Replace the last two digits by the new formatted number
  lastPart = lastPart.substring(0, max(0, lastPart.length - 2)) + numericPart.toString().padLeft(2, '0');

  // 8. Rebuild the string with the last part updated
  parts[parts.length - 1] = lastPart;
  final nextId = parts.join('-');

  return nextId;
}

void checkMackinnonCompletion(BuildContext context, Inventory inventory, InventoryRepository inventoryRepository) {
  final speciesProvider = Provider.of<SpeciesProvider>(context, listen: false);
  final speciesList = speciesProvider.getSpeciesForInventory(inventory.id);
  // print('speciesList: ${speciesList.length} ; maxSpecies: ${inventory.maxSpecies}');
  if (inventory.type == InventoryType.invMackinnonList &&
      speciesList.length == inventory.maxSpecies - 1) {
    _showMackinnonDialog(context, inventory, inventoryRepository);
  }
}

void _showMackinnonDialog(BuildContext context, Inventory inventory, InventoryRepository inventoryRepository) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Inventário Concluído'),
        content: Text(
            'O inventário atingiu o número máximo de espécies. Deseja iniciar a próxima lista ou encerrar as listas?'),
        actions: [
          TextButton(
            child: Text('Iniciar Próxima Lista'),
            onPressed: () async {
              // Finish the inventory and open the screen to add inventory
              var maxSpecies = inventory.maxSpecies;
              await inventory.stopTimer(inventoryRepository);
              // onInventoryUpdated(inventory);
              Navigator.pop(context, true);
              Navigator.of(context).pop();
              final nextInventoryId = getNextInventoryId(inventory.id);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddInventoryScreen(
                  initialInventoryId: nextInventoryId,
                  initialInventoryType: InventoryType.invMackinnonList,
                  initialMaxSpecies: maxSpecies,
                )
                ),
              );
            },
          ),
          TextButton(
            child: Text('Encerrar'),
            onPressed: () async {
              // Finish the inventory and go back to the Home screen
              await inventory.stopTimer(inventoryRepository);
              // onInventoryUpdated(inventory);
              Navigator.pop(context, true);
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

Future<ThemeMode> getThemeMode() async {
  final prefs = await SharedPreferences.getInstance();
  final themeModeIndex = prefs.getInt('themeMode') ?? 0; // 0 is the default value for ThemeMode.system
  return ThemeMode.values[themeModeIndex];
}

/// Determine the current position of the device.
///
/// When the location services are not enabled or permissions
/// are denied the `Future` will return an error.
Future<Position> _determinePosition() async {
  bool serviceEnabled;
  LocationPermission permission;

  // Test if location services are enabled.
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    // Location services are not enabled don't continue
    // accessing the position and request users of the
    // App to enable the location services.
    return Future.error('Location services are disabled.');
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      // Permissions are denied, next time you could try
      // requesting permissions again (this is also where
      // Android's shouldShowRequestPermissionRationale
      // returned true. According to Android guidelines
      // your App should show an explanatory UI now.
      return Future.error('Location permissions are denied');
    }
  }

  if (permission == LocationPermission.deniedForever) {
    // Permissions are denied forever, handle appropriately.
    return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.');
  }

  // When we reach here, permissions are granted and we can
  // continue accessing the position of the device.
  return await Geolocator.getCurrentPosition();
}

Future<Position?> getPosition() async {
  try {
    return await _determinePosition();
  } catch (e) {
    return null;
  }
}

String? getInventoryTypeLetter(InventoryType inventoryType) {
  switch (inventoryType) {
    case InventoryType.invBanding:
      return 'B';
    case InventoryType.invCasual:
      return 'C';
    case InventoryType.invMackinnonList:
      return 'L';
    case InventoryType.invTransectionCount:
      return 'T';
    case InventoryType.invPointCount:
      return 'P';
    default:
      return null;
  }
}

class CommaToDotTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.replaceAll(',', '.'),
      selection: newValue.selection,
    );
  }
}


