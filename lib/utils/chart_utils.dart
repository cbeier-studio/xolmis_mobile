import '../data/models/inventory.dart';

/// Immutable point used by the accumulation curve.
class SpeciesAccumulationData {
  final int interval;
  final int speciesCount;

  SpeciesAccumulationData(this.interval, this.speciesCount);
}

/// Prepares species richness data aggregated by intervals for charts.
///
/// Returns a list of [SpeciesAccumulationData] points where the interval
/// values are in seconds. The [intervalSize] output parameter indicates the
/// calculated step size (10s, 60s, or 600s) based on the total duration.
/// The [inventoryDurationSeconds] output parameter indicates the wall-clock
/// duration of the inventory.
Map<String, dynamic> prepareSpeciesAccumulationData(Inventory inventory, List<Species> speciesList) {
  final speciesAccumulationData = <SpeciesAccumulationData>[];
  final speciesByInterval = <int, Set<String>>{};

  // Work entirely in seconds for uniform precision across all interval sizes.
  final startTime = inventory.startTime;
  if (startTime == null) return {'data': [], 'intervalSize': 60, 'duration': 0.0};

  final endTime = inventory.isFinished ? inventory.endTime! : DateTime.now();
  final wallClockDuration = endTime.difference(startTime).inSeconds;

  // Find the latest species registration time among all registered species
  int maxSpeciesElapsed = 0;
  for (final species in speciesList) {
    if (species.sampleTime != null) {
      final elapsed = species.sampleTime!.difference(startTime).inSeconds;
      if (elapsed > maxSpeciesElapsed) {
        maxSpeciesElapsed = elapsed;
      }
    }
  }

  // The chart should extend to cover the latest species OR the inventory wall-clock duration.
  // This ensures species registered after the timer/finish are visible.
  final totalElapsedSeconds = maxSpeciesElapsed > wallClockDuration ? maxSpeciesElapsed : wallClockDuration;

  // Use the wallClockDuration as the marker for the inventory's end.
  final inventoryDurationSeconds = wallClockDuration.toDouble();
  final totalElapsedMinutes = totalElapsedSeconds ~/ 60;

  // Choose interval size in seconds:
  //   < 5 min  → 10 s
  //   < 60 min → 60 s (1 min)
  //   >= 60 min → 600 s (10 min)
  int intervalSize;
  if (totalElapsedMinutes < 5) {
    intervalSize = 10;
  } else if (totalElapsedMinutes < 60) {
    intervalSize = 60;
  } else {
    intervalSize = 600;
  }

  final totalIntervals = (totalElapsedSeconds / intervalSize).ceil();

  for (final species in speciesList) {
    final sampleTime = species.sampleTime;

    // Skip species without sample time
    if (sampleTime == null) {
      continue;
    }

    // Calculate the interval index for the species
    final elapsedSeconds = sampleTime.difference(startTime).inSeconds;
    final interval = elapsedSeconds ~/ intervalSize;

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
    // X value stored in seconds
    speciesAccumulationData.add(SpeciesAccumulationData(i * intervalSize, cumulativeSpeciesCount));
  }

  return {
    'data': speciesAccumulationData,
    'intervalSize': intervalSize,
    'duration': inventoryDurationSeconds,
  };
}
