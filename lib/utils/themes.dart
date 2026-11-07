import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:settings_ui/settings_ui.dart';

/// Tokens de cores do Xolmis Design System (Material Design 3 + Cores da Marca)
class XolmisColors {
  // Material 3 Primary & Secondary Tokens
  static const Color primary = Color(0xFF6B66C5);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFEADDFF);
  static const Color onPrimaryContainer = Color(0xFF2A2566);
  static const Color secondary = Color(0xFF625B71);
  static const Color secondaryContainer = Color(0xFFE8DEF8);
  static const Color onSecondaryContainer = Color(0xFF1D192B);
  static const Color surface = Color(0xFFFEF7FF);
  static const Color surfaceVariant = Color(0xFFE7E0EC);
  static const Color outline = Color(0xFF79747E);
  static const Color outlineVariant = Color(0xFFC9C5D0);
  static const Color borderSubtle = Color(0xFFE0E2EC);

  static const surfaceSuperficieBase = Color(0xFFF8F9FE);
  static const surfaceSuperficieSecundaria = Color(0xFFF0F1F8);
  static const surfaceSuperficieTerciaria = Color(0xFFFBFCFF);
  static const surfaceSuperficieElevada = Color(0xFFFFFFFF);
  static const surfaceCardSecundario = Color(0xFFF8F9FE);
  static const surfaceDivisor = Color(0xFFE0E2EC);
  static const surfaceStrokeDeControle = Color(0xFF8A8D98);
  static const surfaceBordaDesabilitada = Color(0xFFECEDF3);
  static const surfaceTexto = Color(0xFF191C20);
  static const surfaceTextoSecundario = Color(0xFF44474F);
  static const surfaceTextoTerciario = Color(0xFF5C5F68);
  static const surfaceTextoDesabilitado = Color(0xFF9EA1A9);
  static const surfaceMarcaTextoAcento = Color(0xFF48429B);
  static const surfaceLinkHover = Color(0xFF2A2566);
  static const surfaceTintSelecao = Color(0xFFECECFA);
  static const surfaceSelecaoForte = Color(0xFFD5CDF2);

  // Xolmis Brand Colors
  static const Color jacarandaCore = Color(0xFF6B66C5);
  static const Color jacarandaDeep = Color(0xFF48429B);
  static const Color jacarandaLight = Color(0xFFECECFA);
  static const Color jacarandaContainer = Color(0xFFE2E0F9);
  static const Color rosaOrquideaCore = Color(0xFFC25283);
  static const Color rosaOrquideaDeep = Color(0xFF8E2A59);
  static const Color rosaOrquideaContainer = Color(0xFFF8D7E3);
  static const Color folhaCampo = Color(0xFF3A7D52);
  static const Color terraMadeira = Color(0xFF8C6D52);

  // Categorical Palette
  static const catMandacaruVivo = Color(0xFF2B854F);
  static const catMandacaruPastel = Color(0xFFE0F7E6);
  static const catGencianaVivo = Color(0xFF2971C6);
  static const catGencianaPastel = Color(0xFFE7F1FF);
  static const catIpeAmareloVivo = Color(0xFFAC9002);
  static const catIpeAmareloPastel = Color(0xFFF8F0D3);
  static const catPitangaVivo = Color(0xFFC43F3E);
  static const catPitangaPastel = Color(0xFFFFEBE9);
  static const catBromeliaVivo = Color(0xFF0DA1B2);
  static const catBromeliaPastel = Color(0xFFD9F6FB);
  static const catQuaresmeiraVivo = Color(0xFF8551B8);
  static const catQuaresmeiraPastel = Color(0xFFF4ECFF);
  static const catHibiscoVivo = Color(0xFFBD3E76);
  static const catHibiscoPastel = Color(0xFFFFEAF0);
  static const catCajuVivo = Color(0xFFCF6F19);
  static const catCajuPastel = Color(0xFFFFECE0);
  static const catVitoriaRegiaVivo = Color(0xFF008476);
  static const catVitoriaRegiaPastel = Color(0xFFDDF7F1);
  static const catSamambaiaVivo = Color(0xFF83A01F);
  static const catSamambaiaPastel = Color(0xFFEBF5D6);
  static const catAnilVivo = Color(0xFF5E63C5);
  static const catAnilPastel = Color(0xFFECEFFF);
  static const catOrquideaVivo = Color(0xFFC360BC);
  static const catOrquideaPastel = Color(0xFFFFE8FC);
  static const catJatobaVivo = Color(0xFF8E6040);
  static const catJatobaPastel = Color(0xFFFCEDE3);
  static const catArdosiaVivo = Color(0xFF607183);
  static const catArdosiaPastel = Color(0xFFEBF1F7);
  static const catLiquenVivo = Color(0xFF7B8C78);
  static const catLiquenPastel = Color(0xFFEDF2EC);
  static const catPedraVivo = Color(0xFF999185);
  static const catPedraPastel = Color(0xFFF2F0EC);
  static const catOutrosVivo = Color(0xFF999185);
  static const catOutrosPastel = Color(0xFFF2F0EC);

  // Semantic Statuses
  static const success = Color(0xFF2E7D32);
  static const successContainer = Color(0xFFE8F5E9);
  static const successOnContainer = Color(0xFF1B5E20);
  static const warning = Color(0xFFB45309);
  static const warningContainer = Color(0xFFFFF0D6);
  static const warningOnContainer = Color(0xFF7A3E00);
  static const error = Color(0xFFB3261E);
  static const errorContainer = Color(0xFFF9DEDC);
  static const errorOnContainer = Color(0xFF410E0B);
  static const info = Color(0xFF0277BD);
  static const infoContainer = Color(0xFFE1F2FD);
  static const infoOnContainer = Color(0xFF01426E);
  static const neutral = Color(0xFF5F6560);
  static const neutralContainer = Color(0xFFE2E8E3);
  static const neutralOnContainer = Color(0xFF444945);
  static const alternative = Color(0xFF6F42A5);
  static const alternativeContainer = Color(0xFFF1EAF8);
  static const alternativeOnContainer = Color(0xFF4C2E72);
  static const medium = Color(0xFF8F3B00);
  static const mediumContainer = Color(0xFFFFE6D5);
  static const mediumOnContainer = Color(0xFF8F3B00);

  // Chart Palette
  static const chartMandacaru = Color(0xFF2B854F);
  static const chartGenciana = Color(0xFF2971C6);
  static const chartIpeAmarelo = Color(0xFFAC9002);
  static const chartPitanga = Color(0xFFC43F3E);
  static const chartBromelia = Color(0xFF0DA1B2);
  static const chartQuaresmeira = Color(0xFF8551B8);
  static const chartHibisco = Color(0xFFBD3E76);
  static const Color pinkAccent = Color(0xFFEC4899);
  static const chartCaju = Color(0xFFCF6F19);
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