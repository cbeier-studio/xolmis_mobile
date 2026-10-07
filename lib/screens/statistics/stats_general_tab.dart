import 'dart:io';
import 'package:fl_chart/fl_chart.dart';
import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';
import 'package:xolmis/providers/inventory_provider.dart';
import 'package:xolmis/providers/nest_provider.dart';
import 'package:xolmis/providers/poi_provider.dart';
import 'package:xolmis/providers/species_provider.dart';

import '../../generated/l10n.dart';

import '../../data/models/inventory.dart';
import '../../providers/egg_provider.dart';
import '../../providers/specimen_provider.dart';
import '../../utils/statistics_logic.dart';
import '../../utils/themes.dart';
import 'all_species_records_screen.dart';

/// General statistics tab aggregating inventories, nests, and specimens.
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

/// Loads and renders high-level project metrics and charts.
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
  late Map<int, int> recordsByMonth = {};
  late Map<int, int> speciesRichnessByMonth = {};
  late Map<int, int> speciesRichnessByYear = {};
  int _touchedIndexSpecimenType = -1;
  int _touchedIndexNestFate = -1;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadGeneralData();
  }

  /// Fetches all general statistics required by this tab.
  Future<void> _loadGeneralData() async {
    try {
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

      recordsPerHour = await getAllOccurrencesByHourOfDay();

      recordsByMonth = await getOccurrencesByMonth(null);
      speciesRichnessByMonth = await getSpeciesRichnessPerMonthGlobal();
      speciesRichnessByYear = await getSpeciesRichnessPerYearGlobal();

      final specimenTypeCounts = await getSpecimenTypeCounts();
      specimenTypeSections =
          specimenTypeCounts.entries.map((entry) {
            return PieChartSectionData(
              showTitle: true,
              title: entry.value.toString(),
              value: entry.value.toDouble(),
              color: getSpecimenColor(entry.key),
              radius: 20,
            );
          }).toList();
      nestFateSections =
          getNestFateCounts(widget.nestProvider.nests).entries.map((entry) {
            return PieChartSectionData(
              showTitle: true,
              title: entry.value.toString(),
              value: entry.value.toDouble(),
              color: getNestFateColor(entry.key),
              radius: 20,
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

  /// Helper method to create bar groups from month occurrences map
  List<BarChartGroupData> _createBarGroupsFromMonthOccurrencesMap(
    Map<int, int> monthlyOccurrences,
    double barWidth,
    Color barColor,
  ) {
    final List<BarChartGroupData> barGroups = [];
    monthlyOccurrences.forEach((month, count) {
      barGroups.add(
        BarChartGroupData(
          x: month,
          barRods: [
            BarChartRodData(
              toY: count.toDouble(),
              color: barColor,
              width: barWidth,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(6), topRight: Radius.circular(6)),
            ),
          ],
        ),
      );
    });
    return barGroups;
  }

  /// Helper method to create bar groups from year occurrences map
  List<BarChartGroupData> _createBarGroupsFromYearOccurrencesMap(
    Map<int, int> yearlyOccurrences,
    double barWidth,
    Color barColor,
  ) {
    final List<BarChartGroupData> barGroups = [];
    // Sort years to display them in chronological order
    final sortedYears = yearlyOccurrences.keys.toList()..sort();

    for (var i = 0; i < sortedYears.length; i++) {
      final year = sortedYears[i];
      final count = yearlyOccurrences[year] ?? 0;
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: count.toDouble(),
              color: barColor,
              width: barWidth,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(6), topRight: Radius.circular(6)),
            ),
          ],
        ),
      );
    }
    return barGroups;
  }

  /// Helper method to get full month name
  String _getMonthName(int month) {
    try {
      return DateFormat('MMMM').format(DateTime(0, month));
    } catch (e) {
      return '';
    }
  }

  /// Helper method to get abbreviated month name (first letter uppercase)
  String _getMonthAbbrName(int month) {
    try {
      String monthAbbreviation = DateFormat('MMM').format(DateTime(0, month));
      return monthAbbreviation[0].toUpperCase();
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (widget.inventoryProvider.allInventoriesCount == 0 &&
        widget.nestProvider.allNestsCount == 0 &&
        widget.specimenProvider.specimensCount == 0) {
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
                await _loadGeneralData();
              },
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildKpiMetricsGrid(context, isDark),
          const SizedBox(height: 16),

          _buildTopSpeciesCard(context, isDark),
          const SizedBox(height: 16),

          _buildHourlyChartCard(context, isDark),
          const SizedBox(height: 16),

          _buildMonthlyRecordsCard(isDark),
          const SizedBox(height: 16),

          _buildMonthlyRichnessCard(isDark),
          const SizedBox(height: 16),

          _buildYearlyRecordsCard(isDark),
          const SizedBox(height: 16),

          // Row(
          //   mainAxisAlignment: MainAxisAlignment.start,
          //   children: [
          //     Expanded(child:
          //     // Nest fate per species
          //     Card(
          //       child: Padding(
          //         padding: EdgeInsets.all(16.0),
          //         child: Column(
          //           children: [
          //             Text(
          //               S.current.recordsByHour,
          //               style: TextTheme.of(context).titleMedium,
          //             ),
          //             const SizedBox(height: 8,),
          //             recordsPerHour.isNotEmpty ?
          //             SizedBox(
          //               height: 150,
          //               child: BarChart(
          //                 BarChartData(
          //                   alignment: BarChartAlignment.spaceAround,
          //                   gridData: FlGridData(show: false),
          //                   borderData: FlBorderData(
          //                     show: true,
          //                     border: Border(
          //                       bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.5), width: 1),
          //                     ),
          //                   ),
          //                   barTouchData: BarTouchData(
          //                     enabled: true,
          //                     touchTooltipData: BarTouchTooltipData(
          //                         fitInsideHorizontally: true,
          //                         fitInsideVertically: true,
          //                         getTooltipColor: (spot) => Colors.white.withValues(alpha: 0.8),
          //                         getTooltipItem: (group, groupIndex, rod, rodIndex) {
          //                           final hour = group.x.toInt();
          //                           final value = rod.toY.toInt();
          //                           if (value == 0) {
          //                             return null;
          //                           }
          //                           return BarTooltipItem(
          //                             '', // Main string empty, we use the children
          //                             const TextStyle(),
          //                             children: [
          //                               TextSpan(
          //                                 text: '$value\n',
          //                                 style: const TextStyle(
          //                                   color: Colors.blue,
          //                                   fontWeight: FontWeight.bold,
          //                                   fontSize: 16,
          //                                 ),
          //                               ),
          //                               TextSpan(
          //                                 text: '${hour.toString().padLeft(2, '0')} h',
          //                                 style: const TextStyle(
          //                                   color: Colors.black87,
          //                                   fontWeight: FontWeight.normal,
          //                                   fontSize: 12,
          //                                 ),
          //                               ),
          //                             ],
          //                           );
          //                         }
          //                     ),
          //                   ),
          //                   titlesData: FlTitlesData(
          //                     show: true,
          //                     bottomTitles: AxisTitles(
          //                       sideTitles: SideTitles(
          //                         showTitles: true,
          //                         reservedSize: 30,
          //                         getTitlesWidget: (value, meta) {
          //                           // Show X axis titles only on specific intervals.
          //                           final hour = value.toInt();
          //                           if (hour % 3 == 0 || hour == 23) {
          //                             return SideTitleWidget(meta: meta, child: Text(hour.toString().padLeft(2, '0')));
          //                           } else {
          //                             return SideTitleWidget(meta: meta, child: const Text(''));
          //                           }
          //                         },
          //                       ),
          //                     ),
          //                     leftTitles: AxisTitles(
          //                       sideTitles: SideTitles(showTitles: false, reservedSize: 28),
          //                     ),
          //                     topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          //                     rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          //                   ),
          //                   barGroups: createBarGroupsFromOccurrencesMap(
          //                     recordsPerHour,
          //                     12,
          //                   ),
          //                 ),
          //               ),
          //             ) : Text(S.current.noDataAvailable),
          //           ],
          //         ),
          //       ),
          //     ),
          //     ),
          //    ],
          //  ),
          // Row(
          //   mainAxisAlignment: MainAxisAlignment.start,
          //   children: [
          //     Expanded(
          //       child: Card(
          //         child: Padding(
          //           padding: EdgeInsets.all(16.0),
          //           child: Column(
          //             children: [
          //               Text(S.current.recordsPerMonth, style: TextTheme.of(context).titleMedium),
          //               const SizedBox(height: 8),
          //               SizedBox(
          //                 height: 150,
          //                 child: BarChart(
          //                   BarChartData(
          //                     alignment: BarChartAlignment.spaceAround,
          //                     gridData: FlGridData(show: false),
          //                     borderData: FlBorderData(
          //                       show: true,
          //                       border: Border(bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.5), width: 1)),
          //                     ),
          //                     barTouchData: BarTouchData(
          //                       enabled: true,
          //                       touchTooltipData: BarTouchTooltipData(
          //                         fitInsideHorizontally: true,
          //                         fitInsideVertically: true,
          //                         getTooltipColor: (spot) => Colors.white.withValues(alpha: 0.8),
          //                         getTooltipItem: (group, groupIndex, rod, rodIndex) {
          //                           final month = group.x.toInt();
          //                           final value = rod.toY.toInt();
          //                           if (value == 0) {
          //                             return null;
          //                           }
          //                           return BarTooltipItem(
          //                             '',
          //                             const TextStyle(),
          //                             children: [
          //                               TextSpan(
          //                                 text: '$value\n',
          //                                 style: const TextStyle(
          //                                   color: Colors.blue,
          //                                   fontWeight: FontWeight.bold,
          //                                   fontSize: 16,
          //                                 ),
          //                               ),
          //                               TextSpan(
          //                                 text: _getMonthName(month),
          //                                 style: const TextStyle(
          //                                   color: Colors.black87,
          //                                   fontWeight: FontWeight.normal,
          //                                   fontSize: 12,
          //                                 ),
          //                               ),
          //                             ],
          //                           );
          //                         },
          //                       ),
          //                     ),
          //                     titlesData: FlTitlesData(
          //                       show: true,
          //                       bottomTitles: AxisTitles(
          //                         sideTitles: SideTitles(
          //                           showTitles: true,
          //                           reservedSize: 30,
          //                           getTitlesWidget: (value, meta) {
          //                             final month = value.toInt();
          //                             return SideTitleWidget(meta: meta, child: Text(_getMonthAbbrName(month)));
          //                           },
          //                         ),
          //                       ),
          //                       leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false, reservedSize: 28)),
          //                       topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          //                       rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          //                     ),
          //                     barGroups: _createBarGroupsFromMonthOccurrencesMap(recordsByMonth, 14, Colors.blue),
          //                   ),
          //                 ),
          //               ),
          //             ],
          //           ),
          //         ),
          //       ),
          //     ),
          //   ],
          // ),
          // Row(
          //   mainAxisAlignment: MainAxisAlignment.start,
          //   children: [
          //     Expanded(
          //       child: Card(
          //         child: Padding(
          //           padding: EdgeInsets.all(16.0),
          //           child: Column(
          //             children: [
          //               Text(S.current.speciesRichnessPerMonth, style: TextTheme.of(context).titleMedium),
          //               const SizedBox(height: 8),
          //               SizedBox(
          //                 height: 150,
          //                 child: BarChart(
          //                   BarChartData(
          //                     alignment: BarChartAlignment.spaceAround,
          //                     gridData: FlGridData(show: false),
          //                     borderData: FlBorderData(
          //                       show: true,
          //                       border: Border(bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.5), width: 1)),
          //                     ),
          //                     barTouchData: BarTouchData(
          //                       enabled: true,
          //                       touchTooltipData: BarTouchTooltipData(
          //                         fitInsideHorizontally: true,
          //                         fitInsideVertically: true,
          //                         getTooltipColor: (spot) => Colors.white.withValues(alpha: 0.8),
          //                         getTooltipItem: (group, groupIndex, rod, rodIndex) {
          //                           final month = group.x.toInt();
          //                           final value = rod.toY.toInt();
          //                           if (value == 0) {
          //                             return null;
          //                           }
          //                           return BarTooltipItem(
          //                             '',
          //                             const TextStyle(),
          //                             children: [
          //                               TextSpan(
          //                                 text: '$value\n',
          //                                 style: const TextStyle(
          //                                   color: Colors.deepPurple,
          //                                   fontWeight: FontWeight.bold,
          //                                   fontSize: 16,
          //                                 ),
          //                               ),
          //                               TextSpan(
          //                                 text: _getMonthName(month),
          //                                 style: const TextStyle(
          //                                   color: Colors.black87,
          //                                   fontWeight: FontWeight.normal,
          //                                   fontSize: 12,
          //                                 ),
          //                               ),
          //                             ],
          //                           );
          //                         },
          //                       ),
          //                     ),
          //                     titlesData: FlTitlesData(
          //                       show: true,
          //                       bottomTitles: AxisTitles(
          //                         sideTitles: SideTitles(
          //                           showTitles: true,
          //                           reservedSize: 30,
          //                           getTitlesWidget: (value, meta) {
          //                             final month = value.toInt();
          //                             return SideTitleWidget(meta: meta, child: Text(_getMonthAbbrName(month)));
          //                           },
          //                         ),
          //                       ),
          //                       leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false, reservedSize: 28)),
          //                       topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          //                       rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          //                     ),
          //                     barGroups: _createBarGroupsFromMonthOccurrencesMap(
          //                       speciesRichnessByMonth,
          //                       14,
          //                       Colors.deepPurple,
          //                     ),
          //                   ),
          //                 ),
          //               ),
          //             ],
          //           ),
          //         ),
          //       ),
          //     ),
          //   ],
          // ),
          // Row(
          //   mainAxisAlignment: MainAxisAlignment.start,
          //   children: [
          //     Expanded(
          //       child: Card(
          //         child: Padding(
          //           padding: EdgeInsets.all(16.0),
          //           child: Column(
          //             children: [
          //               Text(S.current.speciesRichnessPerYear, style: TextTheme.of(context).titleMedium),
          //               const SizedBox(height: 8),
          //               speciesRichnessByYear.isNotEmpty
          //                   ? SizedBox(
          //                     height: 150,
          //                     child: BarChart(
          //                       BarChartData(
          //                         alignment: BarChartAlignment.spaceAround,
          //                         gridData: FlGridData(show: false),
          //                         borderData: FlBorderData(
          //                           show: true,
          //                           border: Border(
          //                             bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.5), width: 1),
          //                           ),
          //                         ),
          //                         barTouchData: BarTouchData(
          //                           enabled: true,
          //                           touchTooltipData: BarTouchTooltipData(
          //                             fitInsideHorizontally: true,
          //                             fitInsideVertically: true,
          //                             getTooltipColor: (spot) => Colors.white.withValues(alpha: 0.8),
          //                             getTooltipItem: (group, groupIndex, rod, rodIndex) {
          //                               final sortedYears = speciesRichnessByYear.keys.toList()..sort();
          //                               final year = sortedYears[groupIndex];
          //                               final value = rod.toY.toInt();
          //                               if (value == 0) {
          //                                 return null;
          //                               }
          //                               return BarTooltipItem(
          //                                 '',
          //                                 const TextStyle(),
          //                                 children: [
          //                                   TextSpan(
          //                                     text: '$value\n',
          //                                     style: const TextStyle(
          //                                       color: Colors.teal,
          //                                       fontWeight: FontWeight.bold,
          //                                       fontSize: 16,
          //                                     ),
          //                                   ),
          //                                   TextSpan(
          //                                     text: year.toString(),
          //                                     style: const TextStyle(
          //                                       color: Colors.black87,
          //                                       fontWeight: FontWeight.normal,
          //                                       fontSize: 12,
          //                                     ),
          //                                   ),
          //                                 ],
          //                               );
          //                             },
          //                           ),
          //                         ),
          //                         titlesData: FlTitlesData(
          //                           show: true,
          //                           bottomTitles: AxisTitles(
          //                             sideTitles: SideTitles(
          //                               showTitles: true,
          //                               reservedSize: 30,
          //                               getTitlesWidget: (value, meta) {
          //                                 final sortedYears = speciesRichnessByYear.keys.toList()..sort();
          //                                 final index = value.toInt();
          //                                 if (index >= 0 && index < sortedYears.length) {
          //                                   return SideTitleWidget(
          //                                     meta: meta,
          //                                     child: Text(sortedYears[index].toString()),
          //                                   );
          //                                 } else {
          //                                   return SideTitleWidget(meta: meta, child: Text(''));
          //                                 }
          //                               },
          //                             ),
          //                           ),
          //                           leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false, reservedSize: 28)),
          //                           topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          //                           rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          //                         ),
          //                         barGroups: _createBarGroupsFromYearOccurrencesMap(
          //                           speciesRichnessByYear,
          //                           14,
          //                           Colors.teal,
          //                         ),
          //                       ),
          //                     ),
          //                   )
          //                   : Text(S.current.noDataAvailable),
          //             ],
          //           ),
          //         ),
          //       ),
          //     ),
          //   ],
          // ),
          // SizedBox(height: 16),

          _buildInventoryStatsCard(context, isDark),
          const SizedBox(height: 16),

          _buildNestStatsCard(context, isDark),
          const SizedBox(height: 16),

          _buildSpecimenStatsCard(context, isDark),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildKpiMetricsGrid(BuildContext context, bool isDark) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.1,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildMetricTile(
          label: S.current.recordedSpecies,
          value: '${totalDistinctSpecies}',
          valueColor: XolmisColors.primary,
          isDark: isDark,
        ),
        _buildMetricTile(
          label: S.current.inventory(widget.inventoryProvider.allInventoriesCount),
          value: '${widget.inventoryProvider.allInventoriesCount}',
          isDark: isDark,
        ),
        _buildMetricTile(
          label: S.current.nest(widget.nestProvider.allNestsCount),
          value: '${widget.nestProvider.allNestsCount}',
          isDark: isDark,
        ),
        _buildMetricTile(
          label: S.current.specimens(widget.specimenProvider.specimensCount).toLowerCase(),
          value: '${widget.specimenProvider.specimensCount}',
          isDark: isDark,
        ),
        _buildMetricTile(
          label: S.current.poisRecorded(totalPoisCount),
          value: '${totalPoisCount}',
          valueColor: XolmisColors.folhaCampo,
          isDark: isDark,
        ),
        _buildMetricTile(
          label: S.current.localitiesSurveyed(allLocalitiesSurveyed),
          value: '${allLocalitiesSurveyed}',
          valueColor: XolmisColors.terraMadeira,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildMetricTile({required String label, required String value, Color? valueColor, required bool isDark}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : XolmisColors.secondaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.grey.shade800 : XolmisColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
              fontSize: Theme.of(context).textTheme.headlineSmall?.fontSize,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(color: isDark ? Colors.grey.shade400 : XolmisColors.secondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTopSpeciesCard(BuildContext context, bool isDark) {
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.emoji_events_outlined, size: 18, color: XolmisColors.primary),
                  const SizedBox(width: 8),
                  Text(S.current.topSpecies(5), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                ],
              ),
              InkWell(
                onTap: () async {
                  // Ação de navegação para a nova tela
                  final allSpeciesRecords = await getTopSpeciesWithMostRecords(0);
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => AllSpeciesRecordsScreen(allSpeciesRecords: allSpeciesRecords)),
                  );
                },
                child: Text(
                  S.current.seeAll,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: XolmisColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
          const SizedBox(height: 8),
          FutureBuilder<List<MapEntry<String, int>>>(
            future: _topSpeciesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator(year2023: false);
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else if (snapshot.hasData) {
                return Column(
                  children:
                      snapshot.data!
                          .map(
                            (entry) => ListTile(
                              dense: true,
                              visualDensity: VisualDensity(horizontal: 0, vertical: -4),
                              title: Text(
                                entry.key,
                                style: TextStyle(
                                  fontFamily: Platform.isIOS ? 'CupertinoSystemDisplay' : null,
                                  fontStyle: FontStyle.italic,
                                  fontSize: 12,
                                ),
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text('${entry.value}', style: TextStyle(fontWeight: FontWeight.bold)),
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
    );
  }

  Widget _buildHourlyChartCard(BuildContext context, bool isDark) {
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
              const Icon(Icons.access_time, size: 18, color: XolmisColors.primary),
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
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 40,
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
                        '', // Main string empty, we use the children
                        const TextStyle(),
                        children: [
                          TextSpan(
                            text: '$value\n',
                            style: const TextStyle(
                              color: XolmisColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          TextSpan(
                            text: '${hour.toString().padLeft(2, '0')} h',
                            style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.normal, fontSize: 12),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                // barTouchData: BarTouchDataOptions(
                //   enabled: true,
                //   touchTooltipData: BarTouchTooltipData(
                //     getTooltipColor: (_) => XolmisColors.jacarandaDeep,
                //     getTooltipItem: (group, groupIndex, rod, rodIndex) {
                //       return BarTooltipItem(
                //         '${groupIndex.toString().padLeft(2, '0')}h: ${rod.toY.round()} reg.',
                //         TextStyle(
                //           color: Colors.white,
                //           fontSize: 11,
                //           fontWeight: FontWeight.w600,
                //         ),
                //       );
                //     },
                //   ),
                // ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (value, meta) {
                        final hour = value.toInt();
                        if (hour % 4 == 0) {
                          return Text(
                            '${hour}h',
                            style: TextStyle(fontSize: 9, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
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
                barGroups: List.generate(
                  24,
                  (index) => BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: recordsPerHour[index]!.toDouble(),
                        color: XolmisColors.primary,
                        width: 10,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyRecordsCard(bool isDark) {
    const monthLabels = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];

    final maxMonthly = recordsByMonth.values.toList().fold(1, (max, v) => v > max ? v : max);

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
                barGroups: _createBarGroupsFromMonthOccurrencesMap(recordsByMonth, 12, XolmisColors.jacarandaCore),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyRichnessCard(bool isDark) {
    const monthLabels = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];

    final maxMonthly = speciesRichnessByMonth.values.toList().fold(1, (max, v) => v > max ? v : max);

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
                S.current.speciesRichnessPerMonth,
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
                barGroups: _createBarGroupsFromMonthOccurrencesMap(
                  speciesRichnessByMonth,
                  12,
                  XolmisColors.jacarandaCore,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYearlyRecordsCard(bool isDark) {
    final years = speciesRichnessByYear.keys.toList();
    final values = speciesRichnessByYear.values.toList();
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
                barTouchData: BarTouchData(enabled: true,
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
                      reservedSize: 22,
                      getTitlesWidget: (value, meta) {
                        final sortedYears = speciesRichnessByYear.keys.toList()..sort();
                        final index = value.toInt();
                        if (index >= 0 && index < sortedYears.length) {
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(
                              sortedYears[index].toString(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                              ),
                            ),
                          );
                        } else {
                          return SideTitleWidget(meta: meta, child: Text(''));
                        }
                      },
                      // getTitlesWidget: (value, meta) {
                      //   final idx = value.toInt();
                      //   if (idx >= 0 && idx < years.length) {
                      //     return Text(
                      //       years[idx],
                      //       style: TextStyle(
                      //         fontSize: 10,
                      //         fontWeight: FontWeight.w500,
                      //         color: isDark
                      //             ? Colors.grey.shade400
                      //             : Colors.grey.shade600,
                      //       ),
                      //     );
                      //   }
                      //   return const SizedBox.shrink();
                      // },
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
                barGroups: _createBarGroupsFromYearOccurrencesMap(speciesRichnessByYear, 20, XolmisColors.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatSubBox(String title, String value, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : XolmisColors.surfaceVariant.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.grey.shade800 : XolmisColors.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: XolmisColors.primary),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryStatsCard(BuildContext context, bool isDark) {
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
              _buildStatSubBox(S.current.surveyHours, '${totalInventoryHours.toStringAsFixed(2)}', isDark),
              _buildStatSubBox(S.current.averageSurveyHours, '${averageInventoryHours.toStringAsFixed(2)}', isDark),
              _buildStatSubBox(S.current.daysSurveyed(totalInventoryDays), '${totalInventoryDays}', isDark),
              _buildStatSubBox(
                S.current.localitiesSurveyed(inventoryLocalitiesCount),
                '${inventoryLocalitiesCount}',
                isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Widget _buildLegendItem(String label, Color color, bool isDark) {
  //   return Row(
  //     children: [
  //       Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
  //       const SizedBox(width: 6),
  //       Text(
  //         label,
  //         style: TextStyle(
  //           fontSize: 11,
  //           fontWeight: FontWeight.w500,
  //           color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
  //         ),
  //       ),
  //     ],
  //   );
  // }

  Widget _buildNestStatsCard(BuildContext context, bool isDark) {
    final apparentSuccessRate =
        widget.nestProvider.inactiveNestsCount == 0
            ? '—'
            : '${(widget.nestProvider.successNestsCount / widget.nestProvider.inactiveNestsCount * 100).toStringAsFixed(1)}%';
    final nidoparasitismRate =
        widget.nestProvider.allNestsCount == 0
            ? '—'
            : '${(totalNestsWithNidoparasitism / widget.nestProvider.allNestsCount * 100).toStringAsFixed(1)}%';

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
                        apparentSuccessRate,
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
                    color: XolmisColors.warningContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: XolmisColors.warning.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nidoparasitismRate,
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
            child: Row(
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
                // Column(
                //   mainAxisAlignment: MainAxisAlignment.center,
                //   crossAxisAlignment: CrossAxisAlignment.start,
                //   children: [
                //     _buildLegendItem(S.current.nestFateSuccess, XolmisColors.success, isDark),
                //     const SizedBox(height: 6),
                //     _buildLegendItem(S.current.nestFateLost, XolmisColors.error, isDark),
                //     const SizedBox(height: 6),
                //     _buildLegendItem(
                //         S.current.nestFateUnknown, Colors.grey, isDark),
                //   ],
                // ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecimenStatsCard(BuildContext context, bool isDark) {
    final colorsList = [
      XolmisColors.primary,
      XolmisColors.jacarandaCore,
      const Color(0xFF14B8A6),
      XolmisColors.warning,
      XolmisColors.secondary,
    ];

    int colorIndex = 0;

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
              const Icon(Icons.local_offer_outlined, size: 18, color: XolmisColors.primary),
              const SizedBox(width: 8),
              Text(
                S.current.specimensByType,
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
            child: Row(
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
                              _touchedIndexSpecimenType = -1; // Nenhuma seção está sendo tocada
                              return;
                            }
                            // Atualiza o estado com o índice da seção tocada
                            _touchedIndexSpecimenType = pieTouchResponse.touchedSection!.touchedSectionIndex;
                          });
                        },
                      ),
                      sectionsSpace: 2,
                      centerSpaceRadius: 35,
                      sections:
                          specimenTypeSections.asMap().entries.map((entry) {
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
                              title:
                                  isTouched
                                      ? getSpecimenTypeFriendlyName(
                                        getSpecimenTypeFromColor(color),
                                        context,
                                      ) // Função para obter o nome amigável
                                      : sectionData.value.toInt().toString(),
                            );
                          }).toList(),
                    ),
                  ),
                ),
                // Column(
                //   mainAxisAlignment: MainAxisAlignment.center,
                //   crossAxisAlignment: CrossAxisAlignment.start,
                //   children: specimenTypeSections.asMap().keys.map((entry) {
                //     final idx = entry;
                //     final color = colorsList[idx % colorsList.length];
                //     return Padding(
                //       padding: const EdgeInsets.only(bottom: 5.0),
                //       child: _buildLegendItem(getSpecimenTypeFriendlyName(getSpecimenTypeFromColor(color), context), color, isDark),
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

  List<BarChartGroupData> createBarGroupsFromOccurrencesMap(Map<int, int> monthlyOccurrences, double barWidth) {
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
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(6), topRight: Radius.circular(6)),
            ),
          ],
        ),
      );
    });
    return barGroups;
  }
}
