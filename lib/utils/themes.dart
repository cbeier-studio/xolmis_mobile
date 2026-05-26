import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';


/// Holds the app theme mode and notifies listeners when it changes.
class ThemeModel extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  /// The current theme mode used by the application.
  ThemeMode get themeMode => _themeMode;

  /// Toggles the app theme between light and dark modes.
  ///
  /// This method does not persist the selected value; it only updates the
  /// in-memory state and notifies listeners.
  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    notifyListeners();
  }

  /// Loads the persisted theme mode from shared preferences.
  ///
  /// When no saved value exists, [ThemeMode.system] is used.
  void getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeIndex = prefs.getInt('themeMode') ?? 0; // 0 is the default value for ThemeMode.system
    _themeMode = ThemeMode.values[themeModeIndex];
    notifyListeners();
  }
}