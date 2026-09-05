import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:settings_ui/settings_ui.dart';

/// Returns the default light theme for settings lists.
SettingsThemeData getSettingsLightTheme(BuildContext context) {
  return SettingsThemeData(
    settingsListBackground: Theme.of(context).scaffoldBackgroundColor,
    settingsSectionBackground: Theme.of(context).cardColor,
    settingsTileTextColor: Theme.of(context).colorScheme.onSurface,
    tileDescriptionTextColor: Theme.of(context).colorScheme.onSurfaceVariant,
    leadingIconsColor: Theme.of(context).colorScheme.primary,
    titleTextColor: Theme.of(context).colorScheme.primary,
    trailingTextColor: Theme.of(context).colorScheme.onSurfaceVariant,
  );
}

/// Returns the default dark theme for settings lists.
SettingsThemeData getSettingsDarkTheme(BuildContext context) {
  return SettingsThemeData(
    settingsListBackground: Theme.of(context).scaffoldBackgroundColor,
    settingsSectionBackground: Theme.of(context).cardColor,
    settingsTileTextColor: Theme.of(context).colorScheme.onSurface,
    tileDescriptionTextColor: Theme.of(context).colorScheme.onSurfaceVariant,
    leadingIconsColor: Theme.of(context).colorScheme.primary,
    titleTextColor: Theme.of(context).colorScheme.primary,
    trailingTextColor: Theme.of(context).colorScheme.onSurfaceVariant,
  );
}


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