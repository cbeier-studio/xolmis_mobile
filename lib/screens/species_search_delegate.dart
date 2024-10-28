import 'package:flutter/material.dart';

class SpeciesSearchDelegate extends SearchDelegate<String> {
  final List<String> allSpecies;
  final Function(String) addSpeciesToInventory;
  final VoidCallback updateSpeciesList;

  SpeciesSearchDelegate(this.allSpecies, this.addSpeciesToInventory, this.updateSpeciesList);

  @override
  String? get searchFieldLabel => 'Buscar espécie';

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear_outlined),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_outlined),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = allSpecies
        .where((species) => speciesMatchesQuery(species, query))
        .toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final species = suggestions[index];
        return ListTile(
          title: Text(species),
          onTap: () {
            addSpeciesToInventory(species);
            close(context, species); // Close the suggestions list and return the selected species
          },
        );
      },
    );
  }

  bool speciesMatchesQuery(String speciesName, String query) {
    if (query.length == 4 || query.length == 6) {
      final words = speciesName.split(' ');
      if (words.length >= 2) {
        final firstWord = words[0];
        final secondWord = words[1];
        final firstPartLength = query.length == 4 ? 2 : 3;
        final firstPart = query.substring(0, firstPartLength);
        final secondPart = query.substring(firstPartLength);

        // Check if the parts of query match the parts of the species name
        if (firstWord.toLowerCase().startsWith(firstPart.toLowerCase()) &&
            secondWord.toLowerCase().startsWith(secondPart.toLowerCase())) {
          return true;
        }
      }

      if (speciesName.toLowerCase().contains(query.toLowerCase())) {
        return true;
      }
    }
    // If que query do not have 4 or 6 characters, or if the species name do not have two words,
    // use the previous search logic (e.g.: contains)
    return speciesName.toLowerCase().contains(query.toLowerCase());
  }

  @override
  Widget buildResults(BuildContext context) {
    // Add the first item from suggestions list
    if (query.isNotEmpty) {
      final suggestions = allSpecies.where((species) => speciesMatchesQuery(species, query)).toList();
      if (suggestions.isNotEmpty) {
        final firstSuggestion = suggestions[0];
        addSpeciesToInventory(firstSuggestion);
        // updateSpeciesList();
        close(context, firstSuggestion);
      }
    }
    return Container(); // Return a empty widget, because buildResults is not used in this case
  }
}