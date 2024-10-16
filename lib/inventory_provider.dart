import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:io';
import 'database_helper.dart';
import 'inventory.dart';
import 'dart:async';

// Class to manage the state of inventories
class InventoryProvider extends ChangeNotifier {
  List<Inventory> _inventories = [];

  List<Inventory> get inventories => _inventories;

  bool isLoading = false;

  Future<void> loadInventories() async {
    isLoading = true;
    notifyListeners();
    try {
      // Load the inventories from database
      _inventories = await DatabaseHelper().getUnfinishedInventories();
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao carregar inventários: $e');
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void updateInventoryIsPaused(Inventory inventory, bool isPaused, BuildContext context) {
    inventory.isPaused = isPaused;
    if (isPaused) {
      stopTimer();
    } else {
      startTimer();
    }
    updateInventoryElapsedTime(inventory);
    notifyListeners();
  }

  void updateInventoryElapsedTime(Inventory inventory) {
    // Check if the inventory is paused or finished
    if (!inventory.isPaused && !inventory.isFinished && inventory.type == InventoryType.invCumulativeTime) {
      inventory.elapsedTime++;
      if (inventory.elapsedTime >= inventory.duration) {
        inventory.isFinished = true;
        DatabaseHelper().insertInventory(inventory);
      }
      notifyListeners();
    }
  }

  Timer? _timer;

  void startTimer() {
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      for (var inventory in inventories) {
        if (!inventory.isPaused && !inventory.isFinished) {
          updateInventoryElapsedTime(inventory);
        }
      }
    });
  }

  void stopTimer() {
    _timer?.cancel();
  }

  void resetInventoryTimer(Inventory inventory) {
    inventory.elapsedTime = 0; // Restart elapsedTime
    stopTimer(); // Stop the current timer
    startTimer(); // Restart the timer
    notifyListeners();
  }

  Future<bool> addInventory(Inventory inventory) async {
    if (inventory.type == InventoryType.invCumulativeTime && !inventory.isFinished) {
      inventory.duration = 30;
    }

    try {
      LatLng currentLocation = await getCurrentLocation();
      inventory.startLatitude = currentLocation.latitude;
      inventory.startLongitude = currentLocation.longitude;
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao obter a localização: $e');
      }
      // Handle the location error
      return false; // Return false if a location error occur
    }

    try {
      bool success = await DatabaseHelper().insertInventory(inventory);
      if (success) {
        inventories.add(inventory);
        notifyListeners();
        return true;
      } else {
        if (kDebugMode) {
          print('Erro ao inserir inventário no banco de dados');
        }
        // Handle insertion error
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao adicionar inventário: $e');
      }
      // Handle the error, e.g.: show a error message to the user
      return false;
    }
  }

  Inventory getInventoryById(String id) {
    return _inventories.firstWhere((inventory) => inventory.id== id);
  }

  void updateSpecies(Species updatedSpecies) {
    final inventory = _inventories.firstWhere((inventory) => inventory.id == updatedSpecies.inventoryId);
    final speciesIndex = inventory.speciesList.indexWhere((species) => species.id == updatedSpecies.id);

    if (speciesIndex != -1) {
      inventory.speciesList[speciesIndex] = updatedSpecies;
      notifyListeners();
    }
  }

  List<Inventory> _finishedInventories = [];

  List<Inventory> get finishedInventories => _finishedInventories;

  bool isLoadingFinished = false;

  Future<void> loadFinishedInventories() async {
    isLoadingFinished = true;
    notifyListeners();
    try {
      _finishedInventories = await DatabaseHelper().getFinishedInventories();
      if (kDebugMode) {
        print('Inventários finalizados carregados: ${finishedInventories.length}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao carregar inventários finalizados: $e');
      }
    } finally {
      isLoadingFinished = false;
      notifyListeners();
    }
  }

  void removeFinishedInventory(Inventory inventory) {
    finishedInventories.remove(inventory);
    notifyListeners();
  }

  void addSpeciesToInventory(Inventory inventory, String speciesName) {
    Species? existingSpecies = inventory.speciesList.firstWhere(
          (species) => species.name == speciesName,
      orElse: () => Species(inventoryId: '', name: '', isOutOfInventory: false, count: 0),
    );

    if (existingSpecies.name != '') {
      existingSpecies.count++;
    } else {
      inventory.speciesList.add(Species(inventoryId: inventory.id, name: speciesName, isOutOfInventory: inventory.isFinished, count: 1));
    }

    if (inventory.type == InventoryType.invCumulativeTime) {
      resetInventoryTimer(inventory); // Restart the timer if invCumulativeTime
    }

    notifyListeners();
  }

  void removeSpeciesFromInventory(Inventory inventory, String speciesName) {
    inventory.speciesList.removeWhere((species) => species.name == speciesName);
    notifyListeners();
  }

  Future<void> finishInventory(Inventory inventory) async {
    inventory.endTime = DateTime.now();

    try {
      LatLng currentLocation = await getCurrentLocation();
      inventory.endLongitude = currentLocation.longitude;
      inventory.endLatitude = currentLocation.latitude;
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao obter a localização: $e');
      }
      // Handle the location error
    }

    await DatabaseHelper().insertInventory(inventory); // Save the inventory to the database
    notifyListeners();
  }

  Future<void> exportInventory(Inventory inventory) async {
    // 1. Create a list of data for the CSV
    List<List<dynamic>> rows = [];
    rows.add(['ID do Inventário', 'Tipo', 'Duração', 'Pausado', 'Finalizado', 'Tempo Restante', 'Tempo Decorrido']);
    rows.add([inventory.id, inventory.type.toString(), inventory.duration, inventory.isPaused, inventory.isFinished, inventory.remainingTime, inventory.elapsedTime]);
    rows.add([]); // Empty line to separate the inventory of the species
    rows.add(['Espécie', 'Contagem']);
    for (var species in inventory.speciesList) {
      rows.add([species.name, species.count]);
    }

    // 2. Convert the list of data to CSV
    String csv = const ListToCsvConverter().convert(rows);

    // 3. Get the documents folder of the device
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/inventory_${inventory.id}.csv';

    // 4. Create the file and save the data
    final file = File(path);
    await file.writeAsString(csv);

    // 5. (Optional) Show a success message
    // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Inventário exportado para: $path')));
  }

  Future<LatLng> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if the location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // The location services are not enabled. Ask the user to enable them.
      return Future.error('Os serviços de localização estão desabilitados.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // The permissions were permanently negated, we can not ask for permissions.
        return Future.error(
            'As permissões de localização foram negadas permanentemente.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // The permissions were permanently negated, we can not ask for permissions.
      return Future.error(
          'As permissões de localização foram negadas permanentemente.');
    }

    // When we arrive here, the permissions were given and the location services are enabled.
    Position position = await Geolocator.getCurrentPosition();
    return LatLng(position.latitude, position.longitude);
  }

  Future<void> addVegetation(Vegetation vegetation) async {
    _vegetationList.add(vegetation);
    DatabaseHelper().insertVegetation(vegetation);
    notifyListeners();
  }

  final List<Vegetation>_vegetationList = [];

  List<Vegetation> getVegetationByInventoryId(String inventoryId) {
    return _vegetationList.where((vegetation) => vegetation.inventoryId == inventoryId).toList();
  }

  void removeVegetation(Vegetation vegetation) {
    _vegetationList.remove(vegetation);
    DatabaseHelper().deleteVegetation(vegetation.id);
    notifyListeners();
  }

}