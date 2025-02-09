import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:xolmis/data/database/database_helper.dart';
import 'package:xolmis/generated/l10n.dart';

import '../data/models/inventory.dart';
import '../data/models/nest.dart';
import '../data/models/specimen.dart';

import '../providers/inventory_provider.dart';
import '../providers/species_provider.dart';
import '../providers/nest_provider.dart';
import '../providers/egg_provider.dart';
import '../providers/specimen_provider.dart';

import '../utils/utils.dart';

class StatisticsScreen extends StatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  
  const StatisticsScreen({super.key, required this.scaffoldKey});

  @override
  StatisticsScreenState createState() => StatisticsScreenState();
}

class StatisticsScreenState extends State<StatisticsScreen> {
  final _dbHelper = DatabaseHelper();
  final List<Species> speciesList = [];
  final List<Inventory> inventoryList= [];
  String? selectedSpecies;
  final SearchController searchController = SearchController();
  List<Species> allSpeciesList = [];
  List<Nest> nestList = [];
  List<Egg> eggList = [];
  List<Specimen> specimenList = [];
  bool isLoadingData = false;
  int totalRecordsPerSpecies = 0;

  // Color mapping for each record type
  final Map<String, Color> _recordTypeColors = {
    S.current.inventories: Colors.blue,
    S.current.nests: Colors.orange,
    S.current.egg(2): Colors.green,
    S.current.specimens(2): Colors.purple,
  };

  // Function to get the color for a given record type
  Color _getColor(String recordType) {
    return _recordTypeColors[recordType] ?? Colors.grey; // Default to grey if not found
  }

  // Helper function to get distinct species names from a table
  Future<List<String>> _getDistinctSpeciesFromTable(String tableName) async {
    final db = await _dbHelper.database;
    final String columnName = tableName == 'species' ? 'name' : 'speciesName';
    if (db == null) {
      debugPrint('Error: Database is null.');
      return [];
    }
    try {
      final List<Map<String, dynamic>> results = await db.query(
        tableName,
        columns: [columnName],
        distinct: true,
      );

      // Extract the species names from the results.
      final List<String> speciesNames = results
          .map((row) => row[columnName] as String)
          .toList();

      return speciesNames;
    } catch (e) {
      debugPrint('Error querying database: $e');
      return []; // Return an empty list in case of an error.
    }
  }

  // Get the total number of species with records in any table
  Future<int> getTotalSpeciesWithRecords() async {
    final speciesFromSpecies = await _getDistinctSpeciesFromTable('species');
    final speciesFromNests = await _getDistinctSpeciesFromTable('nests');
    final speciesFromEggs = await _getDistinctSpeciesFromTable('eggs');
    final speciesFromSpecimens = await _getDistinctSpeciesFromTable('specimens');

    final allSpecies = <String>{
      ...speciesFromSpecies,
      ...speciesFromNests,
      ...speciesFromEggs,
      ...speciesFromSpecimens,
    };

    return allSpecies.length;
  }

  // Get the top 10 species with the most records
  Future<List<MapEntry<String, int>>> getTop10SpeciesWithMostRecords() async {
    final speciesFromSpecies = await _getDistinctSpeciesFromTable('species');
    final speciesFromNests = await _getDistinctSpeciesFromTable('nests');
    final speciesFromEggs = await _getDistinctSpeciesFromTable('eggs');
    final speciesFromSpecimens = await _getDistinctSpeciesFromTable(
        'specimens');

    final speciesCounts = <String, int>{};

    // Count species from species table
    for (final species in speciesFromSpecies) {
      speciesCounts[species] = (speciesCounts[species] ?? 0) + 1;
    }

    // Count species from nests table
    for (final species in speciesFromNests) {
      speciesCounts[species] = (speciesCounts[species] ?? 0) + 1;
    }

    // Count species from eggs table
    for (final species in speciesFromEggs) {
      speciesCounts[species] = (speciesCounts[species] ?? 0) + 1;
    }

    // Count species from specimens table
    for (final species in speciesFromSpecimens) {
      speciesCounts[species] = (speciesCounts[species] ?? 0) + 1;
    }

    // Sort by count in descending order and take the top 10
    final sortedSpecies = speciesCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedSpecies.take(10).toList();
  }

  Map<int, int> getOccurrencesByMonth(
    BuildContext context,
    List<Species> speciesList,
    List<Nest> nestList,
    List<Egg> eggList,
    List<Specimen> specimenList,
  ) {
    Map<int, int> occurrences = {};

    // Initialize the occurrences map with zero for each month
    for (int month = 1; month <= 12; month++) {
      occurrences[month] = 0;
    }

    void addOccurrence(DateTime date) {
      occurrences[date.month] = (occurrences[date.month] ?? 0) + 1;
    }

    // Check the list of species
    for (var specie in speciesList) {
      // if (specie.id == species.id) {
        DateTime? speciesDate = specie.sampleTime;

        if (speciesDate == null) {
          Inventory? inventory = Provider.of<InventoryProvider>(context, listen: false).getInventoryById(specie.inventoryId);
          speciesDate = inventory?.startTime;
        }

        if (speciesDate != null) {
          addOccurrence(speciesDate);
        }
      // }
    }

    // Check the list of nests
    for (var nest in nestList) {
      if (nest.speciesName == selectedSpecies) {
        addOccurrence(nest.foundTime!);
      }
    }

    // Check the list of eggs
    for (var egg in eggList) {
      if (egg.speciesName == selectedSpecies) {
        addOccurrence(egg.sampleTime!);
      }
    }

    // Check the list of specimens
    for (var specimen in specimenList) {
      if (specimen.speciesName == selectedSpecies) {
        addOccurrence(specimen.sampleTime!);
      }
    }

    return occurrences;
  }

  Map<String, int> getTotalsByRecordType(List<Species> inventories, List<Nest> nests, List<Egg> eggs, List<Specimen> specimens) {
    return {
      S.current.inventories: inventories.length,
      S.current.nests: nests.length,
      S.current.egg(2): eggs.length,
      S.current.specimens(2): specimens.length,
    };
  }

  @override
  Widget build(BuildContext context) {
    final speciesProvider = Provider.of<SpeciesProvider>(context, listen: false);
    final nestProvider = Provider.of<NestProvider>(context, listen: false);
    final eggProvider = Provider.of<EggProvider>(context, listen: false);
    final specimenProvider = Provider.of<SpecimenProvider>(context, listen: false);

    List<PieChartSectionData> totalsSections = getTotalsByRecordType(allSpeciesList, nestList, eggList, specimenList).entries.map((entry) {
      return PieChartSectionData(
        showTitle: true,
        title: entry.value.toString(),
        value: entry.value.toDouble(),
        color: _getColor(entry.key),
        radius: 20,
        // titleStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();
    totalRecordsPerSpecies = allSpeciesList.length + nestList.length + eggList.length + specimenList.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(S.current.statistics),
        leading: MediaQuery.sizeOf(context).width < 600 ? Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_outlined),
            onPressed: () {
              widget.scaffoldKey.currentState?.openDrawer();
            },
          ),
        ) : SizedBox.shrink(),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
                child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(S.current.perSpecies, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            Row(
              children: [
                SearchAnchor(
              searchController: searchController,
              isFullScreen: MediaQuery.of(context).size.width < 600,
              builder: (BuildContext context, SearchController controller) {
                return IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    controller.openView();
                  },
                );
              },
              suggestionsBuilder: (context, controller) {
                if (controller.text.isEmpty) {
                  return [];
                } else {
                  return List<String>.from(allSpeciesNames)
                    .where((species) => speciesMatchesQuery(
                        species, controller.text.toLowerCase()))
                    .map((species) {
                    return ListTile(
                      title: Text(species),
                      onTap: () async {
                        setState(() {
                          selectedSpecies = species;
                          isLoadingData = true;
                        });
                        await loadDataLists(speciesProvider, nestProvider, eggProvider, specimenProvider);
                        setState(() {
                          isLoadingData = false;
                        });
                        controller.text = selectedSpecies ?? '';
                        controller.closeView('');
                        // controller.clear();
                      },
                    );
                  }).toList();
                }
              },
            ),
                SizedBox(width: 16.0,),
                Text(selectedSpecies ?? '', style: TextStyle(fontStyle: FontStyle.italic, fontWeight: FontWeight.bold),)
            ],
            ),
            SizedBox(height: 16.0),
            if (selectedSpecies != null && !isLoadingData) ...[
              Column(children: [                  
              Card(
                child: Padding(
          padding: EdgeInsets.all(16.0),
      child: Column(
                  children: [
                    Text(S.current.totalRecords, style: TextStyle(fontSize: 16),),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(totalRecordsPerSpecies.toString(), style: TextStyle(fontSize: 20,),),
                    SizedBox(
                      height: 300,
                      child: PieChart(
                PieChartData(
                  borderData: FlBorderData(
                    show: false,
                  ),
                  // pieTouchData: PieTouchData(enabled: true),
                  sectionsSpace: 2,
                  centerSpaceRadius: 80,
                  sections: totalsSections,
                ),
              ),
                    ),
                      ],
                    ),
                    SizedBox(height: 8.0,),
                    Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Indicator(
                color: Colors.blue,
                text: S.current.inventories,
                isSquare: false,
                // size: touchedIndex == 0 ? 18 : 16,
                // textColor: touchedIndex == 0
                //     ? AppColors.mainTextColor1
                //     : AppColors.mainTextColor3,
              ),
              Indicator(
                color: Colors.orange,
                text: S.current.nests,
                isSquare: false,
                // size: touchedIndex == 1 ? 18 : 16,
                // textColor: touchedIndex == 1
                //     ? AppColors.mainTextColor1
                //     : AppColors.mainTextColor3,
              ),
              Indicator(
                color: Colors.green,
                text: S.current.egg(2),
                isSquare: false,
                // size: touchedIndex == 2 ? 18 : 16,
                // textColor: touchedIndex == 2
                //     ? AppColors.mainTextColor1
                //     : AppColors.mainTextColor3,
              ),
              Indicator(
                color: Colors.purple,
                text: S.current.specimens(2),
                isSquare: false,
                // size: touchedIndex == 3 ? 18 : 16,
                // textColor: touchedIndex == 3
                //     ? AppColors.mainTextColor1
                //     : AppColors.mainTextColor3,
              ),
            ],
          ),
                  ],
                ),
                ),
              ),
              SizedBox(height: 16.0),
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                  children: [
                    Text(S.current.recordsPerMonth, style: TextStyle(fontSize: 16),),
                  SizedBox(
                    height: 300,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        gridData: FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        barTouchData: BarTouchData(enabled: true),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                String monthAbbreviation =
                                    DateFormat('MMM').format(DateTime(0, value.toInt()));
                                return Text(monthAbbreviation);
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        barGroups: createBarGroupsFromOccurrencesMap(
                            getOccurrencesByMonth(context, allSpeciesList,
                                nestList, eggList, specimenList)),
                      ),
                    ),
                  ),

                ]),
                      ),
              ),
                ],
                ),
            ] else if (isLoadingData) ...[
              Center(child: CircularProgressIndicator())
            ] else ...[
              Center(child: Text(S.current.selectSpeciesToShowStats))
            ],
          ],
        ),
      ),
      ),
    );
  }

  Future<void> loadDataLists(SpeciesProvider speciesProvider, NestProvider nestProvider, EggProvider eggProvider, SpecimenProvider specimenProvider) async {
    allSpeciesList = await speciesProvider.getAllRecordsBySpecies(selectedSpecies ?? '');
    nestList = await nestProvider.getNestsBySpecies(selectedSpecies ?? '');
    eggList = await eggProvider.getEggsBySpecies(selectedSpecies ?? '');
    specimenList = await specimenProvider.getSpecimensBySpecies(selectedSpecies ?? '');
  }

  List<BarChartGroupData> createBarGroupsFromOccurrencesMap(Map<int, int> monthlyOccurrences) {
    final List<BarChartGroupData> barGroups = [];
    monthlyOccurrences.forEach((month, count) {
      // Converter a abreviação do mês para um número (1-12)
      barGroups.add(
        BarChartGroupData(
          x: month, // O mês será o valor do eixo X
          barRods: [
            BarChartRodData(
              toY: count.toDouble(), // A contagem de espécies será o valor do eixo Y
              color: Colors.blue, // Cor da barra (você pode personalizar)
              width: 16, // Largura da barra (você pode personalizar)
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
            ),
          ],
        ),
      );
    });
    return barGroups;
  }
}

class MonthOccurrence {
  final int month;
  final int occurrences;

  MonthOccurrence({required this.month, required this.occurrences});
}

class Indicator extends StatelessWidget {
  const Indicator({
    super.key,
    required this.color,
    required this.text,
    required this.isSquare,
    this.size = 16,
    this.textColor,
  });
  final Color color;
  final String text;
  final bool isSquare;
  final double size;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: isSquare ? BoxShape.rectangle : BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(
          width: 4,
        ),
        Text(
          text,
          style: TextStyle(
            // fontSize: 16,
            // fontWeight: FontWeight.bold,
            color: textColor,
          ),
        )
      ],
    );
  }
}
