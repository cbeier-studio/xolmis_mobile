import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';

import '../data/models/inventory.dart';
import '../data/database/repositories/inventory_repository.dart';
import '../providers/species_provider.dart';

import '../screens/inventory/add_inventory_screen.dart';
import '../generated/l10n.dart';

List<String> allSpeciesNames = [];

void Function(String)? onInventoryStopped;

Future<List<String>> loadSpeciesSearchData() async {
  final jsonString = await rootBundle.loadString('assets/species_data.json');
  final jsonData = json.decode(jsonString) as List<dynamic>;
  return jsonData.map((species) => species['scientificName'].toString())
      .toList();
}

bool speciesMatchesQuery(String speciesName, String query) {
  final String lowerSpeciesName = speciesName.toLowerCase();
  final String lowerQuery = query.toLowerCase();

  if (lowerQuery.isEmpty) {
    return true;
  }

  // 1. Match parts (query with spaces)
  if (lowerQuery.contains(' ')) {
    final queryParts = lowerQuery.split(' ').where((part) => part.isNotEmpty).toList();
    final speciesWords = lowerSpeciesName.split(' ').where((word) => word.isNotEmpty).toList();

    if (queryParts.isEmpty) {
      return true;
    }

    return queryParts.every((queryPart) {
      return speciesWords.any((speciesWord) => speciesWord.contains(queryPart));
    });
  }

  // 2. Special match of 4 or 6 characters (query without spaces)
  if (lowerQuery.length == 4 || lowerQuery.length == 6) {
    final words = lowerSpeciesName.split(' ');
    if (words.length >= 2) {
      final firstWord = words[0];
      final secondWord = words[1];

      final int firstPartLength = lowerQuery.length == 4 ? 2 : 3;

      if (lowerQuery.length >= firstPartLength * 2) {
        final firstQueryPart = lowerQuery.substring(0, firstPartLength);
        final secondQueryPart = lowerQuery.substring(firstPartLength);

        if (firstWord.startsWith(firstQueryPart) && secondWord.startsWith(secondQueryPart)) {
          return true;
        }
      }
    }
    if (lowerSpeciesName.contains(lowerQuery)) {
      return true;
    }
  }

  // 3. Standard match 'contains' (general fallback)
  return lowerSpeciesName.contains(lowerQuery);
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
      return AlertDialog.adaptive(
        title: Text(S.current.listFinished),
        content: Text(S.current.listFinishedMessage),
        actions: [
          TextButton(
            child: Text(S.current.startNextList),
            onPressed: () async {
              // Finish the inventory and open the screen to add inventory
              var maxSpecies = inventory.maxSpecies;
              await inventory.stopTimer(context, inventoryRepository);
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
            child: Text(S.current.finish),
            onPressed: () async {
              // Finish the inventory and go back to the Home screen
              await inventory.stopTimer(context, inventoryRepository);
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
  final LocationSettings locationSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    timeLimit: const Duration(seconds: 30),
  );

  return await Geolocator.getCurrentPosition(
    locationSettings: locationSettings,
  );
}

Future<Position?> _showManualCoordinatesDialog(BuildContext context) {
  final formKey = GlobalKey<FormState>();
  final latitudeController = TextEditingController();
  final longitudeController = TextEditingController();

  return showDialog<Position?>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return AlertDialog.adaptive(
        title: Text(S.of(dialogContext).enterCoordinates),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: latitudeController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: S.of(dialogContext).latitude,
                ),
                keyboardType: TextInputType.numberWithOptions(signed: true, decimal: true),
                inputFormatters: [
                  CommaToDotTextInputFormatter(),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return S.of(dialogContext).fieldCannotBeEmpty;
                  }
                  final lat = double.tryParse(value);
                  if (lat == null || lat < -90 || lat > 90) {
                    return S.of(dialogContext).invalidLatitude;
                  }
                  return null;
                },
              ),
              SizedBox(height: 8),
              TextFormField(
                controller: longitudeController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: S.of(dialogContext).longitude,
                ),
                keyboardType: TextInputType.numberWithOptions(signed: true, decimal: true),
                inputFormatters: [
                  CommaToDotTextInputFormatter(),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return S.of(dialogContext).fieldCannotBeEmpty;
                  }
                  final lon = double.tryParse(value);
                  if (lon == null || lon < -180 || lon > 180) {
                    return S.of(dialogContext).invalidLongitude;
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: Text(S.of(dialogContext).cancel),
            onPressed: () => Navigator.of(dialogContext).pop(null),
          ),
          TextButton(
            child: Text(S.of(dialogContext).save),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final now = DateTime.now();
                final position = Position(
                  latitude: double.parse(latitudeController.text),
                  longitude: double.parse(longitudeController.text),
                  timestamp: now,
                  accuracy: 0.0,
                  altitude: 0.0,
                  altitudeAccuracy: 0.0,
                  heading: 0.0,
                  headingAccuracy: 0.0,
                  speed: 0.0,
                  speedAccuracy: 0.0,
                );
                Navigator.of(dialogContext).pop(position);
              }
            },
          ),
        ],
      );
    },
  );
}

Future<Position?> getPosition(BuildContext context) async {
  try {
    return await _determinePosition();
  } catch (e) {
    debugPrint("Error getting position: $e");
    if (!context.mounted) return null;

    final choice = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog.adaptive(
          title: Text(S.of(dialogContext).locationError),
          content: Text(S.of(dialogContext).couldNotGetGpsLocation),
          actions: [
            TextButton(
              child: Text(S.of(dialogContext).continueWithout),
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            TextButton(
              child: Text(S.of(dialogContext).enterManually),
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );

    if (choice == true) {
      if (!context.mounted) return null;
      return await _showManualCoordinatesDialog(context);
    } else {
      return null;
    }
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
    case InventoryType.invTransectionDistance:
      return 'T';
    case InventoryType.invPointCount:
      return 'P';
    case InventoryType.invPointDistance:
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


