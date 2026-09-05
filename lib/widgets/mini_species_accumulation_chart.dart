import 'package:fl_chart/fl_chart.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import '../../data/models/inventory.dart';
import '../../providers/species_provider.dart';
import '../../utils/chart_utils.dart';
import '../screens/statistics/species_chart_screen.dart';
import '../../generated/l10n.dart';

/// A small line chart that displays the species accumulation curve.
///
/// It updates in real-time when the inventory is active and when species are added.
/// Tapping the chart opens the full [SpeciesChartScreen].
class MiniSpeciesAccumulationChart extends StatelessWidget {
  final Inventory inventory;

  const MiniSpeciesAccumulationChart({super.key, required this.inventory});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: S.of(context).speciesAccumulationCurve,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SpeciesChartScreen(inventory: inventory),
            ),
          );
        },
        borderRadius: BorderRadius.circular(4),
        child: Container(
          width: 36,
          height: 36,
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
          child: Consumer<SpeciesProvider>(
            builder: (context, speciesProvider, child) {
              return ValueListenableBuilder<double>(
                valueListenable: inventory.elapsedTimeNotifier,
                builder: (context, elapsedTime, child) {
                  final speciesList = speciesProvider.getSpeciesForInventory(inventory.id);
                  final chartDataMap = prepareSpeciesAccumulationData(inventory, speciesList);
                  final data = chartDataMap['data'] as List<SpeciesAccumulationData>;

                  if (data.isEmpty) {
                    return Center(
                      child: Icon(
                        Icons.show_chart_outlined,
                        size: 20,
                        color: Theme.of(context).disabledColor,
                      ),
                    );
                  }

                  final spots = data
                      .map((d) => FlSpot(d.interval.toDouble(), d.speciesCount.toDouble()))
                      .toList();

                  final maxX = spots.last.x;
                  final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);

                  return IgnorePointer(
                    child: LineChart(
                      LineChartData(
                        minX: 0,
                        maxX: maxX,
                        minY: 0,
                        maxY: maxY == 0 ? 1 : maxY,
                        titlesData: const FlTitlesData(show: false),
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey.withAlpha(100))),
                        lineTouchData: const LineTouchData(enabled: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: spots,
                            isCurved: false,
                            barWidth: 1,
                            color: Theme.of(context).brightness == Brightness.light
                                ? Colors.deepPurple
                                : Colors.deepPurple[200],
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(context).brightness == Brightness.light
                                    ? Colors.deepPurpleAccent.withAlpha(80)
                                    : Colors.deepPurpleAccent.shade100.withAlpha(120),
                                  Colors.transparent,
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              )
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
