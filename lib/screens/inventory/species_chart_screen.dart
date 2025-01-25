import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:xolmis/generated/l10n.dart';

import '../../data/models/inventory.dart';

class SpeciesChartScreen extends StatelessWidget {
  final Inventory inventory;

  const SpeciesChartScreen({super.key, required this.inventory});

  @override
  Widget build(BuildContext context) {
    // Prepare the data for the species accumulation curve
    final speciesAccumulationData = _prepareSpeciesAccumulationData(inventory);
    List<FlSpot> trendLineSpots = [];

    // Set the chart bounds
    final minX = 0.0;
    final maxX = speciesAccumulationData.isNotEmpty
        ? speciesAccumulationData.map((data) => data.interval.toDouble()).reduce((a, b) => a > b ? a : b)
        : 0.0;
    final maxY = speciesAccumulationData.isNotEmpty
        ? speciesAccumulationData.map((data) => data.speciesCount.toDouble()).reduce((a, b) => a > b ? a : b)
        : 0.0;

    // Prepare the data for the trend line using polyfit
    if (speciesAccumulationData.isNotEmpty) {
      final x = speciesAccumulationData.map((data) => data.interval.toDouble()).toList();
      final y = speciesAccumulationData.map((data) => data.speciesCount.toDouble()).toList();
      final polyCoefficients = _polyfit(x, y, 2); // Fit a 2nd degree polynomial

      for (var i = minX; i <= maxX; i++) {
        final yValue = _polyval(polyCoefficients, i);
        trendLineSpots.add(FlSpot(i, yValue));
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).speciesAccumulationCurve),        
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: speciesAccumulationData.isEmpty
          // Show a message if there is no data
            ? Center(child: Text(S.current.noDataAvailable))
            : LineChart(          
          LineChartData(
            minX: minX,
            maxX: maxX,
            maxY: maxY,
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                axisNameWidget: Text(S.current.timeMinutes),
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final minutes = value.toInt();
                    return Text('$minutes');
                  },
                ),
              ),
              leftTitles: AxisTitles(
                axisNameWidget: Text(S.current.speciesAccumulated),
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    return Text(value.toInt().toString());
                  },
                ),
              ),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: FlGridData(show: false, horizontalInterval: 1, verticalInterval: 1),
            borderData: FlBorderData(
              show: true,
              border: Border.all(color: Colors.grey, width: 1),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: speciesAccumulationData
                    .map((data) => FlSpot(data.interval.toDouble(), data.speciesCount.toDouble()))
                    .toList(),
                isCurved: false,
                barWidth: 2,
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.deepPurple
                    : Colors.deepPurple[200],
                belowBarData: BarAreaData(show: true),
              ),
              LineChartBarData(
                show: false,
                    spots: trendLineSpots,
                    isCurved: false,
                    color: Colors.red,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  // Prepare the data for the species accumulation curve
  List<SpeciesAccumulationData> _prepareSpeciesAccumulationData(Inventory inventory) {
    final speciesAccumulationData = <SpeciesAccumulationData>[];
    final speciesByInterval = <int, Set<String>>{};

    // Calculate the total elapsed minutes and the total intervals
    final startTime = inventory.startTime!;
    final currentTime = inventory.isFinished ? inventory.endTime! : DateTime.now();
    final totalElapsedMinutes = currentTime.difference(startTime).inMinutes;
    final totalIntervals = (totalElapsedMinutes / 5).ceil();

    for (final species in inventory.speciesList) {
      final sampleTime = species.sampleTime;

      // Skip species without sample time
      if (sampleTime == null) {
        continue;
      }

      // Calculate the interval for the species
      final elapsedMinutes = sampleTime.difference(startTime).inMinutes;
      final interval = elapsedMinutes ~/ 5; // Intervalo de 5 minutos

      if (!speciesByInterval.containsKey(interval)) {
        speciesByInterval[interval] = <String>{};
      }

      // Add the species to the interval
      speciesByInterval[interval]!.add(species.name);
    }

    int cumulativeSpeciesCount = 0;
    final seenSpecies = <String>{};

    // Calculate the cumulative species count for each interval
    for (int i = 0; i <= totalIntervals; i++) {
      if (speciesByInterval.containsKey(i)) {
        for (final species in speciesByInterval[i]!) {
          if (!seenSpecies.contains(species)) {
            seenSpecies.add(species);
            cumulativeSpeciesCount++;
          }
        }
      }
      speciesAccumulationData.add(SpeciesAccumulationData(i * 5, cumulativeSpeciesCount));
    }

    return speciesAccumulationData;
  }

  List<double> _polyfit(List<double> x, List<double> y, int degree) {
    final n = x.length;
    final X = List.generate(n, (i) => List.generate(degree + 1, (j) => pow(x[i], j).toDouble()));
    final XT = _transpose(X);
    final XTX = _multiplyMatrices(XT, X);
    final XTY = _multiplyMatrixVector(XT, y);
    final coefficients = _solve(XTX, XTY);
    return coefficients;
  }

  double _polyval(List<double> coefficients, double x) {
    return coefficients.asMap().entries.fold(0.0, (sum, entry) => sum + entry.value * pow(x, entry.key));
  }

  List<List<double>> _transpose(List<List<double>> matrix) {
    final rows = matrix.length;
    final cols = matrix[0].length;
    final transposed = List.generate(cols, (i) => List.generate(rows, (j) => matrix[j][i]));
    return transposed;
  }

  List<List<double>> _multiplyMatrices(List<List<double>> A, List<List<double>> B) {
    final rowsA = A.length;
    final colsA = A[0].length;
    final colsB = B[0].length;
    final result = List.generate(rowsA, (i) => List.generate(colsB, (j) => 0.0));
    for (var i = 0; i < rowsA; i++) {
      for (var j = 0; j < colsB; j++) {
        for (var k = 0; k < colsA; k++) {
          result[i][j] += A[i][k] * B[k][j];
        }
      }
    }
    return result;
  }

  List<double> _multiplyMatrixVector(List<List<double>> matrix, List<double> vector) {
    final rows = matrix.length;
    final cols = matrix[0].length;
    final result = List.generate(rows, (i) => 0.0);
    for (var i = 0; i < rows; i++) {
      for (var j = 0; j < cols; j++) {
        result[i] += matrix[i][j] * vector[j];
      }
    }
    return result;
  }

  List<double> _solve(List<List<double>> A, List<double> b) {
    final n = A.length;
    final x = List.generate(n, (i) => 0.0);
    for (var i = 0; i < n; i++) {
      var maxEl = A[i][i];
      var maxRow = i;
      for (var k = i + 1; k < n; k++) {
        if (A[k][i] > maxEl) {
          maxEl = A[k][i];
          maxRow = k;
        }
      }
      for (var k = i; k < n; k++) {
        final tmp = A[maxRow][k];
        A[maxRow][k] = A[i][k];
        A[i][k] = tmp;
      }
      final tmp = b[maxRow];
      b[maxRow] = b[i];
      b[i] = tmp;
      for (var k = i + 1; k < n; k++) {
        final c = -A[k][i] / A[i][i];
        for (var j = i; j < n; j++) {
          if (i == j) {
            A[k][j] = 0;
          } else {
            A[k][j] += c * A[i][j];
          }
        }
        b[k] += c * b[i];
      }
    }
    for (var i = n - 1; i >= 0; i--) {
      x[i] = b[i] / A[i][i];
      for (var k = i - 1; k >= 0; k--) {
        b[k] -= A[k][i] * x[i];
      }
    }
    return x;
  }
}

// Data class for the species accumulation curve
class SpeciesAccumulationData {
  final int interval;
  final int speciesCount;

  SpeciesAccumulationData(this.interval, this.speciesCount);
}
