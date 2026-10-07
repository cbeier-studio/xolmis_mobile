import 'package:fl_chart/fl_chart.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/core_consts.dart';
import '../../data/models/specimen.dart';
import '../../generated/l10n.dart';
import '../../providers/specimen_provider.dart';
import '../../utils/statistics_logic.dart';
import '../../utils/themes.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text(S.current.statistics)),
      body: SafeArea(
        child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildKpiMetricsGrid(isDark),
                const SizedBox(height: 16),

                _buildSpecimenStatsCard(context, isDark),
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
          label: S.current.selectedSpecimens(2),
          value: '${widget.specimens.length}',
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
                      specimenTypeCounts.asMap().entries.map((entry) {
                        final index = entry.key;
                        final sectionData = entry.value;
                        final isTouched = index == _touchedIndexSpecimenType;
                        final typeLabel = specimenTypeFriendlyNames[sectionData.key] ?? S.current.specimenType;

                        // Aumenta o raio e o tamanho da fonte se a seção estiver sendo tocada
                        final double radius = isTouched ? 50.0 : 40.0;
                        final double fontSize = isTouched ? 18.0 : 14.0;
                        final color = getSpecimenColor(typeLabel);

                        // Cria uma nova PieChartSectionData com os estilos atualizados
                        return PieChartSectionData(
                          color: color,
                          value: sectionData.value.toDouble(),
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
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${widget.specimens.length}',
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
}