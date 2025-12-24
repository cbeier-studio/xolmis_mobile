import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/core_consts.dart';
import '../../data/models/inventory.dart';
import '../../data/models/nest.dart';
import '../../data/models/specimen.dart';
import '../../generated/l10n.dart';
import '../../providers/egg_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/nest_provider.dart';
import '../../providers/species_provider.dart';
import '../../providers/specimen_provider.dart';
import '../../utils/statistics_logic.dart';
import '../../utils/utils.dart';

class StatsSpeciesTab extends StatefulWidget {
  final InventoryProvider inventoryProvider;
  final SpeciesProvider speciesProvider;
  final NestProvider nestProvider;
  final EggProvider eggProvider;
  final SpecimenProvider specimenProvider;
  const StatsSpeciesTab({
    super.key,
    required this.inventoryProvider,
    required this.speciesProvider,
    required this.nestProvider,
    required this.eggProvider,
    required this.specimenProvider
  });

  @override
  State<StatsSpeciesTab> createState() => _StatsSpeciesTabState();
}

class _StatsSpeciesTabState extends State<StatsSpeciesTab> with AutomaticKeepAliveClientMixin {
  final SearchController searchController = SearchController();
  List<Species> allSpeciesList = [];
  List<Nest> nestList = [];
  List<Egg> eggList = [];
  List<Specimen> specimenList = [];
  String? selectedSpecies;
  int totalRecordsPerSpecies = 0;
  double relativeFrequency = 0.0;
  double relativeAbundance = 0.0;
  int totalAbundance = 0;
  int totalPoisCount = 0;
  bool isLoadingSpecies = false;
  int _touchedIndexNestFate = -1;
  int _touchedIndexTotals = -1;
  List<PieChartSectionData> totalsSections = [];
  List<String> recordedSpeciesNames = [];
  int totalSuccessNests = 0;
  int totalNestsWithNidoparasitism = 0;
  List<PieChartSectionData> nestFateSections = [];

  @override
  bool get wantKeepAlive => true;

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
    setState(() {
      isLoadingSpecies = true;
    });

    try {
    allSpeciesList = await speciesProvider.getAllRecordsBySpecies(
      selectedSpecies ?? '',
    );
    nestList = await nestProvider.getNestsBySpecies(selectedSpecies ?? '');
    totalSuccessNests = nestList.where((nest) => nest.nestFate == NestFateType.fatSuccess).length;
    totalNestsWithNidoparasitism = nestList.where((nest) {
      // Para cada ninho, verifique se *alguma* de suas revisões tem parasitismo.
      return nest.revisionsList!.any((revision) =>
      (revision.eggsParasite ?? 0) > 0 || (revision.nestlingsParasite ?? 0) > 0
      );
    }).length;
    eggList = await eggProvider.getEggsBySpecies(selectedSpecies ?? '');
    specimenList = await specimenProvider.getSpecimensBySpecies(
      selectedSpecies ?? '',
    );

    totalPoisCount = (allSpeciesList.map((s) => s.pois.length).fold(0,(a, b) => a + b));

    final totalInventories = widget.inventoryProvider.allInventoriesCount;
    final totalRecordsOfAllSpecies = await speciesProvider.getTotalRecordsOfAllSpecies();

    if (totalInventories > 0) {
      final inventoryIdsWithSpecies = allSpeciesList.map((s) => s.inventoryId).toSet();
      relativeFrequency = (inventoryIdsWithSpecies.length / totalInventories) * 100;
    } else {
      relativeFrequency = 0.0;
    }
    final totalRecordsForSelectedSpecies = allSpeciesList.length;
    if (totalRecordsOfAllSpecies > 0) {
      relativeAbundance = (totalRecordsForSelectedSpecies / totalRecordsOfAllSpecies) * 100;
    } else {
      relativeAbundance = 0.0;
    }
    int individualsRecorded = allSpeciesList.fold(0, (sum, species) {
      return sum + species.count;
    });
    totalAbundance = individualsRecorded;

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
    } catch (e, s) {
      debugPrint('[STATS_SPECIES_TAB] Error loading data lists: $e\n$s');
    } finally {
      if (mounted) {
        setState(() {
          isLoadingSpecies = false;
        });
      }
    }
  }

  String getRecordFriendlyName(String recordType, BuildContext context) {
    switch (recordType) {
      case 'inventory':
        return S.of(context).inventories;
      case 'nest':
        return S.of(context).nests;
      case 'egg':
        return S.of(context).egg(2); // "Ovos"
      case 'specimen':
        return S.of(context).specimens(2); // "Espécimes"
      default:
        return '';
    }
  }

  String getRecordTypeFromColor(Color color) {
    if (color == Colors.blue) return 'inventory';
    if (color == Colors.orange) return 'nest';
    if (color == Colors.green) return 'egg';
    if (color == Colors.purple) return 'specimen';
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

    if (widget.speciesProvider.getAllInventoryIds().isEmpty &&
        widget.nestProvider.nestsCount == 0 &&
        widget.specimenProvider.specimensCount == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
          Icon(
          Icons.insert_chart_outlined,
          size: 48,
          color: Theme.of(context).colorScheme.surfaceDim,
        ),
        const SizedBox(height: 8),
        Text(
          S.current.noDataAvailable,
          style: Theme.of(context).textTheme.titleMedium,
        ),
            SizedBox(height: 16),
            ActionChip(
                label: Text(S.of(context).refresh),
                avatar: Icon(Icons.refresh_outlined),
                onPressed: () async {
                  await _loadData();
                }
            )
        ],
        ),
      );
    }

    return Padding(
        padding: const EdgeInsets.all(16.0),
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
                    widget.speciesProvider,
                    widget.nestProvider,
                    widget.eggProvider,
                    widget.specimenProvider,
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
                style: const TextStyle(
                  color: Colors.deepPurple,
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                  fontSize: 16,
                ),
              ),
            ],
            SizedBox(height: 16.0),
        Expanded(child:
        SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (selectedSpecies != null && !isLoadingSpecies) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Expanded(child:
                    // Total records per species
                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Text(
                              S.current.totalRecords,
                              style: TextTheme.of(context).titleMedium,
                            ),
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                Text(
                                  totalRecordsPerSpecies.toString(),
                                  style: TextTheme.of(context).headlineSmall,
                                ),
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
                                              _touchedIndexTotals = -1; // Nenhuma seção está sendo tocada
                                              return;
                                            }
                                            // Atualiza o estado com o índice da seção tocada
                                            _touchedIndexTotals =
                                                pieTouchResponse.touchedSection!
                                                    .touchedSectionIndex;
                                          });
                                        },
                                      ),
                                      sectionsSpace: 2,
                                      centerSpaceRadius: 50,
                                      sections: totalsSections.asMap().entries.map((entry) {
                                        final index = entry.key;
                                        final sectionData = entry.value;
                                        final isTouched = index == _touchedIndexTotals;

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
                                              ? getRecordFriendlyName(getRecordTypeFromColor(color), context) // Função para obter o nome amigável
                                              : sectionData.value.toInt().toString(),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            // SizedBox(height: 8.0),
                            // Row(
                            //   mainAxisAlignment:
                            //   MainAxisAlignment.spaceEvenly,
                            //   children: <Widget>[
                            //     Indicator(
                            //       color: Colors.blue,
                            //       text: S.current.inventories,
                            //       isSquare: false,
                            //     ),
                            //     Indicator(
                            //       color: Colors.orange,
                            //       text: S.current.nests,
                            //       isSquare: false,
                            //     ),
                            //     Indicator(
                            //       color: Colors.green,
                            //       text: S.current.egg(2),
                            //       isSquare: false,
                            //     ),
                            //     Indicator(
                            //       color: Colors.purple,
                            //       text: S.current.specimens(2),
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
    Row(
    mainAxisAlignment: MainAxisAlignment.start,
    children: [
    Expanded(child:
                    // Records per month
                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Text(
                              S.current.recordsPerMonth,
                              style: TextTheme.of(context).titleMedium,
                            ),
                            const SizedBox(height: 8,),
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
                                      getTooltipColor: (spot) => Colors.white.withAlpha(200),
                                      fitInsideVertically: true,
                                      fitInsideHorizontally: true,
                                    ),
                                  ),
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
                                    ), 16,
                                  ),
                                ),
                              ),
                            ),
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
                    // Records per year
                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Text(
                              S.current.recordsPerYear,
                              style: TextTheme.of(context).titleMedium,
                            ),
                            const SizedBox(height: 8,),
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
                                        getTooltipColor: (spot) => Colors.white.withAlpha(200),
                                        fitInsideVertically: true,
                                        fitInsideHorizontally: true,
                                      ),
                                  ),
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
    ),
                    ],
    ),
                    SizedBox(height: 16.0),
                    Text(
                      S.current.inventories,
                      style: TextTheme.of(context).titleLarge,
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
                                  relativeAbundance.toStringAsFixed(1),
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: Theme.of(context).textTheme.headlineSmall?.fontWeight,
                                    fontSize: Theme.of(context).textTheme.headlineSmall?.fontSize,
                                  ),
                                ),
                                Text(S.current.relativeAbundance),
                              ],
                            ),
                          ),
                        ),
                        ),
                        // Detection rate
                        Expanded(child:
                        Card(
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  relativeFrequency.toStringAsFixed(1),
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: Theme.of(context).textTheme.headlineSmall?.fontWeight,
                                    fontSize: Theme.of(context).textTheme.headlineSmall?.fontSize,
                                  ),
                                ),
                                Text(S.current.relativeFrequency),
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
                        // Apparent success rate
                        Expanded(child:
                        Card(
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  totalAbundance.toString(),
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: Theme.of(context).textTheme.headlineSmall?.fontWeight,
                                    fontSize: Theme.of(context).textTheme.headlineSmall?.fontSize,
                                  ),
                                ),
                                Text(S.current.totalAbundance),
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
                                allSpeciesList.isNotEmpty ?
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
                                            getOccurrencesByHourOfDay(
                                              allSpeciesList,
                                            ), 12,
                                          ),
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
                        ),
                      ],
                    ),
                    SizedBox(height: 16.0),
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
                                  (totalSuccessNests / widget.nestProvider.inactiveNestsCount * 100).toStringAsFixed(1),
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
                              S.current.nestFate,
                              style: TextTheme.of(context).titleMedium,
                            ),
                            nestList.isNotEmpty ? Stack(
                              alignment: Alignment.center,
                              children: [
                                Text(
                                  nestList.length.toString(),
                                  style: TextTheme.of(context).headlineSmall,
                                ),
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
                                ),
                              ],
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
    ),
    ],
    ),
                  ],
                ),


              ] else if (isLoadingSpecies) ...[
                Center(child: CircularProgressIndicator(
                  year2023: false,
                )),
              ] else ...[
                Center(child: Text(S.current.selectSpeciesToShowStats)),
              ],
            ],
          ),
        ),
        ),
      ],
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
