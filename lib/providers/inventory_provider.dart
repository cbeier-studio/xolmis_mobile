import 'package:flutter/material.dart';

import '../data/models/inventory.dart';
import '../data/daos/inventory_dao.dart';

import 'species_provider.dart';
import 'vegetation_provider.dart';
import 'weather_provider.dart';

class InventoryProvider with ChangeNotifier {
  final InventoryDao _inventoryDao;
  final List<Inventory> _inventories = [];
  final Map<String, Inventory> _inventoryMap = {};
  final ValueNotifier<int> speciesCountNotifier = ValueNotifier<int>(0);
  final ValueNotifier<bool> inventoryFinishedNotifier = ValueNotifier<bool>(false);
  // Flag to indicate that data is loading
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Get list of active inventories
  List<Inventory> get activeInventories =>
      _inventories.where((inventory) => !inventory.isFinished).toList();

  // Get list of finished inventories
  List<Inventory> get finishedInventories =>
      _inventories.where((inventory) => inventory.isFinished).toList();

  // Get the number of active inventories
  int get inventoriesCount => activeInventories.length;
  int get allInventoriesCount => _inventories.length;

  final SpeciesProvider _speciesProvider;
  final VegetationProvider _vegetationProvider;
  final WeatherProvider _weatherProvider;
  SpeciesProvider get speciesProvider => _speciesProvider;
  VegetationProvider get vegetationProvider => _vegetationProvider;
  WeatherProvider get weatherProvider => _weatherProvider;

  InventoryProvider(this._inventoryDao, this._speciesProvider, this._vegetationProvider, this._weatherProvider);

  void refreshState() {
    notifyListeners();
  }

  // Load all inventories from the database
  Future<void> fetchInventories(BuildContext context) async {
    debugPrint('[PROVIDER] ----------------------------------');
    debugPrint('[PROVIDER] Fetching all inventories...');
    _isLoading = true;
    try {final inventoriesFromDb = await _inventoryDao.getInventories();
    final Set<String> dbInventoryIds = inventoriesFromDb.map((inv) => inv.id).toSet();

    // Remove from memory the inventories that does not exist in DB anymore
    _inventoryMap.removeWhere((id, inventory) => !dbInventoryIds.contains(id));
    _inventories.removeWhere((inventory) => !dbInventoryIds.contains(inventory.id));

    // Update existing or add new inventories
    for (var dbInventory in inventoriesFromDb) {
      if (_inventoryMap.containsKey(dbInventory.id)) {
        // Object already exists in memory: UPDATE IT, do not replace it.
        final memoryInventory = _inventoryMap[dbInventory.id]!;
        memoryInventory.currentInterval = dbInventory.currentInterval;
        memoryInventory.elapsedTime = dbInventory.elapsedTime;
        memoryInventory.isFinished = dbInventory.isFinished;
        memoryInventory.isPaused = dbInventory.isPaused;
        memoryInventory.startTime = dbInventory.startTime;
        memoryInventory.endTime = dbInventory.endTime;
        memoryInventory.duration = dbInventory.duration;
        memoryInventory.localityName = dbInventory.localityName;
        memoryInventory.speciesCount = dbInventory.speciesCount;
        memoryInventory.speciesWithinCount = dbInventory.speciesWithinCount;
        memoryInventory.speciesOutOfInventoryCount = dbInventory.speciesOutOfInventoryCount;
        memoryInventory.currentIntervalSpeciesCount = dbInventory.currentIntervalSpeciesCount;
        memoryInventory.totalPausedTimeInSeconds = dbInventory.totalPausedTimeInSeconds;
        memoryInventory.pauseStartTime = dbInventory.pauseStartTime;
        memoryInventory.intervalsWithoutNewSpecies = dbInventory.intervalsWithoutNewSpecies;
        memoryInventory.isDiscarded = dbInventory.isDiscarded;
      } else {
        // Object does not exist in memory: ADD IT.
        _inventories.add(dbInventory);
        _inventoryMap[dbInventory.id] = dbInventory;
      }
      // Load subitems if necessary
      await _speciesProvider.loadSpeciesForInventory(dbInventory.id);
      await _vegetationProvider.loadVegetationForInventory(dbInventory.id);
      await _weatherProvider.loadWeatherForInventory(dbInventory.id);
    }
    debugPrint('[PROVIDER] ...Sync complete. Current active count: ${activeInventories.length}');
    } catch (e, s) {
      debugPrint('[PROVIDER] !!! ERROR syncing inventories: $e\n$s');
    } finally {
      _isLoading = false;
      notifyListeners();
      debugPrint('[PROVIDER] fetchInventories complete. Notifying listeners.');
      debugPrint('[PROVIDER] ----------------------------------');
    }
  }

  // Get inventory data by ID
  Inventory? getInventoryById(String id) {
    return _inventoryMap[id]; // Get the inventory from map
  }

  // Check if an inventory ID already exists
  Future<bool> inventoryIdExists(String id) async {
    return await _inventoryDao.inventoryIdExists(id);
  }

  // Add inventory to the database and the list
  Future<bool> addInventory(BuildContext context, Inventory inventory) async {
    debugPrint('[PROVIDER] Adding new inventory: ${inventory.id}');
    try {
      await _inventoryDao.insertInventory(context, inventory);
      _inventories.add(inventory);
      _inventoryMap[inventory.id] = inventory; // Add to the map
      notifyListeners();
      debugPrint('[PROVIDER] ...Success. Starting timer for new inventory.');
      startInventoryTimer(context, inventory, _inventoryDao);

      return true;
    } catch (error) {
      debugPrint('[PROVIDER] !!! ERROR adding inventory ${inventory.id}: $error');
      return false;
    }
  }

  // Add imported inventory to the database and the list
  Future<bool> importInventory(Inventory inventory) async {
    debugPrint('[PROVIDER] Importing inventory: ${inventory.id}');
    try {
      await _inventoryDao.importInventory(inventory);
      _inventories.add(inventory);
      _inventoryMap[inventory.id] = inventory; // Add to the map
      notifyListeners();
      debugPrint('[PROVIDER] ...Import complete for ${inventory.id}. Notifying listeners.');

      return true;
    } catch (error) {
      debugPrint('[PROVIDER] !!! ERROR importing inventory ${inventory.id}: $error');
      return false;
    }
  }

  // Update inventory in the database and the list
  Future<void> updateInventory(Inventory inventory) async {
    debugPrint('[PROVIDER] Updating inventory: ${inventory.id}');
    await _inventoryDao.updateInventory(inventory);

    final index = _inventories.indexWhere((inv) => inv.id == inventory.id);
    if (index != -1) {
      _inventories[index] = inventory;
    }
    // Ensure the map also has the updated instance, though if instances are shared, this might be redundant.
    _inventoryMap[inventory.id] = inventory;
    
    inventoryFinishedNotifier.value = inventory.isFinished;
    notifyListeners();
    debugPrint('[PROVIDER] ...Update complete for ${inventory.id}. Notifying listeners.');
  }

  // Remove inventory from the database and the list
  Future<void> removeInventory(String id) async {
    debugPrint('[PROVIDER] Removing inventory: $id');
    await _inventoryDao.deleteInventory(id);

    _inventories.removeWhere((inventory) => inventory.id == id);
    _inventoryMap.remove(id);
    notifyListeners();
    debugPrint('[PROVIDER] ...Removal complete for $id. Notifying listeners.');
  }

  // Get an active inventory by ID
  Inventory getActiveInventoryById(String id) {
    return activeInventories.firstWhere((inventory) => inventory.id == id);
  }

  // Start inventory timer
  void startInventoryTimer(BuildContext context, Inventory inventory, InventoryDao inventoryDao) {
    if (inventory.duration > 0 && !inventory.isFinished && !inventory.isPaused) {
      debugPrint('[PROVIDER] Commanding START timer for ${inventory.id}');
      inventory.startTimer(context, inventoryDao);
      updateInventory(inventory);
      // notifyListeners();
    } else {
      debugPrint('[PROVIDER] SKIPPED commanding START timer for ${inventory.id} (isFinished=${inventory.isFinished}, isPaused=${inventory.isPaused})');
    }
  }

  // Pause inventory timer
  void pauseInventoryTimer(Inventory inventory, InventoryDao inventoryDao) {
    debugPrint('[PROVIDER] Commanding PAUSE timer for ${inventory.id}');
    inventory.pauseTimer(inventoryDao);
    updateInventory(inventory);
    // notifyListeners();
  }

  // Resume inventory timer
  void resumeInventoryTimer(BuildContext context, Inventory inventory, InventoryDao inventoryDao) {
    debugPrint('[PROVIDER] Commanding RESUME timer for ${inventory.id}');
    inventory.resumeTimer(context, inventoryDao);
    updateInventory(inventory);
    // notifyListeners();
  }

  // Update the ID in the database and the list
  Future<void> changeInventoryId(BuildContext context, String oldId, String newId) async {
    await _inventoryDao.changeInventoryId(oldId, newId);
    // await fetchInventories(context);
    final inventory = _inventoryMap[oldId];
    if (inventory != null) {
      _inventoryMap.remove(oldId);
      inventory.id = newId;
      _inventoryMap[newId] = inventory;
    }
    notifyListeners();
  }

  // Update the elapsed time in the database and the list
  Future<void> updateInventoryElapsedTime(String inventoryId, double elapsedTime) async {
    await _inventoryDao.updateInventoryElapsedTime(inventoryId, elapsedTime);
    _inventoryMap[inventoryId]?.elapsedTime = elapsedTime;
    final index = _inventories.indexWhere((inv) => inv.id == inventoryId);
    if (index != -1 && _inventories[index].elapsedTime != elapsedTime) {
      // To ensure the instance in the list is also updated if it's a different object or for direct field update
      _inventories[index].elapsedTime = elapsedTime;
    }
    notifyListeners();
  }

  // Update the current interval in the database and the list
  Future<void> updateInventoryCurrentInterval(String inventoryId, int currentInterval) async {
    await _inventoryDao.updateInventoryCurrentInterval(inventoryId, currentInterval);
    _inventoryMap[inventoryId]?.currentInterval = currentInterval;
    final index = _inventories.indexWhere((inv) => inv.id == inventoryId);
    if (index != -1 && _inventories[index].currentInterval != currentInterval) {
      // To ensure the instance in the list is also updated
      _inventories[index].currentInterval = currentInterval;
    }
    notifyListeners();
  }

  // Update the species list count
  void updateSpeciesCount(String inventoryId) {
    final inventory = getInventoryById(inventoryId);
    if (inventory != null) {
      final speciesList = _speciesProvider.getSpeciesForInventory(inventoryId);
      inventory.speciesCount = speciesList.length;
      inventory.speciesOutOfInventoryCount =
          speciesList.where((s) => s.isOutOfInventory).length;
      inventory.speciesWithinCount =
          inventory.speciesCount - inventory.speciesOutOfInventoryCount;
      speciesCountNotifier.value = inventory.speciesCount;
      notifyListeners();
    }
  }

  // Concatenate the next inventory ID
  Future<int> getNextSequentialNumber(String? local, String observer, int ano, int mes, int dia, String? typeChar) {
    return _inventoryDao.getNextSequentialNumber(local, observer, ano, mes, dia, typeChar);
  }

  // Calculate the total sampling hours from all inventories (via SQL - much faster)
  Future<double> getTotalSamplingHours() async {
    return await _inventoryDao.getTotalSamplingHours_SQL();
  }

  // Calculate the average sampling hours from all inventories (via SQL - much faster)
  Future<double> getAverageSamplingHours() async {
    return await _inventoryDao.getAverageSamplingHours_SQL();
  }
  // Get total sampling days from all inventories (via SQL - much faster)
  Future<int> getTotalSamplingDays() async {
    return await _inventoryDao.getTotalSamplingDays_SQL();
  }


  // Get list of distinct localities for autocomplete
  Future<List<String>> getDistinctLocalities() {
    return _inventoryDao.getDistinctLocalities();
  }

  Future<List<String>> get allSpeciesInInventories async {
    final speciesSet = <String>{};
    final allInventories = await _inventoryDao.getInventories();
    for (var inv in allInventories) {
      for (var record in inv.speciesList) {
        speciesSet.add(record.name);
      }
    }
    return speciesSet.toList()..sort();
  }

  // Load inventories with lightweight summary (no sub-entities)
  Future<void> fetchInventoriesSummary(BuildContext context) async {
    debugPrint('[PROVIDER] Fetching inventories summary (lightweight)...');
    _isLoading = true;
    try {
      final inventoriesFromDb = await _inventoryDao.getInventoriesSummary();
      final Set<String> dbInventoryIds = inventoriesFromDb.map((inv) => inv.id).toSet();

      _inventoryMap.removeWhere((id, inventory) => !dbInventoryIds.contains(id));
      _inventories.removeWhere((inventory) => !dbInventoryIds.contains(inventory.id));

      for (var dbInventory in inventoriesFromDb) {
        if (_inventoryMap.containsKey(dbInventory.id)) {
          final memoryInventory = _inventoryMap[dbInventory.id]!;
          memoryInventory.currentInterval = dbInventory.currentInterval;
          memoryInventory.elapsedTime = dbInventory.elapsedTime;
          memoryInventory.isFinished = dbInventory.isFinished;
          memoryInventory.isPaused = dbInventory.isPaused;
          memoryInventory.startTime = dbInventory.startTime;
          memoryInventory.endTime = dbInventory.endTime;
          memoryInventory.duration = dbInventory.duration;
          memoryInventory.localityName = dbInventory.localityName;
          memoryInventory.speciesCount = dbInventory.speciesCount;
          memoryInventory.speciesWithinCount = dbInventory.speciesWithinCount;
          memoryInventory.speciesOutOfInventoryCount =
              dbInventory.speciesOutOfInventoryCount;
          memoryInventory.currentIntervalSpeciesCount = dbInventory.currentIntervalSpeciesCount;
          memoryInventory.totalPausedTimeInSeconds = dbInventory.totalPausedTimeInSeconds;
          memoryInventory.pauseStartTime = dbInventory.pauseStartTime;
          memoryInventory.intervalsWithoutNewSpecies = dbInventory.intervalsWithoutNewSpecies;
          memoryInventory.isDiscarded = dbInventory.isDiscarded;
        } else {
          _inventories.add(dbInventory);
          _inventoryMap[dbInventory.id] = dbInventory;
        }
      }
      debugPrint('[PROVIDER] Summary sync complete. Count: ${activeInventories.length}');
    } catch (e, s) {
      debugPrint('[PROVIDER] !!! ERROR syncing inventories summary: $e\n$s');
    } finally {
      _isLoading = false;
      notifyListeners();
      debugPrint('[PROVIDER] fetchInventoriesSummary complete.');
    }
  }

  // Load complete details for a specific inventory (used on-demand)
  Future<void> loadInventoryDetails(String inventoryId) async {
    try {
      final inventory = await _inventoryDao.getInventoryById(inventoryId);
      final index = _inventories.indexWhere((inv) => inv.id == inventoryId);
      if (index != -1) {
        _inventories[index] = inventory;
      }
      _inventoryMap[inventoryId] = inventory;
      notifyListeners();
      debugPrint('[PROVIDER] Loaded complete details for inventory: $inventoryId');
    } catch (e) {
      debugPrint('[PROVIDER] !!! ERROR loading inventory details: $e');
    }
  }

  // Load complete details for multiple inventories (used for statistics)
  Future<List<Inventory>> loadInventoriesDetails(List<String> inventoryIds) async {
    try {
      final inventories = <Inventory>[];
      for (var id in inventoryIds) {
        final inventory = await _inventoryDao.getInventoryById(id);
        final index = _inventories.indexWhere((inv) => inv.id == id);
        if (index != -1) {
          _inventories[index] = inventory;
        }
        _inventoryMap[id] = inventory;
        inventories.add(inventory);
      }
      notifyListeners();
      debugPrint('[PROVIDER] Loaded complete details for ${inventories.length} inventories');
      return inventories;
    } catch (e) {
      debugPrint('[PROVIDER] !!! ERROR loading inventory details: $e');
      return [];
    }
  }
}