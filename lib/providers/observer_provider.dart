import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/daos/observer_dao.dart';
import '../data/models/observer.dart';

/// Manages the list of available observers and the default observer setting.
class ObserverProvider with ChangeNotifier {
  final ObserverDao _observerDao;
  List<Observer> _observers = [];
  String? _defaultObserverAbbrev;

  ObserverProvider(this._observerDao);

  /// All known observers.
  List<Observer> get observers => _observers;

  /// The abbreviation of the default observer.
  String? get defaultObserverAbbrev => _defaultObserverAbbrev;

  /// Loads all observers and the default observer abbreviation from storage.
  Future<void> fetchObservers() async {
    _observers = await _observerDao.getAllObservers();
    final prefs = await SharedPreferences.getInstance();
    _defaultObserverAbbrev = prefs.getString('defaultObserver');
    notifyListeners();
  }

  /// Adds a new observer to the database and refreshes the local list.
  Future<void> addObserver(Observer observer) async {
    await _observerDao.insertObserver(observer);
    await fetchObservers();
  }

  /// Updates an existing observer and refreshes the local list.
  Future<void> updateObserver(Observer observer) async {
    await _observerDao.updateObserver(observer);
    await fetchObservers();
  }

  /// Deletes an observer and refreshes the local list.
  Future<void> deleteObserver(String observerAbbrev) async {
    await _observerDao.deleteObserver(observerAbbrev);
    await fetchObservers();
  }

  /// Sets the default observer abbreviation in SharedPreferences.
  Future<void> setDefaultObserver(String? abbrev) async {
    final prefs = await SharedPreferences.getInstance();
    if (abbrev == null) {
      await prefs.remove('defaultObserver');
    } else {
      await prefs.setString('defaultObserver', abbrev);
    }
    _defaultObserverAbbrev = abbrev;
    notifyListeners();
  }

  /// Returns the default [Observer] object, if it exists.
  Observer? getDefaultObserver() {
    if (_defaultObserverAbbrev == null) return null;
    try {
      return _observers.firstWhere((o) => o.observerAbbrev == _defaultObserverAbbrev);
    } catch (_) {
      return null;
    }
  }
}
