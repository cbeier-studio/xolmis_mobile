import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/inventory.dart';
import '../data/daos/inventory_dao.dart';
import '../providers/species_provider.dart';

import '../screens/inventory/add_inventory_screen.dart';
import '../core/core_consts.dart';
import '../generated/l10n.dart';

List<String> allSpeciesNames = [];

void Function(String)? onInventoryStopped;

Future<SupportedCountry> getCountrySetting() async {
  final prefs = await SharedPreferences.getInstance();
  final countryCode = prefs.getString('user_country');

  // Converte a string 'BR' de volta para o enum SupportedCountry.BR
  // O valor padrão é Brasil se nada for encontrado.
  return SupportedCountry.values.firstWhere(
        (e) => e.name == countryCode,
    orElse: () => SupportedCountry.BR,
  );
}

Future<List<String>> loadSpeciesSearchData() async {
  try {
    final selectedCountry = await getCountrySetting();
    final countryCode = selectedCountry.name;

    final filePath = 'assets/checklists/species_data_$countryCode.json';
    debugPrint('Carregando dados de espécies do arquivo: $filePath');

    // Carrega o conteúdo do arquivo JSON do bundle de assets.
    final jsonString = await rootBundle.loadString(filePath);

    // Decodifica o JSON e o converte para uma lista de strings.
    final jsonData = json.decode(jsonString) as List<dynamic>;
    final speciesList = jsonData.map((species) => species['scientificName'].toString()).toList();

    debugPrint('Dados de espécies carregados com sucesso. Total: ${speciesList.length} espécies.');
    return speciesList;

  } on FlutterError catch (e) {
    // Trata especificamente o erro de arquivo não encontrado.
    debugPrint('ERRO: Não foi possível carregar o arquivo de dados de espécies. Verifique se o arquivo está no local correto e declarado no pubspec.yaml. Detalhes: $e');
    // Retorna uma lista vazia para evitar que o app quebre.
    return [];
  } catch (e) {
    // Trata outros erros (ex: JSON malformado, erro de tipo).
    debugPrint('ERRO: Ocorreu um erro inesperado ao carregar ou processar os dados de espécies: $e');
    // Retorna uma lista vazia como fallback seguro.
    return [];
  }
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

void checkMackinnonCompletion(BuildContext context, Inventory inventory, InventoryDao inventoryDao) {
  final speciesProvider = Provider.of<SpeciesProvider>(context, listen: false);
  final speciesList = speciesProvider.getSpeciesForInventory(inventory.id);
  // print('speciesList: ${speciesList.length} ; maxSpecies: ${inventory.maxSpecies}');
  if (inventory.type == InventoryType.invMackinnonList &&
      speciesList.length == inventory.maxSpecies - 1) {
    _showMackinnonDialog(context, inventory, inventoryDao);
  }
}

void _showMackinnonDialog(BuildContext context, Inventory inventory, InventoryDao inventoryDao) {
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
              await inventory.stopTimer(context, inventoryDao);
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
              await inventory.stopTimer(context, inventoryDao);
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
      return AlertDialog(
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
    case InventoryType.invTransectCount:
      return 'T';
    case InventoryType.invTransectDetection:
      return 'T';
    case InventoryType.invPointCount:
      return 'P';
    case InventoryType.invPointDetection:
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

Widget buildGridMenuItem(
    BuildContext context, IconData icon, String label, VoidCallback onTap,
    {Color? color}) {
  final itemColor =
      color ?? Theme.of(context).textTheme.bodyLarge?.color;
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(icon, color: itemColor),
        const SizedBox(height: 8,),
        // IconButton(icon: Icon(icon, color: itemColor), onPressed: onTap),
        Text(label,
            textAlign: TextAlign.center, style: TextStyle(color: itemColor)),
      ],
    ),
  );
}

