import 'package:flutter/material.dart';
import 'package:xolmis/generated/l10n.dart';

class AllSpeciesRecordsScreen extends StatelessWidget {
  final List<MapEntry<String, int>> allSpeciesRecords;

  const AllSpeciesRecordsScreen({super.key, required this.allSpeciesRecords});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).topSpecies(allSpeciesRecords.length)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
        itemCount: allSpeciesRecords.length,
        itemBuilder: (context, index) {
          final entry = allSpeciesRecords[index];
          return ListTile(
            title: Text(
              entry.key,
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
            trailing: Text(
              entry.value.toString(),
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        },
      ),
      ),
    );
  }
}
