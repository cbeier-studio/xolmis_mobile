import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/core_consts.dart';
import '../../data/models/nest.dart';
import '../../generated/l10n.dart';
import '../../providers/nest_provider.dart';
import '../../providers/egg_provider.dart';
import '../../utils/statistics_logic.dart';

class StatsNestsScreen extends StatefulWidget {
  final List<Nest> nests;

  const StatsNestsScreen({super.key, required this.nests});

  @override
  StatsNestsScreenState createState() => StatsNestsScreenState();
}

class StatsNestsScreenState extends State<StatsNestsScreen> {
  late NestProvider nestProvider;
  late EggProvider eggProvider;
  late List<String> combinedSpeciesList = [];
  late int distinctLocalitiesCount = 0;
  int totalSuccessNests = 0;
  int totalNestsWithNidoparasitism = 0;
  List<PieChartSectionData> nestFateSections = [];
  int _touchedIndexNestFate = -1;

  @override
  void initState() {
    super.initState();
    nestProvider = Provider.of<NestProvider>(context, listen: false);
    eggProvider = Provider.of<EggProvider>(context, listen: false);
    _loadData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadData() async {
    combinedSpeciesList = _getSpeciesList(widget.nests);
    totalSuccessNests = widget.nests.where((nest) => nest.nestFate == NestFateType.fatSuccess).length;
    totalNestsWithNidoparasitism = widget.nests.where((nest) {
      // Para cada ninho, verifique se *alguma* de suas revisões tem parasitismo.
      return nest.revisionsList!.any((revision) =>
      (revision.eggsParasite ?? 0) > 0 || (revision.nestlingsParasite ?? 0) > 0
      );
    }).length;

    final allLocalities = widget.nests.map((nest) => nest.localityName).toList();
    final distinctLocalities = allLocalities.toSet();
    distinctLocalitiesCount = distinctLocalities.length;

    nestFateSections =
        getNestFateCounts(
          widget.nests,
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

  List<String> _getSpeciesList(List<Nest> nests) {
    final speciesSet = <String>{};
    for (final nest in nests) {
      speciesSet.add(nest.speciesName!);
    }
    return speciesSet.toList()..sort();
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
                              widget.nests.length.toString(),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: Theme.of(context).textTheme.headlineSmall?.fontWeight,
                                fontSize: Theme.of(context).textTheme.headlineSmall?.fontSize,
                              ),
                            ),
                            Text(S.current.selectedNests(widget.nests.length)),
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
                        child: 
                          const SizedBox(width: 8,)
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
                                  (totalSuccessNests / nestProvider.inactiveNestsCount * 100).toStringAsFixed(1),
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
                                  (totalNestsWithNidoparasitism / nestProvider.allNestsCount * 100).toStringAsFixed(1),
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
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Text(
                              S.current.nestFate,
                              style: TextTheme.of(context).titleMedium,
                            ),
                            widget.nests.isNotEmpty ? Stack(
                              alignment: Alignment.center,
                              children: [
                                Text(
                                  widget.nests.length.toString(),
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