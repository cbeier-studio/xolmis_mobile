import 'package:flutter/material.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import '../../core/core_consts.dart';
import '../../utils/utils.dart';
import '../../utils/themes.dart';
import '../../generated/l10n.dart';

class GeneralSettings extends StatefulWidget {
  const GeneralSettings({super.key});

  @override
  State<GeneralSettings> createState() => _GeneralSettingsState();
}

class _GeneralSettingsState extends State<GeneralSettings> {
  ThemeMode _themeMode = ThemeMode.system;
  int _startupModuleIndex = StartupModule.inventories.index;
  SupportedCountry _userCountry = SupportedCountry.BR;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  /// Loads persisted settings from shared preferences into local state.
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _userCountry = await getCountrySetting();
    setState(() {
      _themeMode = ThemeMode.values[prefs.getInt('themeMode') ?? 0];
      _startupModuleIndex =
          prefs.getInt(kStartupModulePreferenceKey) ??
              StartupModule.inventories.index;

      if (_startupModuleIndex < 0 ||
          _startupModuleIndex >= StartupModule.values.length) {
        _startupModuleIndex = StartupModule.inventories.index;
      }
    });
  }

  /// Persists the current in-memory settings to shared preferences.
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', _themeMode.index);
    await prefs.setInt(kStartupModulePreferenceKey, _startupModuleIndex);
    await prefs.setString('user_country', _userCountry.name);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.current.generalSettings),
      ),
      body: SettingsList(
        contentPadding: EdgeInsets.zero,
        crossAxisAlignment: CrossAxisAlignment.start,
        applicationType: ApplicationType.material,
        platform: DevicePlatform.android,
        sections: [
          SettingsSection(
            tiles: [
              SettingsTile.navigation(
                leading: const Icon(Icons.contrast_outlined),
                title: Text(S.of(context).appearance),
                value: Builder(
                  builder: (context) {
                    switch (_themeMode) {
                      case ThemeMode.light:
                        return Text(S.of(context).lightMode);
                      case ThemeMode.dark:
                        return Text(S.of(context).darkMode);
                      case ThemeMode.system:
                        return Text(S.of(context).systemMode);
                    }
                  },
                ),
                onPressed: (context) {
                  buildThemeModeSelector(context);
                },
              ),
              SettingsTile.navigation(
                leading: const Icon(Icons.home_outlined),
                title: Text(S.of(context).startupModule),
                value: Text(_getStartupModuleLabel(context, _startupModuleIndex)),
                onPressed: (context) async {
                  final selectedModule =
                  await _showStartupModuleSelectionDialog(context);

                  if (selectedModule != null &&
                      selectedModule != _startupModuleIndex) {
                    setState(() {
                      _startupModuleIndex = selectedModule;
                    });
                    await _saveSettings();
                  }
                },
              ),
              SettingsTile.navigation(
                leading: const Icon(Icons.language_outlined),
                title: Text(S.current.speciesSearchCountry),
                value: Text(countryMetadata[_userCountry]?.name ?? ''),
                onPressed: (context) async {
                  // Abre o novo diálogo de seleção de país
                  final SupportedCountry? newCountry =
                  await showCountrySelectionDialog(context);

                  // Se o usuário selecionou um novo país e o valor é diferente
                  if (newCountry != null && newCountry != _userCountry) {
                    setState(() {
                      _userCountry = newCountry;
                    });
                    // Salva a nova configuração
                    await _saveSettings();

                    // Recarrega os dados de espécies com base no novo país
                    List<String> preloadedSpeciesNames =
                    await loadSpeciesSearchData();
                    preloadedSpeciesNames.sort((a, b) => a.compareTo(b));
                    // Atualiza a lista global de espécies
                    allSpeciesNames = List.from(preloadedSpeciesNames);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds and shows a dialog for selecting the user's country.
  Future<SupportedCountry?> showCountrySelectionDialog(
      BuildContext context,
      ) async {
    SupportedCountry? tempSelectedCountry = _userCountry;

    return await showDialog<SupportedCountry>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(S.current.country),
              contentPadding: const EdgeInsets.only(top: 20.0),
              content: SingleChildScrollView(
                child: RadioGroup<SupportedCountry>(
                  groupValue: tempSelectedCountry,
                  onChanged: (SupportedCountry? value) {
                    setDialogState(() {
                      tempSelectedCountry = value;
                    });
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children:
                    SupportedCountry.values.map((country) {
                      return RadioListTile<SupportedCountry>(
                        title: Text(countryMetadata[country]?.name ?? ''),
                        value: country,
                      );
                    }).toList(),
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text(S.of(context).cancel),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text(S.of(context).save),
                  onPressed: () {
                    Navigator.of(context).pop(tempSelectedCountry);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Shows a dialog for selecting the theme mode.
  Future<dynamic> buildThemeModeSelector(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: Text(S.of(context).selectMode),
          children: [
            SimpleDialogOption(
              child: Row(
                children: [
                  const Icon(Icons.light_mode_outlined),
                  const SizedBox(width: 8.0),
                  Text(S.of(context).lightMode),
                ],
              ),
              onPressed: () {
                setState(() {
                  _themeMode = ThemeMode.light;
                });
                _saveSettings();
                Provider.of<ThemeModel>(context, listen: false).getThemeMode();
                Navigator.pop(context);
              },
            ),
            SimpleDialogOption(
              child: Row(
                children: [
                  const Icon(Icons.dark_mode_outlined),
                  const SizedBox(width: 8.0),
                  Text(S.of(context).darkMode),
                ],
              ),
              onPressed: () {
                setState(() {
                  _themeMode = ThemeMode.dark;
                });
                _saveSettings();
                Provider.of<ThemeModel>(context, listen: false).getThemeMode();
                Navigator.pop(context);
              },
            ),
            SimpleDialogOption(
              child: Row(
                children: [
                  const Icon(Icons.contrast_outlined),
                  const SizedBox(width: 8.0),
                  Text(S.of(context).systemMode),
                ],
              ),
              onPressed: () {
                setState(() {
                  _themeMode = ThemeMode.system;
                });
                _saveSettings();
                Provider.of<ThemeModel>(context, listen: false).getThemeMode();
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  /// Returns the localized label for a startup module index.
  String _getStartupModuleLabel(BuildContext context, int moduleIndex) {
    switch (StartupModule.values[moduleIndex]) {
      case StartupModule.inventories:
        return S.of(context).inventories;
      case StartupModule.nests:
        return S.of(context).nests;
      case StartupModule.specimens:
        return S.of(context).specimens(2);
      case StartupModule.fieldJournal:
        return S.of(context).fieldJournal;
      case StartupModule.statistics:
        return S.of(context).statistics;
    }
  }

  /// Shows a dialog to choose which module opens on startup.
  Future<int?> _showStartupModuleSelectionDialog(BuildContext context) async {
    int tempSelectedModule = _startupModuleIndex;

    return showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(S.of(context).startupModule),
              content: SingleChildScrollView(
                child: RadioGroup<int>(
                  groupValue: tempSelectedModule,
                  onChanged: (int? value) {
                    if (value == null) return;
                    setDialogState(() {
                      tempSelectedModule = value;
                    });
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: List<Widget>.generate(
                      StartupModule.values.length,
                          (index) => RadioListTile<int>(
                        title: Text(_getStartupModuleLabel(context, index)),
                        value: index,
                      ),
                    ),
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text(S.of(context).cancel),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                TextButton(
                  child: Text(S.of(context).save),
                  onPressed: () => Navigator.of(context).pop(tempSelectedModule),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
