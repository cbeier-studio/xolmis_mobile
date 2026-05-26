import 'package:flutter/material.dart';

import '../data/models/inventory.dart';
import '../data/daos/inventory_dao.dart';

import 'species_provider.dart';
import 'vegetation_provider.dart';
import 'weather_provider.dart';

/// Manages inventory records, cached instances, and related timing state.
class InventoryProvider with ChangeNotifier {
  final InventoryDao _inventoryDao;
  final List<Inventory> _inventories = [];
  final Map<String, Inventory> _inventoryMap = {};

  /// Emits the last computed species count for an inventory.
  final ValueNotifier<int> speciesCountNotifier = ValueNotifier<int>(0);

  /// Emits whether the last updated inventory is finished.
  final ValueNotifier<bool> inventoryFinishedNotifier = ValueNotifier<bool>(false);
  // Flag to indicate that data is loading
  bool _isLoading = false;

  /// Whether the provider is currently loading inventory data.
  bool get isLoading => _isLoading;

  /// Inventories that are still active.
  List<Inventory> get activeInventories =>
      _inventories.where((inventory) => !inventory.isFinished).toList();

  /// Inventories that have already finished.
  List<Inventory> get finishedInventories =>
      _inventories.where((inventory) => inventory.isFinished).toList();

  /// Number of active inventories.
  int get inventoriesCount => activeInventories.length;

  /// Total number of cached inventories.
  int get allInventoriesCount => _inventories.length;

  final SpeciesProvider _speciesProvider;
  final VegetationProvider _vegetationProvider;
  final WeatherProvider _weatherProvider;
  /// Access to the species provider used for inventory child records.
  SpeciesProvider get speciesProvider => _speciesProvider;

  /// Access to the vegetation provider used for inventory child records.
  VegetationProvider get vegetationProvider => _vegetationProvider;

  /// Access to the weather provider used for inventory child records.
  WeatherProvider get weatherProvider => _weatherProvider;

  InventoryProvider(this._inventoryDao, this._speciesProvider, this._vegetationProvider, this._weatherProvider);

  /// Notifies listeners without changing provider state.
  void refreshState() {
    notifyListeners();
  }

  /// Loads all inventories from the database and synchronizes cached instances.
  ///
  /// Existing in-memory objects are updated in place so active timers and other
  /// runtime state can survive refreshes.
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

  /// Returns the cached inventory identified by [id], if any.
  Inventory? getInventoryById(String id) {
    return _inventoryMap[id]; // Get the inventory from map
  }

  /// Returns whether [id] already exists in persistent storage.
  Future<bool> inventoryIdExists(String id) async {
    return await _inventoryDao.inventoryIdExists(id);
  }

  /// Adds a new inventory, caches it, and starts its timer when applicable.
  ///
  /// Returns `true` when the insert succeeds and `false` otherwise.
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

  /// Imports an inventory record and caches it locally.
  ///
  /// Returns `true` when the import succeeds and `false` otherwise.
  Future<bool> importInventory(Inventory inventory) async {
    debugPrint('[PROVIDER] Importing inventory: ${inventory.id}');
    try {
      final success = await _inventoryDao.importInventory(inventory);
      if (!success) {
        return false;
      }

      final index = _inventories.indexWhere((inv) => inv.id == inventory.id);
      if (index != -1) {
        _inventories[index] = inventory;
      } else {
        _inventories.add(inventory);
      }
      _inventoryMap[inventory.id] = inventory; // Add to the map

      await _speciesProvider.loadSpeciesForInventory(inventory.id);
      await _vegetationProvider.loadVegetationForInventory(inventory.id);
      await _weatherProvider.loadWeatherForInventory(inventory.id);

      notifyListeners();
      debugPrint('[PROVIDER] ...Import complete for ${inventory.id}. Notifying listeners.');

      return true;
    } catch (error) {
      debugPrint('[PROVIDER] !!! ERROR importing inventory ${inventory.id}: $error');
      return false;
    }
  }

  /// Updates an inventory in storage and refreshes the cached instance.
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

  /// Deletes the inventory identified by [id] from storage and cache.
  Future<void> removeInventory(String id) async {
    debugPrint('[PROVIDER] Removing inventory: $id');
    await _inventoryDao.deleteInventory(id);

    _inventories.removeWhere((inventory) => inventory.id == id);
    _inventoryMap.remove(id);
    notifyListeners();
    debugPrint('[PROVIDER] ...Removal complete for $id. Notifying listeners.');
  }

  /// Returns an active inventory by identifier.
  ///
  /// Throws if no active inventory with [id] exists.
  Inventory getActiveInventoryById(String id) {
    return activeInventories.firstWhere((inventory) => inventory.id == id);
  }

  /// Starts the runtime timer for [inventory] when it is eligible to run.
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

  /// Pauses the runtime timer for [inventory].
  void pauseInventoryTimer(Inventory inventory, InventoryDao inventoryDao) {
    debugPrint('[PROVIDER] Commanding PAUSE timer for ${inventory.id}');
    inventory.pauseTimer(inventoryDao);
    updateInventory(inventory);
    // notifyListeners();
  }

  /// Resumes the runtime timer for [inventory].
  void resumeInventoryTimer(BuildContext context, Inventory inventory, InventoryDao inventoryDao) {
    debugPrint('[PROVIDER] Commanding RESUME timer for ${inventory.id}');
    inventory.resumeTimer(context, inventoryDao);
    updateInventory(inventory);
    // notifyListeners();
  }

  /// Changes an inventory identifier in storage and updates cached references.
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

  /// Persists and caches the elapsed time for an inventory.
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

  /// Persists and caches the current interval for an inventory.
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

  /// Recalculates cached species counters for [inventoryId].
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

  /// Returns the next sequential inventory number for the given identifier parts.
  Future<int> getNextSequentialNumber(String? local, String observer, int ano, int mes, int dia, String? typeChar) {
    return _inventoryDao.getNextSequentialNumber(local, observer, ano, mes, dia, typeChar);
  }

  /// Returns the total sampling hours across all inventories using SQL.
  Future<double> getTotalSamplingHours() async {
    return await _inventoryDao.getTotalSamplingHours_SQL();
  }

  /// Returns the average sampling hours across all inventories using SQL.
  Future<double> getAverageSamplingHours() async {
    return await _inventoryDao.getAverageSamplingHours_SQL();
  }
  /// Returns the total number of sampling days across all inventories using SQL.
  Future<int> getTotalSamplingDays() async {
    return await _inventoryDao.getTotalSamplingDays_SQL();
  }


  /// Returns distinct inventory localities for autocomplete suggestions.
  Future<List<String>> getDistinctLocalities() {
    return _inventoryDao.getDistinctLocalities();
  }

  /// Returns all distinct species names found across persisted inventories.
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

  /// Loads lightweight inventory summaries without nested child collections.
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

  /// Loads complete details for a specific inventory on demand.
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

  /// Loads complete details for multiple inventories on demand.
  ///
  /// Returns the fully loaded inventory objects in the same order they are
  /// retrieved from storage.
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