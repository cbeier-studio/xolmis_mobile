import 'package:flutter/material.dart';

class SpeciesSearchDialog extends StatefulWidget {
  final List<String> allSpeciesNames;
  final Function(String) onSelected;
  final VoidCallback updateSpeciesList;

  const SpeciesSearchDialog({
    super.key,
    required this.allSpeciesNames,
    required this.onSelected,
    required this.updateSpeciesList,
  });

  @override
  SpeciesSearchDialogState createState() => SpeciesSearchDialogState();
}

class SpeciesSearchDialogState extends State<SpeciesSearchDialog> {
  late List<String> filteredSpeciesNames;
  late TextEditingController searchController;

  @override
  void initState() {
    super.initState();
    filteredSpeciesNames = widget.allSpeciesNames;
    searchController = TextEditingController();
  }

  void _filterSpecies(String query) {
    setState(() {
      filteredSpeciesNames = widget.allSpeciesNames
          .where((species) => species.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search species',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4.0),
                ),
              ),
              onChanged: _filterSpecies,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredSpeciesNames.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(filteredSpeciesNames[index]),
                  onTap: () {
                    widget.onSelected(filteredSpeciesNames[index]);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}