import 'package:flutter/gestures.dart';
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

class StatisticsScreenState extends State<StatisticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.current.statistics),
        leading:
            MediaQuery.sizeOf(context).width < 600
                ? Builder(
                  builder:
                      (context) => IconButton(
                        icon: const Icon(Icons.menu_outlined),
                        onPressed: () {
                          widget.scaffoldKey.currentState?.openDrawer();
                        },
                      ),
                )
                : SizedBox.shrink(),
        bottom: TabBar(
          controller: _tabController,
          tabs: [Tab(text: S.current.general), Tab(text: S.current.perSpecies)],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        dragStartBehavior: DragStartBehavior.down,
        physics: NeverScrollableScrollPhysics(),
        children: [GeneralStatisticsTab(), PerSpeciesStatisticsTab()],
      ),
    );
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
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            // fontSize: 16,
            // fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ],
    );
  }
}

class GeneralStatisticsTab extends StatefulWidget {
  const GeneralStatisticsTab({super.key});

  @override
  State<GeneralStatisticsTab> createState() => _GeneralStatisticsTabState();
}

class _GeneralStatisticsTabState extends State<GeneralStatisticsTab> {
  bool isLoadingData = false;
  int totalDistinctSpecies = 0;
  double totalInventoryHours = 0.0;
  double averageInventoryHours = 0.0;
  List<Species> allSpeciesList = [];
  List<Nest> nestList = [];
  List<Egg> eggList = [];
  List<Specimen> specimenList = [];
  List<PieChartSectionData> specimenTypeSections = [];

  @override
  void initState() {
    super.initState();
    _loadGeneralData();
  }

  Future<void> _loadGeneralData() async {
    final inventoryProvider = Provider.of<InventoryProvider>(
      context,
      listen: false,
    );
    try {
      setState(() {
        isLoadingData = true;
      });

      // recordedSpeciesNames = await getRecordedSpeciesList();
      totalDistinctSpecies = await getTotalSpeciesWithRecords();
      totalInventoryHours = await inventoryProvider.getTotalSamplingHours();
      averageInventoryHours = await inventoryProvider.getAverageSamplingHours();
      final specimenTypeCounts = await getSpecimenTypeCounts();
      specimenTypeSections = specimenTypeCounts.entries.map((entry) {
        return PieChartSectionData(
          showTitle: true,
          title: entry.value.toString(),
          value: entry.value.toDouble(),
          color: getSpecimenColor(entry.key),
          radius: 20,
        );
      }).toList();
    } catch (e) {
      // Handle errors here, e.g., show a snackbar
      debugPrint('Error loading data: $e');
    } finally {
      setState(() {
        isLoadingData = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth:
              MediaQuery.of(context).size.width > 600 ? 840 : double.infinity,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isLoadingData) ...[
                  Text(
                    S.current.species(2),
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  // Total species with records
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: ListTile(
                        title: Text(
                          totalDistinctSpecies.toString(),
                          style: TextStyle(fontSize: 20),
                        ),
                        subtitle: Text(S.current.recordedSpecies),
                      ),
                    ),
                  ),
                  // Top 10 list of species with most records
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Text(
                            S.current.topTenSpecies,
                            style: TextStyle(fontSize: 16),
                          ),
                          SizedBox(height: 8),
                          FutureBuilder<List<MapEntry<String, int>>>(
                            future: getTop10SpeciesWithMostRecords(
                              allSpeciesList,
                              nestList,
                              eggList,
                              specimenList,
                            ),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return CircularProgressIndicator();
                              } else if (snapshot.hasError) {
                                return Text('Error: ${snapshot.error}');
                              } else if (snapshot.hasData) {
                                return Column(
                                  children:
                                      snapshot.data!
                                          .map(
                                            (entry) => ListTile(
                                              dense: true,
                                              visualDensity: VisualDensity(
                                                horizontal: 0,
                                                vertical: -4,
                                              ),
                                              title: Text(
                                                entry.key,
                                                style: TextStyle(
                                                  fontStyle: FontStyle.italic,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              trailing: Text(
                                                entry.value.toString(),
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                );
                              } else {
                                return Text(S.current.noDataAvailable);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    S.current.inventories,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  // Total sampling hours
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: ListTile(
                        title: Text(
                          NumberFormat.decimalPattern(locale.toString(),).format(totalInventoryHours),
                          style: TextStyle(fontSize: 20),
                        ),
                        subtitle: Text(S.current.surveyHours),
                      ),
                    ),
                  ),
                  // Average survey hours per inventory
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: ListTile(
                        title: Text(
                          NumberFormat.decimalPattern(locale.toString(),).format(averageInventoryHours),
                          style: TextStyle(fontSize: 20),
                        ),
                        subtitle: Text(S.current.averageSurveyHours),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    S.current.specimens(2),
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  // Chart of specimens by type
                  Card(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Text(
                                S.current.specimenType,
                                style: TextStyle(fontSize: 16),
                              ),
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Text(
                                  //   totalRecordsPerSpecies.toString(),
                                  //   style: TextStyle(fontSize: 20),
                                  // ),
                                  SizedBox(
                                    height: 300,
                                    child: PieChart(
                                      PieChartData(
                                        borderData: FlBorderData(show: false),
                                        // pieTouchData: PieTouchData(enabled: true),
                                        sectionsSpace: 2,
                                        centerSpaceRadius: 80,
                                        sections: specimenTypeSections,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8.0),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: <Widget>[
                                  Indicator(
                                    color: Colors.blue,
                                    text: S.current.specimenWholeCarcass,
                                    isSquare: false,
                                  ),
                                  Indicator(
                                    color: Colors.orange,
                                    text: S.current.specimenPartialCarcass,
                                    isSquare: false,
                                  ),
                                  
                                ],
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: <Widget>[
                                  Indicator(
                                    color: Colors.green,
                                    text: S.current.specimenNest,
                                    isSquare: false,
                                  ),
                                  Indicator(
                                    color: Colors.purple,
                                    text: S.current.specimenBones,
                                    isSquare: false,
                                  ),
                                  Indicator(
                                    color: Colors.yellow,
                                    text: S.current.specimenEgg,
                                    isSquare: false,
                                  ),
                                  Indicator(
                                    color: Colors.cyan,
                                    text: S.current.specimenParasites,
                                    isSquare: false,
                                  ),
                                  
                                ],
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: <Widget>[
                                  Indicator(
                                    color: Colors.deepPurple,
                                    text: S.current.specimenFeathers,
                                    isSquare: false,
                                  ),
                                  Indicator(
                                    color: Colors.red,
                                    text: S.current.specimenBlood,
                                    isSquare: false,
                                  ),
                                  Indicator(
                                    color: Colors.teal,
                                    text: S.current.specimenClaw,
                                    isSquare: false,
                                  ),
                                  Indicator(
                                    color: Colors.amber,
                                    text: S.current.specimenSwab,
                                    isSquare: false,
                                  ),
                                  
                                ],
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: <Widget>[
                                  Indicator(
                                    color: Colors.lightGreen,
                                    text: S.current.specimenTissues,
                                    isSquare: false,
                                  ),
                                  Indicator(
                                    color: Colors.deepOrange,
                                    text: S.current.specimenFeces,
                                    isSquare: false,
                                  ),
                                  Indicator(
                                    color: Colors.pink,
                                    text: S.current.specimenRegurgite,
                                    isSquare: false,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                ] else if (isLoadingData) ...[
                  Center(child: CircularProgressIndicator()),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PerSpeciesStatisticsTab extends StatefulWidget {
  const PerSpeciesStatisticsTab({super.key});

  @override
  State<PerSpeciesStatisticsTab> createState() =>
      _PerSpeciesStatisticsTabState();
}

class _PerSpeciesStatisticsTabState extends State<PerSpeciesStatisticsTab> {
  final SearchController searchController = SearchController();
  List<Species> allSpeciesList = [];
  List<Nest> nestList = [];
  List<Egg> eggList = [];
  List<Specimen> specimenList = [];
  String? selectedSpecies;
  int totalRecordsPerSpecies = 0;
  bool isLoadingSpecies = false;
  List<PieChartSectionData> totalsSections = [];
  List<String> recordedSpeciesNames = [];
  List<PieChartSectionData> nestFateSections = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      recordedSpeciesNames = await getRecordedSpeciesList();
    } catch (e) {
      // Handle errors here, e.g., show a snackbar
      debugPrint('Error loading species data: $e');
    }
  }

  Future<void> loadDataLists(
    SpeciesProvider speciesProvider,
    NestProvider nestProvider,
    EggProvider eggProvider,
    SpecimenProvider specimenProvider,
  ) async {
    allSpeciesList = await speciesProvider.getAllRecordsBySpecies(
      selectedSpecies ?? '',
    );
    nestList = await nestProvider.getNestsBySpecies(selectedSpecies ?? '');
    eggList = await eggProvider.getEggsBySpecies(selectedSpecies ?? '');
    specimenList = await specimenProvider.getSpecimensBySpecies(
      selectedSpecies ?? '',
    );
    totalRecordsPerSpecies =
        allSpeciesList.length +
        nestList.length +
        eggList.length +
        specimenList.length;
    totalsSections =
        getTotalsByRecordType(
          allSpeciesList,
          nestList,
          eggList,
          specimenList,
        ).entries.map((entry) {
          return PieChartSectionData(
            showTitle: true,
            title: entry.value.toString(),
            value: entry.value.toDouble(),
            color: getRecordColor(entry.key),
            radius: 20,
            // titleStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          );
        }).toList();
    nestFateSections =
        getNestFateCounts(
          nestList,
        ).entries.map((entry) {
          return PieChartSectionData(
            showTitle: true,
            title: entry.value.toString(),
            value: entry.value.toDouble(),
            color: getNestFateColor(entry.key),
            radius: 20,
            // titleStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          );
        }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final speciesProvider = Provider.of<SpeciesProvider>(
      context,
      listen: false,
    );
    final nestProvider = Provider.of<NestProvider>(context, listen: false);
    final eggProvider = Provider.of<EggProvider>(context, listen: false);
    final specimenProvider = Provider.of<SpecimenProvider>(
      context,
      listen: false,
    );

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth:
              MediaQuery.of(context).size.width > 600 ? 840 : double.infinity,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Field to search for species
                SearchAnchor(
                  searchController: searchController,
                  isFullScreen: MediaQuery.of(context).size.width < 600,
                  builder: (BuildContext context, SearchController controller) {
                    return TextField(
                      controller: controller,
                      decoration: InputDecoration(
                        hintText: S.of(context).selectSpecies,
                        prefixIcon: const Icon(Icons.search_outlined),
                        border: const OutlineInputBorder(),
                      ),
                      readOnly: true,
                      onTap: () {
                        controller.openView();
                      },
                    );
                  },
                  suggestionsBuilder: (context, controller) {
                    return List<String>.from(recordedSpeciesNames)
                        .where(
                          (species) => speciesMatchesQuery(
                            species,
                            controller.text.toLowerCase(),
                          ),
                        )
                        .map((species) {
                          return ListTile(
                            title: Text(species),
                            onTap: () async {
                              setState(() {
                                selectedSpecies = species;
                                isLoadingSpecies = true;
                              });
                              await loadDataLists(
                                speciesProvider,
                                nestProvider,
                                eggProvider,
                                specimenProvider,
                              );
                              setState(() {
                                isLoadingSpecies = false;
                              });
                              controller.text = selectedSpecies ?? '';
                              controller.closeView('');
                              // controller.clear();
                            },
                          );
                        })
                        .toList();
                  },
                ),
                SizedBox(height: 16.0),
                if (selectedSpecies != null) ...[
                  Text(
                    selectedSpecies!,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                      fontSize: 16,
                    ),
                  ),
                ],
                SizedBox(height: 16.0),
                if (selectedSpecies != null && !isLoadingSpecies) ...[
                  Column(
                    children: [
                      // Total records per species
                      Card(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Text(
                                S.current.totalRecords,
                                style: TextStyle(fontSize: 16),
                              ),
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  Text(
                                    totalRecordsPerSpecies.toString(),
                                    style: TextStyle(fontSize: 20),
                                  ),
                                  SizedBox(
                                    height: 300,
                                    child: PieChart(
                                      PieChartData(
                                        borderData: FlBorderData(show: false),
                                        // pieTouchData: PieTouchData(enabled: true),
                                        sectionsSpace: 2,
                                        centerSpaceRadius: 80,
                                        sections: totalsSections,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8.0),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: <Widget>[
                                  Indicator(
                                    color: Colors.blue,
                                    text: S.current.inventories,
                                    isSquare: false,
                                  ),
                                  Indicator(
                                    color: Colors.orange,
                                    text: S.current.nests,
                                    isSquare: false,
                                  ),
                                  Indicator(
                                    color: Colors.green,
                                    text: S.current.egg(2),
                                    isSquare: false,
                                  ),
                                  Indicator(
                                    color: Colors.purple,
                                    text: S.current.specimens(2),
                                    isSquare: false,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 16.0),

                      // Records per month
                      Card(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Text(
                                S.current.recordsPerMonth,
                                style: TextStyle(fontSize: 16),
                              ),
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
                                                DateFormat('MMM').format(
                                                  DateTime(0, value.toInt()),
                                                );
                                            return Text(
                                              monthAbbreviation[0]
                                                  .toUpperCase(),
                                            );
                                          },
                                        ),
                                      ),
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: false,
                                        ),
                                      ),
                                      topTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: false,
                                        ),
                                      ),
                                      rightTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: false,
                                        ),
                                      ),
                                    ),
                                    barGroups:
                                        createBarGroupsFromOccurrencesMap(
                                          getOccurrencesByMonth(
                                            context,
                                            allSpeciesList,
                                            nestList,
                                            eggList,
                                            specimenList,
                                            selectedSpecies,
                                          ),
                                        ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 16.0),

                      // Records per year
                      Card(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Text(
                                S.current.recordsPerYear,
                                style: TextStyle(fontSize: 16),
                              ),
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
                                            return Text(
                                              value.toInt().toString(),
                                            );
                                          },
                                        ),
                                      ),
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: false,
                                        ),
                                      ),
                                      topTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: false,
                                        ),
                                      ),
                                      rightTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: false,
                                        ),
                                      ),
                                    ),
                                    barGroups:
                                        createBarGroupsFromYearOccurrencesMap(
                                          getOccurrencesByYear(
                                            context,
                                            allSpeciesList,
                                            nestList,
                                            eggList,
                                            specimenList,
                                            selectedSpecies,
                                          ),
                                        ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 16.0),
                      // Nest fate per species
                      Card(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Text(
                                S.current.nestFate,
                                style: TextStyle(fontSize: 16),
                              ),
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  Text(
                                    nestList.length.toString(),
                                    style: TextStyle(fontSize: 20),
                                  ),
                                  SizedBox(
                                    height: 300,
                                    child: PieChart(
                                      PieChartData(
                                        borderData: FlBorderData(show: false),
                                        // pieTouchData: PieTouchData(enabled: true),
                                        sectionsSpace: 2,
                                        centerSpaceRadius: 80,
                                        sections: nestFateSections,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8.0),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: <Widget>[
                                  Indicator(
                                    color: Colors.grey,
                                    text: S.current.nestFateUnknown,
                                    isSquare: false,
                                  ),
                                  Indicator(
                                    color: Colors.red,
                                    text: S.current.nestFateLost,
                                    isSquare: false,
                                  ),
                                  Indicator(
                                    color: Colors.blue,
                                    text: S.current.nestFateSuccess,
                                    isSquare: false,
                                  ),                                  
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                    
                  
                ] else if (isLoadingSpecies) ...[
                  Center(child: CircularProgressIndicator()),
                ] else ...[
                  Center(child: Text(S.current.selectSpeciesToShowStats)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<BarChartGroupData> createBarGroupsFromOccurrencesMap(Map<int, int> monthlyOccurrences,) {
    final List<BarChartGroupData> barGroups = [];
    monthlyOccurrences.forEach((month, count) {
      barGroups.add(
        BarChartGroupData(
          x: month, // month is the value of X axis
          barRods: [
            BarChartRodData(
              toY: count.toDouble(), // record count is the value of Y axis
              color: Colors.blue, 
              width: 16, 
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

  List<BarChartGroupData> createBarGroupsFromYearOccurrencesMap(Map<int, int> yearlyOccurrences,) {
    final List<BarChartGroupData> barGroups = [];
    yearlyOccurrences.forEach((year, count) {
      barGroups.add(
        BarChartGroupData(
          x: year, // month is the value of X axis
          barRods: [
            BarChartRodData(
              toY: count.toDouble(), // record count is the value of Y axis
              color: Colors.blue, 
              width: 16, 
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
