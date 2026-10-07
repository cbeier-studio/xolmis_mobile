import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:settings_ui/settings_ui.dart';

/// Tokens de cores do Xolmis Design System (Material Design 3 + Cores da Marca)
class XolmisColors {
  // Material 3 Primary & Secondary Tokens
  static const Color primary = Color(0xFF6750A4);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFEADDFF);
  static const Color onPrimaryContainer = Color(0xFF21005D);
  static const Color secondary = Color(0xFF625B71);
  static const Color secondaryContainer = Color(0xFFE8DEF8);
  static const Color onSecondaryContainer = Color(0xFF1D192B);
  static const Color surface = Color(0xFFFEF7FF);
  static const Color surfaceVariant = Color(0xFFE7E0EC);
  static const Color outline = Color(0xFF79747E);
  static const Color outlineVariant = Color(0xFFC9C5D0);

  // Cores de Suporte Xolmis
  static const Color jacarandaCore = Color(0xFF6B66C5);
  static const Color jacarandaDeep = Color(0xFF48429B);
  static const Color jacarandaLight = Color(0xFFECECFA);
  static const Color jacarandaContainer = Color(0xFFE2E0F9);
  static const Color folhaCampo = Color(0xFF3A7D52);
  static const Color terraMadeira = Color(0xFF8C6D52);
  static const Color borderSubtle = Color(0xFFE0E2EC);

  // Status Semânticos
  static const Color success = Color(0xFF2E7D32);
  static const Color successContainer = Color(0xFFC8E6C9);
  static const Color onSuccessContainer = Color(0xFF1B5E20);

  static const Color warning = Color(0xFFED6C02);
  static const Color warningContainer = Color(0xFFFFE0B2);
  static const Color onWarningContainer = Color(0xFFE65100);

  static const Color error = Color(0xFFB3261E);
  static const Color errorContainer = Color(0xFFF9DEDC);

  static const Color info = Color(0xFF0288D1);
  static const Color infoContainer = Color(0xFFB3E5FC);

  static const Color pinkAccent = Color(0xFFEC4899);
}

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