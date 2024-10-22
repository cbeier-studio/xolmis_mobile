import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/inventory.dart';
import 'add_inventory_screen.dart';

Future<List<String>> loadSpeciesData() async {
  final jsonString = await rootBundle.loadString('assets/species_data.json');
  final jsonData = json.decode(jsonString) as List<dynamic>;
  return jsonData.map((species) => species['scientificName'].toString())
      .toList();
}

void checkMackinnonCompletion(BuildContext context, Inventory inventory) {
  if (inventory.type == InventoryType.invMackinnon &&
      inventory.speciesList.length >= inventory.maxSpecies) {
    inventory.isFinished = true;
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
            'O inventário atingiu o número máximo de espécies. Deseja iniciar a próxima lista ou encerrar o processo?'),
        actions: [
          TextButton(
            child: Text('Iniciar Próxima Lista'),
            onPressed: () async {
              // Finish the inventory and open the screen to add inventory
              await inventory.stopTimer();
              // onInventoryUpdated(inventory);
              Navigator.pop(context, true);
              Navigator.of(context).pop();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddInventoryScreen()),
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