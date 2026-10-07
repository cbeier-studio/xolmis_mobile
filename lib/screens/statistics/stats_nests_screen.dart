import 'package:fl_chart/fl_chart.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/core_consts.dart';
import '../../data/models/nest.dart';
import '../../generated/l10n.dart';
import '../../providers/nest_provider.dart';
import '../../providers/egg_provider.dart';
import '../../utils/statistics_logic.dart';
import '../../utils/themes.dart';

/// Statistics screen focused on the selected nests.
class StatsNestsScreen extends StatefulWidget {
  final List<Nest> nests;

  const StatsNestsScreen({super.key, required this.nests});

  @override
  StatsNestsScreenState createState() => StatsNestsScreenState();
}

/// Computes nest metrics and renders distribution charts.
class StatsNestsScreenState extends State<StatsNestsScreen> {
  late NestProvider nestProvider;
  late EggProvider eggProvider;
  late List<String> combinedSpeciesList = [];
  late int distinctLocalitiesCount = 0;
  late int distinctObserversCount = 0;
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

  /// Loads nest-derived values used by cards and charts.
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

    final allObservers = widget.nests.map((nest) => nest.observer).toList();
    final distinctObservers = allObservers.toSet();
    distinctObserversCount = distinctObservers.length;

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
          );
        }).toList();
  }

  /// Returns sorted distinct species names present in the nest list.
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text(S.current.statistics)),
      body: SafeArea(
        child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildKpiMetricsGrid(isDark),
                const SizedBox(height: 16),

                _buildNestMetricsCard(isDark),
                const SizedBox(height: 24),
              ],
            ),
        ),
      ),
    );
  }

  Widget _buildKpiMetricsGrid(bool isDark) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.1,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildKpiTile(
          label: S.current.selectedNests(2),
          value: '${widget.nests.length}',
          // subtext: '',
          valueColor: XolmisColors.primary,
          isDark: isDark,
        ),
        _buildKpiTile(
          label: S.current.localitiesSurveyed(distinctLocalitiesCount),
          value: '${distinctLocalitiesCount}',
          // subtext: '',
          valueColor: XolmisColors.primary,
          isDark: isDark,
        ),
        _buildKpiTile(
          label: S.current.totalRichness,
          value: '${combinedSpeciesList.length}',
          // subtext: '',
          valueColor: XolmisColors.primary,
          isDark: isDark,
        ),
        _buildKpiTile(
          label: S.current.observers(distinctObserversCount),
          value: '${distinctObserversCount}',
          // subtext: '',
          valueColor: XolmisColors.primary,
          isDark: isDark,
        ),
        Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: XolmisColors.successContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: XolmisColors.success.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${totalSuccessNests}%',
                      style: TextStyle(fontSize: Theme.of(context).textTheme.headlineSmall?.fontSize, fontWeight: FontWeight.bold, color: XolmisColors.success),
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
            Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: XolmisColors.warningContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: XolmisColors.warning.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${totalNestsWithNidoparasitism}%',
                      style: TextStyle(fontSize: Theme.of(context).textTheme.headlineSmall?.fontSize, fontWeight: FontWeight.bold, color: XolmisColors.warning),
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
      ],
    );
  }

  Widget _buildKpiTile({
    required String label,
    required String value,
    // required String subtext,
    required Color valueColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.grey.shade900.withValues(alpha: 0.6)
            : XolmisColors.secondaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : XolmisColors.borderSubtle,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: Theme.of(context).textTheme.headlineSmall?.fontSize,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey.shade400 : XolmisColors.secondary,
            ),
          ),
          // Row(
          //   textBaseline: TextBaseline.alphabetic,
          //   crossAxisAlignment: CrossAxisAlignment.baseline,
          //   children: [
          //
          //     const SizedBox(width: 6),
          //     Expanded(
          //       child: Text(
          //         subtext,
          //         style: TextStyle(
          //           fontSize: 10,
          //           color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          //         ),
          //         overflow: TextOverflow.ellipsis,
          //       ),
          //     ),
          //   ],
          // ),
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
                S.current.nestFate,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
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
}