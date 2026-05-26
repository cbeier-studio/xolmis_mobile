import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/core_consts.dart';
import '../../data/models/specimen.dart';
import '../../generated/l10n.dart';
import '../../providers/specimen_provider.dart';
import '../../utils/statistics_logic.dart';

/// Statistics screen for the selected specimen records.
class StatsSpecimensScreen extends StatefulWidget {
  final List<Specimen> specimens;

  const StatsSpecimensScreen({super.key, required this.specimens});

  @override
  StatsSpecimensScreenState createState() => StatsSpecimensScreenState();
}

/// Computes specimen metrics and renders type distribution charts.
class StatsSpecimensScreenState extends State<StatsSpecimensScreen> {
  late SpecimenProvider specimenProvider;
  late List<String> combinedSpeciesList = [];
  late int distinctLocalitiesCount = 0;
  late int distinctObserversCount = 0;
  List<MapEntry<SpecimenType, int>> specimenTypeCounts = [];
  int _touchedIndexSpecimenType = -1;

  @override
  void initState() {
    super.initState();
    specimenProvider = Provider.of<SpecimenProvider>(context, listen: false);
    _loadData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// Loads distinct counts and grouped values used by the UI.
  Future<void> _loadData() async {
    final speciesList = _getSpeciesList(widget.specimens);

    final distinctLocalities = widget.specimens
        .map((specimen) => specimen.locality?.trim() ?? '')
        .where((locality) => locality.isNotEmpty)
        .toSet();

    final distinctObservers = widget.specimens
        .map((specimen) => specimen.observer?.trim() ?? '')
        .where((observer) => observer.isNotEmpty)
        .toSet();

    final counts = getSpecimenTypeCountsFromList(widget.specimens).entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (!mounted) return;
    setState(() {
      combinedSpeciesList = speciesList;
      distinctLocalitiesCount = distinctLocalities.length;
      distinctObserversCount = distinctObservers.length;
      specimenTypeCounts = counts;
    });
  }

  /// Returns sorted distinct species names in the specimen list.
  List<String> _getSpeciesList(List<Specimen> specimens) {
    final speciesSet = <String>{};
    for (final specimen in specimens) {
      final speciesName = specimen.speciesName?.trim() ?? '';
      if (speciesName.isNotEmpty) {
        speciesSet.add(speciesName);
      }
    }
    return speciesSet.toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.current.statistics)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // Number of selected nests
                    Expanded(child:
                    Card(
                      surfaceTintColor: Colors.deepPurple,
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.specimens.length.toString(),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: Theme.of(context).textTheme.headlineSmall?.fontWeight,
                                fontSize: Theme.of(context).textTheme.headlineSmall?.fontSize,
                              ),
                            ),
                            Text(S.current.selectedSpecimens(widget.specimens.length)),
                          ],
                        ),
                      ),
                    ),
                    ),
                    // Localities surveyed
                    Expanded(child:
                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              distinctLocalitiesCount.toString(),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: Theme.of(context).textTheme.headlineSmall?.fontWeight,
                                fontSize: Theme.of(context).textTheme.headlineSmall?.fontSize,
                              ),
                            ),
                            Text(S.current.localitiesSurveyed(distinctLocalitiesCount)),
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
                    // Total species richness
                    Expanded(child:
                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              combinedSpeciesList.length.toString(),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: Theme.of(context).textTheme.headlineSmall?.fontWeight,
                                fontSize: Theme.of(context).textTheme.headlineSmall?.fontSize,
                              ),
                            ),
                            Text(S.current.totalRichness),
                          ],
                        ),
                      ),
                    ),
                    ),
                    // Average species richness
                    Expanded(child:
                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              distinctObserversCount.toString(),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: Theme.of(context).textTheme.headlineSmall?.fontWeight,
                                fontSize: Theme.of(context).textTheme.headlineSmall?.fontSize,
                              ),
                            ),
                            Text(S.current.observers(distinctObserversCount)),
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
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Text(
                                S.current.specimensByType,
                                style: TextTheme.of(context).titleMedium,
                              ),
                              widget.specimens.isNotEmpty ? Stack(
                                alignment: Alignment.center,
                                children: [
                                  Text(
                                    widget.specimens.length.toString(),
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
                                        sections: specimenTypeCounts.asMap().entries.map((entry) {
                                          final index = entry.key;
                                          final specimenType = entry.value.key;
                                          final count = entry.value.value;
                                          final isTouched = index == _touchedIndexSpecimenType;
                                          final typeLabel = specimenTypeFriendlyNames[specimenType] ?? S.current.specimenType;
                                          final color = getSpecimenColor(typeLabel);

                                          final double radius = isTouched ? 50.0 : 40.0;
                                          final double fontSize = isTouched ? 18.0 : 14.0;

                                          return PieChartSectionData(
                                            color: color,
                                            value: count.toDouble(),
                                            radius: radius,
                                            titleStyle: TextStyle(
                                              fontSize: fontSize,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              shadows: const [Shadow(color: Colors.black, blurRadius: 10)],
                                            ),
                                            title: isTouched ? typeLabel : count.toString(),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ),
                                ],
                              ) : Text(S.current.noDataAvailable),
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
        ),
      ),
    );
  }
}