import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:xolmis/providers/inventory_provider.dart';
import 'package:xolmis/providers/nest_provider.dart';
import 'package:xolmis/providers/poi_provider.dart';
import 'package:xolmis/providers/species_provider.dart';

import '../../generated/l10n.dart';

import '../../data/models/inventory.dart';
import '../../providers/egg_provider.dart';
import '../../providers/specimen_provider.dart';
import '../../utils/statistics_logic.dart';
import 'all_species_records_screen.dart';

class StatsGeneralTab extends StatefulWidget {
  final InventoryProvider inventoryProvider;
  final SpeciesProvider speciesProvider;
  final PoiProvider poiProvider;
  final NestProvider nestProvider;
  final EggProvider eggProvider;
  final SpecimenProvider specimenProvider;
  final List<Species> allSpeciesList;

  const StatsGeneralTab({
    super.key,
    required this.inventoryProvider,
    required this.speciesProvider,
    required this.poiProvider,
    required this.nestProvider,
    required this.eggProvider,
    required this.specimenProvider,
    required this.allSpeciesList,
  });

  @override
  State<StatsGeneralTab> createState() => _StatsGeneralTabState();
}

class _StatsGeneralTabState extends State<StatsGeneralTab> with AutomaticKeepAliveClientMixin {
  late int totalDistinctSpecies = 0;
  late int totalPoisCount = 0;
  late int allLocalitiesSurveyed = 0;
  late int inventoryLocalitiesCount = 0;
  late double totalInventoryHours = 0;
  late double averageInventoryHours = 0;
  late int totalInventoryDays = 0;
  late int totalNestsWithNidoparasitism = 0;
  late List<PieChartSectionData> specimenTypeSections = [];
  late List<PieChartSectionData> nestFateSections = [];
  late Future<List<MapEntry<String, int>>> _topSpeciesFuture = Future.value([]);
  late Map<int, int> recordsPerHour = {};
  int _touchedIndexSpecimenType = -1;
  int _touchedIndexNestFate = -1;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadGeneralData();
  }

  Future<void> _loadGeneralData() async {
    try {
      // recordedSpeciesNames = await getRecordedSpeciesList();
      _topSpeciesFuture = getTopSpeciesWithMostRecords(5);
      totalDistinctSpecies = await getTotalSpeciesWithRecords();
      await widget.poiProvider.fetchPoisCount();
      totalPoisCount = widget.poiProvider.allPoisCount;
      allLocalitiesSurveyed = await getRecordedLocalitiesList(context).then((value) => value.length);
      inventoryLocalitiesCount = (await widget.inventoryProvider.getDistinctLocalities()).length;
      totalInventoryDays = await widget.inventoryProvider.getTotalSamplingDays();
      totalInventoryHours = await widget.inventoryProvider.getTotalSamplingHours();
      averageInventoryHours = await widget.inventoryProvider.getAverageSamplingHours();
      totalNestsWithNidoparasitism = await getTotalNestsWithNidoparasitism();

      final allSpeciesRecords = await widget.speciesProvider.getAllSpeciesRecords();
      final allNestsList = await widget.nestProvider.nests;
      final allSpecimenList = await widget.specimenProvider.specimens;
      final allEggsList = await widget.eggProvider.getAllEggs();
      recordsPerHour = await getAllOccurrencesByHourOfDay(allSpeciesRecords, allNestsList, allEggsList, allSpecimenList);

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
      nestFateSections =
        getNestFateCounts(
          widget.nestProvider.nests,
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

      setState(() {});
    } catch (e) {
      // Handle errors here, e.g., show a snackbar
      debugPrint('Error loading data: $e');
    }
  }

  String getSpecimenTypeFriendlyName(String specimenType, BuildContext context) {
    switch (specimenType) {
      case 'wholeCarcass':
        return S.of(context).specimenWholeCarcass;
      case 'partialCarcass':
        return S.of(context).specimenPartialCarcass;
      case 'nest':
        return S.of(context).specimenNest;
      case 'bones':
        return S.of(context).specimenBones;
      case 'egg':
        return S.of(context).specimenEgg;
      case 'parasites':
        return S.of(context).specimenParasites;
      case 'feathers':
        return S.of(context).specimenFeathers;
      case 'blood':
        return S.of(context).specimenBlood;
      case 'claw':
        return S.of(context).specimenClaw;
      case 'swab':
        return S.of(context).specimenSwab;
      case 'tissues':
        return S.of(context).specimenTissues;
      case 'feces':
        return S.of(context).specimenFeces;
      case 'regurgite':
        return S.of(context).specimenRegurgite;
      default:
        return '';
    }
  }

  String getSpecimenTypeFromColor(Color color) {
    if (color == Colors.blue) return 'wholeCarcass';
    if (color == Colors.orange) return 'partialCarcass';
    if (color == Colors.green) return 'nest';
    if (color == Colors.purple) return 'bones';
    if (color == Colors.yellow) return 'egg';
    if (color == Colors.cyan) return 'parasites';
    if (color == Colors.deepPurple) return 'feathers';
    if (color == Colors.red) return 'blood';
    if (color == Colors.teal) return 'claw';
    if (color == Colors.amber) return 'swab';
    if (color == Colors.lightGreen) return 'tissues';
    if (color == Colors.deepOrange) return 'feces';
    if (color == Colors.pink) return 'regurgite';
    return '';
  }

  String getNestFateFriendlyName(String nestFate, BuildContext context) {
    switch (nestFate) {
      case 'unknown':
        return S.of(context).nestFateUnknown;
      case 'lost':
        return S.of(context).nestFateLost;
      case 'success':
        return S.of(context).nestFateSuccess;
      default:
        return '';
    }
  }

  String getNestFateFromColor(Color color) {
    if (color == Colors.grey) return 'unknown';
    if (color == Colors.red) return 'lost';
    if (color == Colors.blue) return 'success';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (widget.inventoryProvider.allInventoriesCount == 0 &&
      widget.nestProvider.allNestsCount == 0 &&
      widget.specimenProvider.specimensCount == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              S.current.noDataAvailable,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 16),
            FilledButton.icon(
              label: Text(S.of(context).refresh),
              icon: const Icon(Icons.refresh_outlined),
              onPressed: () async {
                await _loadGeneralData();
              },
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              // Text(
              //   S.current.species(2),
              //   style: TextTheme.of(context).titleLarge,
              // ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // Total species with records
                  Expanded(child:
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            totalDistinctSpecies.toString(),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: Theme.of(context).textTheme.headlineSmall?.fontWeight,
                              fontSize: Theme.of(context).textTheme.headlineSmall?.fontSize,
                            ),
                          ),
                          Text(S.current.recordedSpecies),
                        ],
                      ),
                    ),
                  ),
                  ),
                  // Total inventories recorded
                  Expanded(child:
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.inventoryProvider.allInventoriesCount.toString(),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: Theme.of(context).textTheme.headlineSmall?.fontWeight,
                              fontSize: Theme.of(context).textTheme.headlineSmall?.fontSize,
                            ),
                          ),
                          Text(S.current.inventory(widget.inventoryProvider.allInventoriesCount)),
                        ],
                      ),
                    ),
                  ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // Total nests recorded
                  Expanded(child:
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.nestProvider.allNestsCount.toString(),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: Theme.of(context).textTheme.headlineSmall?.fontWeight,
                              fontSize: Theme.of(context).textTheme.headlineSmall?.fontSize,
                            ),
                          ),
                          Text(S.current.nest(widget.nestProvider.allNestsCount)),
                        ],
                      ),
                    ),
                  ),
                  ),
                  // Total specimens recorded
                  Expanded(child:
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.specimenProvider.specimensCount.toString(),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: Theme.of(context).textTheme.headlineSmall?.fontWeight,
                              fontSize: Theme.of(context).textTheme.headlineSmall?.fontSize,
                            ),
                          ),
                          Text(S.current.specimens(widget.specimenProvider.specimensCount).toLowerCase()),
                        ],
                      ),
                    ),
                  ),
                  ),
                ],
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // Total POIs recorded
                Expanded(child:
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          totalPoisCount.toString(),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: Theme.of(context).textTheme.headlineSmall?.fontWeight,
                            fontSize: Theme.of(context).textTheme.headlineSmall?.fontSize,
                          ),
                        ),
                        Text(S.current.poisRecorded(totalPoisCount)),
                      ],
                    ),
                  ),
                ),
                ),
                // Total localities surveyed
                Expanded(child:
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          allLocalitiesSurveyed.toString(),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: Theme.of(context).textTheme.headlineSmall?.fontWeight,
                            fontSize: Theme.of(context).textTheme.headlineSmall?.fontSize,
                          ),
                        ),
                        Text(S.current.localitiesSurveyed(allLocalitiesSurveyed)),
                      ],
                    ),
                  ),
                ),
                ),
              ],
            ),
              // Top list of species with most records
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Expanded(child:
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Text(
                            S.current.topSpecies(5),
                            style: TextTheme.of(context).titleMedium,
                          ),
                          SizedBox(height: 8),
                          FutureBuilder<List<MapEntry<String, int>>>(
                            future: _topSpeciesFuture,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return CircularProgressIndicator(
                                  year2023: false,
                                );
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
                                        style: const TextStyle(
                                          fontStyle: FontStyle.italic,
                                          fontSize: 12,
                                        ),
                                      ),
                                      trailing: Text(
                                        entry.value.toString(),
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.primary,
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
                          const SizedBox(height: 8,),
                          TextButton(onPressed: () async {
                            // Ação de navegação para a nova tela
                            final allSpeciesRecords = await getTopSpeciesWithMostRecords(0);
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => AllSpeciesRecordsScreen(
                                  // Passa a lista COMPLETA para a nova tela
                                  allSpeciesRecords: allSpeciesRecords,
                                ),
                              ),
                            );
                          }, child: Text(S.of(context).seeAll))
                        ],
                      ),
                    ),
                  ),
                  ),
                ],
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Expanded(child:
                // Nest fate per species
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                          S.current.recordsByHour,
                          style: TextTheme.of(context).titleMedium,
                        ),
                        const SizedBox(height: 8,),
                        recordsPerHour.isNotEmpty ?
                        SizedBox(
                          height: 150,
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              gridData: FlGridData(show: false),
                              borderData: FlBorderData(
                                show: true,
                                border: Border(
                                  bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.5), width: 1),
                                ),
                              ),
                              barTouchData: BarTouchData(
                                enabled: true,
                                touchTooltipData: BarTouchTooltipData(
                                    fitInsideHorizontally: true,
                                    fitInsideVertically: true,
                                    getTooltipColor: (spot) => Colors.white.withValues(alpha: 0.8),
                                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                      final hour = group.x.toInt();
                                      final value = rod.toY.toInt();
                                      if (value == 0) {
                                        return null;
                                      }
                                      return BarTooltipItem(
                                        '', // String principal vazia, usamos os children
                                        const TextStyle(),
                                        children: [
                                          TextSpan(
                                            text: '$value\n',
                                            style: const TextStyle(
                                              color: Colors.blue,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          TextSpan(
                                            text: '${hour.toString().padLeft(2, '0')} h',
                                            style: const TextStyle(
                                              color: Colors.black87,
                                              fontWeight: FontWeight.normal,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      );
                                    }
                                ),
                              ),
                              titlesData: FlTitlesData(
                                show: true,
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 30,
                                    getTitlesWidget: (value, meta) {
                                      // Mostra os títulos do eixo X em intervalos (0, 6, 12, 18, 23) para não poluir.
                                      final hour = value.toInt();
                                      if (hour % 3 == 0 || hour == 23) {
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 8.0),
                                          child: Text(hour.toString().padLeft(2, '0')),
                                        );
                                      }
                                      return const Text('');
                                    },
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false, reservedSize: 28),
                                ),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              // Usa a nova função para obter os dados do histograma
                              barGroups: createBarGroupsFromOccurrencesMap(
                                recordsPerHour,
                                12,
                              ),
                            ),
                          ),
                        ) : Text(S.current.noDataAvailable),
                      ],
                    ),
                  ),
                ),
                ),
              ],
            ),
              SizedBox(height: 16),
              Text(
                S.current.inventories,
                style: TextTheme.of(context).titleLarge,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // Total sampling hours
                  Expanded(child:
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            totalInventoryHours.toStringAsFixed(2),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: Theme.of(context).textTheme.headlineSmall?.fontWeight,
                              fontSize: Theme.of(context).textTheme.headlineSmall?.fontSize,
                            ),
                          ),
                          Text(S.current.surveyHours),
                        ],
                      ),
                    ),
                  ),
                  ),
                  // Average survey hours per inventory
                  Expanded(child:
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            averageInventoryHours.toStringAsFixed(2),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: Theme.of(context).textTheme.headlineSmall?.fontWeight,
                              fontSize: Theme.of(context).textTheme.headlineSmall?.fontSize,
                            ),
                          ),
                          Text(S.current.averageSurveyHours),
                        ],
                      ),
                    ),
                  ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // Total days surveyed
                  Expanded(child:
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            totalInventoryDays.toString(),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: Theme.of(context).textTheme.headlineSmall?.fontWeight,
                              fontSize: Theme.of(context).textTheme.headlineSmall?.fontSize,
                            ),
                          ),
                          Text(S.current.daysSurveyed(totalInventoryDays)),
                        ],
                      ),
                    ),
                  ),
                  ),
                  // Total localities recorded
                  Expanded(child:
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            inventoryLocalitiesCount.toString(),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: Theme.of(context).textTheme.headlineSmall?.fontWeight,
                              fontSize: Theme.of(context).textTheme.headlineSmall?.fontSize,
                            ),
                          ),
                          Text(S.current.localitiesSurveyed(inventoryLocalitiesCount)),
                        ],
                      ),
                    ),
                  ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Text(
                S.current.nests,
                style: TextTheme.of(context).titleLarge,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // Apparent success rate
                  Expanded(child:
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (widget.nestProvider.successNestsCount / widget.nestProvider.inactiveNestsCount * 100).toStringAsFixed(1),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: Theme.of(context).textTheme.headlineSmall?.fontWeight,
                              fontSize: Theme.of(context).textTheme.headlineSmall?.fontSize,
                            ),
                          ),
                          Text(S.current.apparentSuccessRate),
                        ],
                      ),
                    ),
                  ),
                  ),
                  // Nidoparasitism rate
                  Expanded(child:
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (totalNestsWithNidoparasitism / widget.nestProvider.allNestsCount * 100).toStringAsFixed(1),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: Theme.of(context).textTheme.headlineSmall?.fontWeight,
                              fontSize: Theme.of(context).textTheme.headlineSmall?.fontSize,
                            ),
                          ),
                          Text(S.current.nidoparasitismRate),
                        ],
                      ),
                    ),
                  ),
                  ),
                ],
              ),
              // Chart of nests by fate
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                Expanded(child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Text(
                              S.current.nestFate,
                              style: TextTheme.of(context).titleMedium,
                            ),
                            widget.nestProvider.nests.isNotEmpty ? 
                                SizedBox(
                                  height: 200,
                                  child: PieChart(
                                    PieChartData(
                                      borderData: FlBorderData(show: false),
                                      pieTouchData: PieTouchData(enabled: true,
                                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                          setState(() {
                                            // Verifica se o evento é um toque ou se o usuário parou de tocar
                                            if (!event.isInterestedForInteractions ||
                                                pieTouchResponse == null ||
                                                pieTouchResponse.touchedSection == null) {
                                              _touchedIndexNestFate = -1; // Nenhuma seção está sendo tocada
                                              return;
                                            }
                                            // Atualiza o estado com o índice da seção tocada
                                            _touchedIndexNestFate =
                                                pieTouchResponse.touchedSection!
                                                    .touchedSectionIndex;
                                          });
                                        },
                                      ),
                                      sectionsSpace: 2,
                                      centerSpaceRadius: 50,
                                      sections: nestFateSections.asMap().entries.map((entry) {
                                        final index = entry.key;
                                        final sectionData = entry.value;
                                        final isTouched = index == _touchedIndexNestFate;

                                        // Aumenta o raio e o tamanho da fonte se a seção estiver sendo tocada
                                        final double radius = isTouched ? 50.0 : 40.0;
                                        final double fontSize = isTouched ? 18.0 : 14.0;
                                        final color = sectionData.color; // A cor original da seção

                                        // Cria uma nova PieChartSectionData com os estilos atualizados
                                        return PieChartSectionData(
                                          color: color,
                                          value: sectionData.value,
                                          radius: radius,
                                          titleStyle: TextStyle(
                                            fontSize: fontSize,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            shadows: const [Shadow(color: Colors.black, blurRadius: 10)],
                                          ),
                                          // Mostra o nome do tipo de registro ao tocar, ou o valor numérico caso contrário
                                          title: isTouched
                                              ? getNestFateFriendlyName(getNestFateFromColor(color), context) // Função para obter o nome amigável
                                              : sectionData.value.toInt().toString(),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                            ) : Text(S.current.noDataAvailable),
                            // SizedBox(height: 8.0),
                            // Row(
                            //   mainAxisAlignment:
                            //   MainAxisAlignment.spaceEvenly,
                            //   children: <Widget>[
                            //     Indicator(
                            //       color: Colors.grey,
                            //       text: S.current.nestFateUnknown,
                            //       isSquare: false,
                            //     ),
                            //     Indicator(
                            //       color: Colors.red,
                            //       text: S.current.nestFateLost,
                            //       isSquare: false,
                            //     ),
                            //     Indicator(
                            //       color: Colors.blue,
                            //       text: S.current.nestFateSuccess,
                            //       isSquare: false,
                            //     ),
                            //   ],
                            // ),
                          ],
                        ),
                      ),
                    ),
                    )
              ],
              ),
              SizedBox(height: 16),
              Text(
                S.current.specimens(2),
                style: TextTheme.of(context).titleLarge,
              ),
              // Chart of specimens by type
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Expanded(
                    child:
                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Text(
                              S.current.specimenType,
                              style: TextTheme.of(context).titleMedium,
                            ),
                            specimenTypeSections.isNotEmpty ? Stack(
                              alignment: Alignment.center,
                              children: [
                                // Text(
                                //   totalRecordsPerSpecies.toString(),
                                //   style: TextStyle(fontSize: 20),
                                // ),
                                SizedBox(
                                  height: 200,
                                  child: PieChart(
                                    PieChartData(
                                      borderData: FlBorderData(show: false),
                                      pieTouchData: PieTouchData(enabled: true,
                                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                          setState(() {
                                            // Verifica se o evento é um toque ou se o usuário parou de tocar
                                            if (!event.isInterestedForInteractions ||
                                                pieTouchResponse == null ||
                                                pieTouchResponse.touchedSection == null) {
                                              _touchedIndexSpecimenType = -1; // Nenhuma seção está sendo tocada
                                              return;
                                            }
                                            // Atualiza o estado com o índice da seção tocada
                                            _touchedIndexSpecimenType =
                                                pieTouchResponse.touchedSection!
                                                    .touchedSectionIndex;
                                          });
                                        },
                                      ),
                                      sectionsSpace: 2,
                                      centerSpaceRadius: 50,
                                      sections: specimenTypeSections.asMap().entries.map((entry) {
                                        final index = entry.key;
                                        final sectionData = entry.value;
                                        final isTouched = index == _touchedIndexSpecimenType;

                                        // Aumenta o raio e o tamanho da fonte se a seção estiver sendo tocada
                                        final double radius = isTouched ? 50.0 : 40.0;
                                        final double fontSize = isTouched ? 18.0 : 14.0;
                                        final color = sectionData.color; // A cor original da seção

                                        // Cria uma nova PieChartSectionData com os estilos atualizados
                                        return PieChartSectionData(
                                          color: color,
                                          value: sectionData.value,
                                          radius: radius,
                                          titleStyle: TextStyle(
                                            fontSize: fontSize,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            shadows: const [Shadow(color: Colors.black, blurRadius: 10)],
                                          ),
                                          // Mostra o nome do tipo de registro ao tocar, ou o valor numérico caso contrário
                                          title: isTouched
                                              ? getSpecimenTypeFriendlyName(getSpecimenTypeFromColor(color), context) // Função para obter o nome amigável
                                              : sectionData.value.toInt().toString(),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              ],
                            ) : Text(S.current.noDataAvailable),
                            // SizedBox(height: 8.0),
                            // Row(
                            //   mainAxisAlignment:
                            //       MainAxisAlignment.spaceEvenly,
                            //   children: <Widget>[
                            //     Indicator(
                            //       color: Colors.blue,
                            //       text: S.current.specimenWholeCarcass,
                            //       isSquare: false,
                            //     ),
                            //     Indicator(
                            //       color: Colors.orange,
                            //       text: S.current.specimenPartialCarcass,
                            //       isSquare: false,
                            //     ),
                            //
                            //   ],
                            // ),
                            // Row(
                            //   mainAxisAlignment:
                            //       MainAxisAlignment.spaceEvenly,
                            //   children: <Widget>[
                            //     Indicator(
                            //       color: Colors.green,
                            //       text: S.current.specimenNest,
                            //       isSquare: false,
                            //     ),
                            //     Indicator(
                            //       color: Colors.purple,
                            //       text: S.current.specimenBones,
                            //       isSquare: false,
                            //     ),
                            //     Indicator(
                            //       color: Colors.yellow,
                            //       text: S.current.specimenEgg,
                            //       isSquare: false,
                            //     ),
                            //     Indicator(
                            //       color: Colors.cyan,
                            //       text: S.current.specimenParasites,
                            //       isSquare: false,
                            //     ),
                            //
                            //   ],
                            // ),
                            // Row(
                            //   mainAxisAlignment:
                            //       MainAxisAlignment.spaceEvenly,
                            //   children: <Widget>[
                            //     Indicator(
                            //       color: Colors.deepPurple,
                            //       text: S.current.specimenFeathers,
                            //       isSquare: false,
                            //     ),
                            //     Indicator(
                            //       color: Colors.red,
                            //       text: S.current.specimenBlood,
                            //       isSquare: false,
                            //     ),
                            //     Indicator(
                            //       color: Colors.teal,
                            //       text: S.current.specimenClaw,
                            //       isSquare: false,
                            //     ),
                            //     Indicator(
                            //       color: Colors.amber,
                            //       text: S.current.specimenSwab,
                            //       isSquare: false,
                            //     ),
                            //
                            //   ],
                            // ),
                            // Row(
                            //   mainAxisAlignment:
                            //       MainAxisAlignment.spaceEvenly,
                            //   children: <Widget>[
                            //     Indicator(
                            //       color: Colors.lightGreen,
                            //       text: S.current.specimenTissues,
                            //       isSquare: false,
                            //     ),
                            //     Indicator(
                            //       color: Colors.deepOrange,
                            //       text: S.current.specimenFeces,
                            //       isSquare: false,
                            //     ),
                            //     Indicator(
                            //       color: Colors.pink,
                            //       text: S.current.specimenRegurgite,
                            //       isSquare: false,
                            //     ),
                            //   ],
                            // ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  List<BarChartGroupData> createBarGroupsFromOccurrencesMap(Map<int, int> monthlyOccurrences, double barWidth,) {
    final List<BarChartGroupData> barGroups = [];
    monthlyOccurrences.forEach((month, count) {
      barGroups.add(
        BarChartGroupData(
          x: month, // month is the value of X axis
          barRods: [
            BarChartRodData(
              toY: count.toDouble(), // record count is the value of Y axis
              color: Colors.blue,
              width: barWidth,
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
