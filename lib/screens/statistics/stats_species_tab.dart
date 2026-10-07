import 'dart:io';

import 'package:fl_chart/fl_chart.dart';
import 'package:material_ui/material_ui.dart';
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
import '../../utils/themes.dart';

/// Per-species statistics tab with filters and species-level charts.
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
    required this.specimenProvider,
  });

  @override
  State<StatsSpeciesTab> createState() => _StatsSpeciesTabState();
}

/// Loads species-centric datasets and computes derived indicators.
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
  Map<int, int> _occurrencesByMonth = {for (var i = 1; i <= 12; i++) i: 0};
  Map<int, int> _occurrencesByYear = {};
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

  /// Loads the species names available for search and selection.
  Future<void> _loadData() async {
    try {
      recordedSpeciesNames = await getRecordedSpeciesList();
    } catch (e) {
      // Handle errors here, e.g., show a snackbar
      debugPrint('Error loading species data: $e');
    }
  }

  /// Loads all records and metrics for the currently selected species.
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
      allSpeciesList = await speciesProvider.getAllRecordsBySpecies(selectedSpecies ?? '');
      nestList = await nestProvider.getNestsBySpecies(selectedSpecies ?? '');
      totalSuccessNests = nestList.where((nest) => nest.nestFate == NestFateType.fatSuccess).length;
      totalNestsWithNidoparasitism =
          nestList.where((nest) {
            // Para cada ninho, verifique se *alguma* de suas revisões tem parasitismo.
            return nest.revisionsList!.any(
              (revision) => (revision.eggsParasite ?? 0) > 0 || (revision.nestlingsParasite ?? 0) > 0,
            );
          }).length;
      eggList = await eggProvider.getEggsBySpecies(selectedSpecies ?? '');
      specimenList = await specimenProvider.getSpecimensBySpecies(selectedSpecies ?? '');

      totalPoisCount = (allSpeciesList.map((s) => s.pois.length).fold(0, (a, b) => a + b));

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

      totalRecordsPerSpecies = allSpeciesList.length + nestList.length + eggList.length + specimenList.length;
      _occurrencesByMonth = await getOccurrencesByMonth(selectedSpecies);
      _occurrencesByYear = await getOccurrencesByYear(selectedSpecies);
      totalsSections =
          getTotalsByRecordType(allSpeciesList, nestList, eggList, specimenList).entries.map((entry) {
            return PieChartSectionData(
              showTitle: true,
              title: entry.value.toString(),
              value: entry.value.toDouble(),
              color: getRecordColor(entry.key),
              radius: 20,
            );
          }).toList();
      nestFateSections =
          getNestFateCounts(nestList).entries.map((entry) {
            return PieChartSectionData(
              showTitle: true,
              title: entry.value.toString(),
              value: entry.value.toDouble(),
              color: getNestFateColor(entry.key),
              radius: 20,
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
        return S.of(context).egg(2);
      case 'specimen':
        return S.of(context).specimens(2);
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (widget.inventoryProvider.allInventoriesCount == 0 &&
        widget.nestProvider.allNestsCount == 0 &&
        widget.specimenProvider.specimens.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.insert_chart_outlined, size: 48, color: Theme.of(context).colorScheme.surfaceDim),
            const SizedBox(height: 8),
            Text(S.current.noDataAvailable, style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: 16),
            ActionChip(
              label: Text(S.of(context).refresh),
              avatar: Icon(Icons.refresh_outlined),
              onPressed: () async {
                await _loadData();
              },
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSpeciesSelectorCard(isDark),
          const SizedBox(height: 16),

          if (selectedSpecies != null) ...[
            _buildSpeciesHeaderBanner(isDark),
            // const SizedBox(height: 16),
          ],
          SizedBox(height: 16.0),
          Expanded(
            child: SingleChildScrollView(
              // padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (selectedSpecies != null && !isLoadingSpecies) ...[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildRecordsByTypeCard(isDark),
                        const SizedBox(height: 16),

                        _buildMonthlyRecordsCard(isDark),
                        const SizedBox(height: 16),

                        _buildYearlyRecordsCard(isDark),
                        const SizedBox(height: 16),

                        _buildInventoryMetricsCard(isDark),
                        const SizedBox(height: 16),

                        _buildHourlyRecordsCard(isDark),
                        const SizedBox(height: 16),

                        _buildNestMetricsCard(isDark),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ] else if (isLoadingSpecies) ...[
                    Center(child: CircularProgressIndicator(year2023: false)),
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

  Widget _buildSpeciesSelectorCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.white,
        border: Border.all(color: isDark ? Colors.grey.shade800 : XolmisColors.borderSubtle),
        borderRadius: BorderRadius.circular(16),
        shape: BoxShape.rectangle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            S.current.selectSpecies,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey.shade400 : XolmisColors.secondary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.grey.shade900
                  : XolmisColors.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.grey.shade800
                    : XolmisColors.outlineVariant.withOpacity(0.5),
              ),
            ),
            child: SearchAnchor(
              searchController: searchController,
              isFullScreen: MediaQuery.of(context).size.width < 600,
              builder: (BuildContext context, SearchController controller) {
                return TextButton(
                  onPressed: () {
                    controller.openView();
                  },
                  child: Row(
                    children: [
                      const Icon(Icons.search_outlined),
                      const SizedBox(width: 8),
                      Text(
                        S.current.findSpecies,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.grey.shade400 : XolmisColors.secondary,
                        ),
                      ),
                    ],
                  ),
                );
              },
              suggestionsBuilder: (context, controller) {
                return List<String>.from(
                  recordedSpeciesNames,
                ).where((species) => speciesMatchesQuery(species, controller.text.toLowerCase())).map((species) {
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
                    },
                  );
                }).toList();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeciesHeaderBanner(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900.withValues(alpha: 0.8) : XolmisColors.jacarandaLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.grey.shade800 : XolmisColors.jacarandaContainer),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  S.current.selectedSpecies.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: XolmisColors.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  selectedSpecies ?? '',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: Platform.isIOS ? 'CupertinoSystemDisplay' : null,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.bold,
                    color: isDark ? XolmisColors.primaryContainer : XolmisColors.jacarandaDeep,
                  ),
                ),
                // Text(
                //   _selectedSpecies.commonName,
                //   style: TextStyle(
                //     fontSize: 12,
                //     color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                //   ),
                // ),
              ],
            ),
          ),
          // Container(
          //   width: 42,
          //   height: 42,
          //   decoration: BoxDecoration(
          //     color: XolmisColors.jacarandaCore.withValues(alpha: 0.15),
          //     shape: BoxShape.circle,
          //   ),
          //   child: const Icon(
          //     Icons.flutter_dash,
          //     color: XolmisColors.jacarandaDeep,
          //     size: 22,
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _buildRecordsByTypeCard(bool isDark) {
    final typeColors = {
      'Inventário': XolmisColors.primary,
      'Ninho': XolmisColors.success,
      'Ovo': XolmisColors.warning,
      'Espécime': const Color(0xFF14B8A6),
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.white,
        border: Border.all(color: isDark ? Colors.grey.shade800 : XolmisColors.borderSubtle),
        borderRadius: BorderRadius.circular(16),
        shape: BoxShape.rectangle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.pie_chart_outline, size: 18, color: XolmisColors.primary),
              const SizedBox(width: 8),
              Text(
                S.current.totalRecords,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: Row(
              children: [
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          pieTouchData: PieTouchData(
                            enabled: true,
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
                                _touchedIndexTotals = pieTouchResponse.touchedSection!.touchedSectionIndex;
                              });
                            },
                          ),
                          sectionsSpace: 2,
                          centerSpaceRadius: 38,
                          sections:
                              totalsSections.asMap().entries.map((entry) {
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
                                  title:
                                      isTouched
                                          ? getRecordFriendlyName(
                                            getRecordTypeFromColor(color),
                                            context,
                                          ) // Função para obter o nome amigável
                                          : sectionData.value.toInt().toString(),
                                );
                              }).toList(),
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${totalRecordsPerSpecies}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          Text(
                            'total',
                            style: TextStyle(fontSize: 10, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Column(
                //   mainAxisAlignment: MainAxisAlignment.center,
                //   crossAxisAlignment: CrossAxisAlignment.start,
                //   children: selectedSpecies.recordsByType.entries.map((entry) {
                //     final color =
                //         typeColors[entry.key] ?? XolmisColors.secondary;
                //     return Padding(
                //       padding: const EdgeInsets.only(bottom: 6.0),
                //       child: Row(
                //         children: [
                //           Container(
                //             width: 10,
                //             height: 10,
                //             decoration: BoxDecoration(
                //               color: color,
                //               shape: BoxShape.circle,
                //             ),
                //           ),
                //           const SizedBox(width: 8),
                //           Text(
                //             entry.key,
                //             style: TextStyle(
                //               fontSize: 11,
                //               fontWeight: FontWeight.w500,
                //               color: isDark
                //                   ? Colors.grey.shade300
                //                   : Colors.grey.shade800,
                //             ),
                //           ),
                //         ],
                //       ),
                //     );
                //   }).toList(),
                // ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyRecordsCard(bool isDark) {
    const monthLabels = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];

    final maxMonthly = _occurrencesByMonth.values.toList().fold(1, (max, v) => v > max ? v : max);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.white,
        border: Border.all(color: isDark ? Colors.grey.shade800 : XolmisColors.borderSubtle),
        borderRadius: BorderRadius.circular(16),
        shape: BoxShape.rectangle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_month_outlined, size: 18, color: XolmisColors.primary),
              const SizedBox(width: 8),
              Text(
                S.current.recordsPerMonth,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxMonthly.toDouble() + 2,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => XolmisColors.jacarandaDeep,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${monthLabels[groupIndex]}: ${rod.toY.round()} reg.',
                        TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 20,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt() - 1;
                        if (idx >= 0 && idx < 12) {
                          return Text(
                            monthLabels[idx],
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(fontSize: 9, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine:
                      (value) => FlLine(
                        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                        strokeWidth: 1,
                      ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    left: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200, width: 2),
                    bottom: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200, width: 2),
                  ),
                ),
                barGroups: createBarGroupsFromOccurrencesMap(_occurrencesByMonth, 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYearlyRecordsCard(bool isDark) {
    final years = _occurrencesByYear.keys.toList()..sort();
    final values = _occurrencesByYear.values.toList();
    final maxYearly = values.fold(1, (max, v) => v > max ? v : max);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.white,
        border: Border.all(color: isDark ? Colors.grey.shade800 : XolmisColors.borderSubtle),
        borderRadius: BorderRadius.circular(16),
        shape: BoxShape.rectangle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.trending_up, size: 18, color: XolmisColors.primary),
              const SizedBox(width: 8),
              Text(
                S.current.speciesRichnessPerYear,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 130,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxYearly.toDouble() + 3,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => XolmisColors.jacarandaDeep,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${rod.toY.round()} spp.',
                        TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final year = value.toInt();
                        if (value == year && years.contains(year)) {
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(
                              year.toString(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(fontSize: 9, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine:
                      (value) => FlLine(
                        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                        strokeWidth: 1,
                      ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    left: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200, width: 2),
                    bottom: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200, width: 2),
                  ),
                ),
                barGroups: createBarGroupsFromYearOccurrencesMap(_occurrencesByYear),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryMetricsCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.white,
        border: Border.all(color: isDark ? Colors.grey.shade800 : XolmisColors.borderSubtle),
        borderRadius: BorderRadius.circular(16),
        shape: BoxShape.rectangle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.assignment_outlined, size: 18, color: XolmisColors.primary),
              const SizedBox(width: 8),
              Text(
                S.current.inventories,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildSubStatMetricBox(
                S.current.relativeAbundance,
                '${relativeAbundance.toStringAsFixed(1)}%',
                XolmisColors.primary,
                isDark,
              ),
              _buildSubStatMetricBox(
                S.current.relativeFrequency,
                '${relativeFrequency.toStringAsFixed(1)}%',
                XolmisColors.primary,
                isDark,
              ),
              _buildSubStatMetricBox(
                S.current.totalAbundance,
                '${totalAbundance.toStringAsFixed(1)}',
                XolmisColors.primary,
                isDark,
              ),
              _buildSubStatMetricBox(
                S.current.poisRecorded(totalPoisCount),
                '${totalPoisCount}',
                XolmisColors.primary,
                isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNestMetricsCard(bool isDark) {
    final hasNestFateData = nestFateSections.any((section) => section.value > 0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.white,
        border: Border.all(color: isDark ? Colors.grey.shade800 : XolmisColors.borderSubtle),
        borderRadius: BorderRadius.circular(16),
        shape: BoxShape.rectangle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.egg_outlined, size: 18, color: XolmisColors.primary),
              const SizedBox(width: 8),
              Text(
                S.current.nests,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: XolmisColors.successContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: XolmisColors.success.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${totalSuccessNests}%',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: XolmisColors.success),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        S.current.apparentSuccessRate,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: XolmisColors.onSuccessContainer,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: XolmisColors.warningContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: XolmisColors.warning.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${totalNestsWithNidoparasitism}%',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: XolmisColors.warning),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        S.current.nidoparasitismRate,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: XolmisColors.onWarningContainer,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            S.current.nestFate,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey.shade300 : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 150,
            child:
                hasNestFateData
                    ? Row(
                      children: [
                        Expanded(
                          child: PieChart(
                            PieChartData(
                              pieTouchData: PieTouchData(
                                enabled: true,
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
                                    _touchedIndexNestFate = pieTouchResponse.touchedSection!.touchedSectionIndex;
                                  });
                                },
                              ),
                              sectionsSpace: 2,
                              centerSpaceRadius: 35,
                              sections:
                                  nestFateSections.asMap().entries.map((entry) {
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
                                      title:
                                          isTouched
                                              ? getNestFateFriendlyName(
                                                getNestFateFromColor(color),
                                                context,
                                              ) // Função para obter o nome amigável
                                              : sectionData.value.toInt().toString(),
                                    );
                                  }).toList(),
                            ),
                          ),
                        ),
                      ],
                    )
                    : Center(
                      child: Text(
                        S.current.noDataAvailable,
                        style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildHourlyRecordsCard(bool isDark) {
    final hourlyOccurrences = getOccurrencesByHourOfDay(allSpeciesList);
    final hasHourlyData = hourlyOccurrences.values.any((count) => count > 0);
    final maxHourly = hourlyOccurrences.values.fold(1, (max, count) => count > max ? count : max);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.white,
        border: Border.all(color: isDark ? Colors.grey.shade800 : XolmisColors.borderSubtle),
        borderRadius: BorderRadius.circular(16),
        shape: BoxShape.rectangle,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.access_time_outlined, size: 18, color: XolmisColors.primary),
              const SizedBox(width: 8),
              Text(
                S.current.recordsByHour,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child:
                hasHourlyData
                    ? BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: maxHourly.toDouble() + 2,
                        barTouchData: BarTouchData(
                          enabled: true,
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipColor: (_) => XolmisColors.jacarandaDeep,
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              return BarTooltipItem(
                                '${group.x.toString().padLeft(2, '0')}h: ${rod.toY.round()} reg.',
                                TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                              );
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 22,
                              interval: 4,
                              getTitlesWidget: (value, meta) {
                                final hour = value.toInt();
                                if (value == hour && hour >= 0 && hour < 24 && hour % 4 == 0) {
                                  return Text(
                                    '${hour}h',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 24,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  value.toInt().toString(),
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                  ),
                                );
                              },
                            ),
                          ),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine:
                              (value) => FlLine(
                                color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                                strokeWidth: 1,
                              ),
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: Border(
                            left: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200, width: 2),
                            bottom: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200, width: 2),
                          ),
                        ),
                        barGroups: createBarGroupsFromOccurrencesMap(hourlyOccurrences, 12),
                      ),
                    )
                    : Center(
                      child: Text(
                        S.current.noDataAvailable,
                        style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubStatMetricBox(String title, String value, Color valueColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : XolmisColors.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.grey.shade800 : XolmisColors.outlineVariant.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: valueColor)),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  List<BarChartGroupData> createBarGroupsFromOccurrencesMap(Map<int, int> monthlyOccurrences, double barWidth) {
    final List<BarChartGroupData> barGroups = [];
    monthlyOccurrences.forEach((month, count) {
      barGroups.add(
        BarChartGroupData(
          x: month, // month is the value of X axis
          barRods: [
            BarChartRodData(
              toY: count.toDouble(), // record count is the value of Y axis
              color: XolmisColors.jacarandaCore,
              width: barWidth,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(6), topRight: Radius.circular(6)),
            ),
          ],
        ),
      );
    });
    return barGroups;
  }

  List<BarChartGroupData> createBarGroupsFromYearOccurrencesMap(Map<int, int> yearlyOccurrences) {
    final List<BarChartGroupData> barGroups = [];
    yearlyOccurrences.forEach((year, count) {
      barGroups.add(
        BarChartGroupData(
          x: year, // month is the value of X axis
          barRods: [
            BarChartRodData(
              toY: count.toDouble(), // record count is the value of Y axis
              color: XolmisColors.primary,
              width: 16,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(6), topRight: Radius.circular(6)),
            ),
          ],
        ),
      );
    });
    return barGroups;
  }
}
