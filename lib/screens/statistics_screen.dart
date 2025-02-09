import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
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
import '../utils/statistics_logic.dart';

class StatisticsScreen extends StatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  
  const StatisticsScreen({super.key, required this.scaffoldKey});

  @override
  StatisticsScreenState createState() => StatisticsScreenState();
}

class StatisticsScreenState extends State<StatisticsScreen> {
  final SearchController searchController = SearchController();
  String? selectedSpecies;
  List<Species> allSpeciesList = [];
  List<Nest> nestList = [];
  List<Egg> eggList = [];
  List<Specimen> specimenList = [];
  bool isLoadingData = false;
  int totalRecordsPerSpecies = 0;
  int totalDistinctSpecies = 0;
  double totalInventoryHours = 0.0;
  double averageInventoryHours = 0.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final inventoryProvider = Provider.of<InventoryProvider>(
        context, listen: false);
    try {
      setState(() {
        isLoadingData = true;
      });
      totalDistinctSpecies = await getTotalSpeciesWithRecords();
      totalInventoryHours = await inventoryProvider.getTotalSamplingHours();
      averageInventoryHours = await inventoryProvider.getAverageSamplingHours();
    } catch (e) {
      // Handle errors here, e.g., show a snackbar
      debugPrint('Error loading data: $e');
    } finally {
      setState(() {
        isLoadingData = false;
      });
    }
  }

  Future<void> loadDataLists(SpeciesProvider speciesProvider, NestProvider nestProvider, EggProvider eggProvider, SpecimenProvider specimenProvider) async {
    allSpeciesList = await speciesProvider.getAllRecordsBySpecies(selectedSpecies ?? '');
    nestList = await nestProvider.getNestsBySpecies(selectedSpecies ?? '');
    eggList = await eggProvider.getEggsBySpecies(selectedSpecies ?? '');
    specimenList = await specimenProvider.getSpecimensBySpecies(selectedSpecies ?? '');
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
        color: getColor(entry.key),
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
            Text(S.current.species(2), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: ListTile(
                  title: Text(totalDistinctSpecies.toString(), style: TextStyle(fontSize: 20)),
                  subtitle: Text('espécies registradas'),
                ),
              ),
            ),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text('Top 10 espécies mais registradas', style: TextStyle(fontSize: 16),),
                    SizedBox(height: 8,),
                      FutureBuilder<List<MapEntry<String, int>>>(
                        future: getTop10SpeciesWithMostRecords(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return CircularProgressIndicator(); // Show a loading indicator
                          } else if (snapshot.hasError) {
                            return Text('Erro: ${snapshot.error}');
                          } else if (snapshot.hasData) {
                            return Column(
                              children: snapshot.data!.map((entry) => ListTile(
                                dense: true,
                                visualDensity: VisualDensity(horizontal: 0, vertical: -4),
                                title: Text(entry.key, style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12,)),
                                trailing: Text(entry.value.toString(), style: TextStyle(color: Colors.grey)),
                              )).toList(),
                            );
                          } else {
                            return Text('Nenhum dado disponível');
                          }
                        },
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16,),
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
                                return Text(monthAbbreviation[0].toUpperCase());
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
                                nestList, eggList, specimenList, selectedSpecies)),
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
            SizedBox(height: 16,),
            Text(S.current.inventories, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: ListTile(
                  title: Text('0', style: TextStyle(fontSize: 20)),
                  subtitle: Text('inventários realizados'),
                ),
              ),
            ),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: ListTile(
                  title: Text(totalInventoryHours.toString(), style: TextStyle(fontSize: 20)),
                  subtitle: Text('horas de amostragem'),
                ),
              ),
            ),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: ListTile(
                  title: Text(averageInventoryHours.toString(), style: TextStyle(fontSize: 20)),
                  subtitle: Text('horas em média'),
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
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
