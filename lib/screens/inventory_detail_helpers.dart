import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/inventory.dart';
import '../providers/species_provider.dart';
import 'add_inventory_screen.dart';

Future<List<String>> loadSpeciesData() async {
  final jsonString = await rootBundle.loadString('assets/species_data.json');
  final jsonData = json.decode(jsonString) as List<dynamic>;
  return jsonData.map((species) => species['scientificName'].toString())
      .toList();
}

String getNextInventoryId(String currentId) {
  final parts = currentId.split('-');
  final lastPart = parts.last;
  final prefix = lastPart.substring(0, 1); // Get the letter prefix (e.g., "L")
  final number = int.parse(lastPart.substring(1)); // Get the numeric part (e.g., "01")
  final nextNumber = number + 1;
  final nextId = '${parts[0]}-${prefix}${nextNumber.toString().padLeft(2, '0')}'; // Pad with leading zeros if needed
  return nextId;
}

void checkMackinnonCompletion(BuildContext context, Inventory inventory) {
  final speciesProvider = Provider.of<SpeciesProvider>(context, listen: false);
  final speciesList = speciesProvider.getSpeciesForInventory(inventory.id);
  // print('speciesList: ${speciesList.length} ; maxSpecies: ${inventory.maxSpecies}');
  if (inventory.type == InventoryType.invMackinnon &&
      speciesList.length == inventory.maxSpecies) {
    _showMackinnonDialog(context, inventory);
  }
}

void _showMackinnonDialog(BuildContext context, Inventory inventory) {
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
              await inventory.stopTimer();
              // onInventoryUpdated(inventory);
              Navigator.pop(context, true);
              Navigator.of(context).pop();
              final nextInventoryId = getNextInventoryId(inventory.id!);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddInventoryScreen(
                  initialInventoryId: nextInventoryId,
                  initialInventoryType: InventoryType.invMackinnon,
                  initialMaxSpecies: inventory.maxSpecies,
                )
                ),
              );
            },
          ),
          TextButton(
            child: Text('Encerrar'),
            onPressed: () async {
              // Finish the inventory and go back to the Home screen
              await inventory.stopTimer();
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