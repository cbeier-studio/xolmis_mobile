import 'dart:core';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:about/about.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/core_consts.dart';
import '../../utils/backup_utils.dart';
import '../../generated/l10n.dart';
import '../../utils/utils.dart';
import '../../utils/themes.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  ThemeMode _themeMode = ThemeMode.system;
  int _maxSimultaneousInventories = 2;
  int _maxSpeciesMackinnon = 10;
  int _pointCountsDuration = 8;
  int _cumulativeTimeDuration = 45;
  int _intervalsDuration = 10;
  String _observerAbbreviation = '';
  bool _formatNumbers = true;
  bool _remindVegetationEmpty = false;
  bool _remindWeatherEmpty = false;
  SupportedCountry _userCountry = SupportedCountry.BR;
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    _setPackageInfo();
    _loadSettings();
  }

  // Set the package info
  Future<void> _setPackageInfo() async => PackageInfo.fromPlatform().then(
    (PackageInfo packageInfo) => setState(() => _packageInfo = packageInfo),
  );

  // Load the settings from SharedPreferences
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _userCountry = await getCountrySetting();
    setState(() {
      _themeMode = ThemeMode.values[prefs.getInt('themeMode') ?? 0];
      _maxSimultaneousInventories =
          prefs.getInt('maxSimultaneousInventories') ?? 3;
      _maxSpeciesMackinnon = prefs.getInt('maxSpeciesMackinnon') ?? 10;
      _pointCountsDuration = prefs.getInt('pointCountsDuration') ?? 8;
      _cumulativeTimeDuration = prefs.getInt('cumulativeTimeDuration') ?? 45;
      _intervalsDuration = prefs.getInt('intervalsDuration') ?? 10;
      _observerAbbreviation = prefs.getString('observerAcronym') ?? '';
      _formatNumbers = prefs.getBool('formatNumbers') ?? true;
      _remindVegetationEmpty = prefs.getBool('remindVegetationEmpty') ?? false;
      _remindWeatherEmpty = prefs.getBool('remindWeatherEmpty') ?? false;
    });
  }

  // Save the settings to SharedPreferences
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', _themeMode.index);
    await prefs.setInt(
      'maxSimultaneousInventories',
      _maxSimultaneousInventories,
    );
    await prefs.setInt('maxSpeciesMackinnon', _maxSpeciesMackinnon);
    await prefs.setInt('pointCountsDuration', _pointCountsDuration);
    await prefs.setInt('cumulativeTimeDuration', _cumulativeTimeDuration);
    await prefs.setInt('intervalsDuration', _intervalsDuration);
    await prefs.setString('observerAcronym', _observerAbbreviation);
    await prefs.setBool('formatNumbers', _formatNumbers);
    await prefs.setBool('remindVegetationEmpty', _remindVegetationEmpty);
    await prefs.setBool('remindWeatherEmpty', _remindWeatherEmpty);
    await prefs.setString('user_country', _userCountry.name);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context).settings)),
      body: SafeArea(
        child: SettingsList(
          lightTheme: SettingsThemeData(
            settingsListBackground: ThemeData.light().scaffoldBackgroundColor,
            titleTextColor: Colors.deepPurple,
          ),
          sections: [
            SettingsSection(
              title: Text(S.of(context).observer),
              tiles: [
                // Observer abbreviation
                SettingsTile.navigation(
                  leading: const Icon(Icons.person_outlined),
                  title: Text(S.of(context).observerSetting),
                  value: Text(_observerAbbreviation),
                  onPressed: (context) async {
                    String? newObserver = await buildObserverDialog(context);

                    if (newObserver != null && newObserver.isNotEmpty) {
                      setState(() {
                        _observerAbbreviation = newObserver;
                      });
                      _saveSettings();
                    }
                  },
                ),
              ],
            ),
            SettingsSection(
              title: Text(S.of(context).speciesSearch),
              tiles: [
                SettingsTile.navigation(
                  leading: const Icon(Icons.language_outlined),
                  title: Text(S.current.country),
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
            SettingsSection(
              title: Text(S.of(context).inventories),
              tiles: [
                // Maximum number of simultaneous inventories
                SettingsTile.navigation(
                  leading: const Icon(Icons.list_alt_outlined),
                  title: Text(S.of(context).simultaneousInventories),
                  value: Text(
                    '$_maxSimultaneousInventories ${S.of(context).inventory(_maxSimultaneousInventories)}',
                  ),
                  onPressed: (context) async {
                    final newMaxInventories = await showDialog<int>(
                      context: context,
                      builder: (context) {
                        return NumberPickerDialog(
                          minValue: 1,
                          maxValue: 10,
                          initialValue: _maxSimultaneousInventories,
                          title: S.of(context).simultaneousInventories,
                        );
                      },
                    );
                    if (newMaxInventories != null) {
                      setState(() {
                        _maxSimultaneousInventories = newMaxInventories;
                      });
                      _saveSettings();
                    }
                  },
                ),
                // Mackinnon lists default number of species
                SettingsTile.navigation(
                  leading: const Icon(Icons.checklist_outlined),
                  title: Text(S.of(context).mackinnonLists),
                  value: Text(
                    S.of(context).speciesPerList(_maxSpeciesMackinnon),
                  ),
                  onPressed: (context) async {
                    final newMaxSpecies = await showDialog<int>(
                      context: context,
                      builder: (context) {
                        return NumberPickerDialog(
                          minValue: 1,
                          maxValue: 30,
                          initialValue: _maxSpeciesMackinnon,
                          title: S.of(context).speciesPerListTitle,
                        );
                      },
                    );
                    if (newMaxSpecies != null) {
                      setState(() {
                        _maxSpeciesMackinnon = newMaxSpecies;
                      });
                      _saveSettings();
                    }
                  },
                ),
                // Point counts default duration
                SettingsTile.navigation(
                  leading: const Icon(Icons.timer_outlined),
                  title: Text(S.of(context).pointCounts),
                  value: Text(
                    S.of(context).inventoryDuration(_pointCountsDuration),
                  ),
                  onPressed: (context) async {
                    final newDuration = await showDialog<int>(
                      context: context,
                      builder: (context) {
                        return NumberPickerDialog(
                          minValue: 1,
                          maxValue: 60,
                          initialValue: _pointCountsDuration,
                          title: S.of(context).durationMin,
                        );
                      },
                    );
                    if (newDuration != null) {
                      setState(() {
                        _pointCountsDuration = newDuration;
                      });
                      _saveSettings();
                    }
                  },
                ),
                // Timed qualitative list default duration
                SettingsTile.navigation(
                  leading: const Icon(Icons.timer_outlined),
                  title: Text(S.of(context).timedQualitativeLists),
                  value: Text(
                    S.of(context).inventoryDuration(_cumulativeTimeDuration),
                  ),
                  onPressed: (context) async {
                    final newDuration = await showDialog<int>(
                      context: context,
                      builder: (context) {
                        return NumberPickerDialog(
                          minValue: 1,
                          maxValue: 120,
                          initialValue: _cumulativeTimeDuration,
                          title: S.of(context).durationMin,
                        );
                      },
                    );
                    if (newDuration != null) {
                      setState(() {
                        _cumulativeTimeDuration = newDuration;
                      });
                      _saveSettings();
                    }
                  },
                ),
                // Interval qualitative list default duration
                SettingsTile.navigation(
                  leading: const Icon(Icons.timer_outlined),
                  title: Text(S.of(context).intervaledQualitativeLists),
                  value: Text(
                    S.of(context).inventoryDuration(_intervalsDuration),
                  ),
                  onPressed: (context) async {
                    final newDuration = await showDialog<int>(
                      context: context,
                      builder: (context) {
                        return NumberPickerDialog(
                          minValue: 1,
                          maxValue: 120,
                          initialValue: _intervalsDuration,
                          title: S.of(context).durationMin,
                        );
                      },
                    );
                    if (newDuration != null) {
                      setState(() {
                        _intervalsDuration = newDuration;
                      });
                      _saveSettings();
                    }
                  },
                ),
                SettingsTile.switchTile(
                  title: Text(S.of(context).remindMissingVegetationData),
                  // description: Text(S.of(context).formatNumbersDescription),
                  leading: const Icon(Icons.notification_important_outlined),
                  initialValue: _remindVegetationEmpty,
                  onToggle: (bool value) {
                    setState(() {
                      _remindVegetationEmpty = value;
                    });
                    _saveSettings();
                  },
                ),
                SettingsTile.switchTile(
                  title: Text(S.of(context).remindMissingWeatherData),
                  // description: Text(S.of(context).formatNumbersDescription),
                  leading: const Icon(Icons.notification_important_outlined),
                  initialValue: _remindWeatherEmpty,
                  onToggle: (bool value) {
                    setState(() {
                      _remindWeatherEmpty = value;
                    });
                    _saveSettings();
                  },
                ),
              ],
            ),
            SettingsSection(
              title: Text(S.of(context).export),
              tiles: [
                SettingsTile.switchTile(
                  title: Text(S.of(context).formatNumbers),
                  description: Text(S.of(context).formatNumbersDescription),
                  leading: const Icon(Icons.numbers_outlined),
                  initialValue: _formatNumbers,
                  onToggle: (bool value) {
                    setState(() {
                      _formatNumbers = value;
                    });
                    _saveSettings();
                  },
                ),
              ],
            ),
            SettingsSection(
              title: Text(S.of(context).general),
              tiles: [
                // Option to select the theme mode
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
                // About the app
                SettingsTile.navigation(
                  leading: const Icon(Icons.info_outlined),
                  title: Text(S.of(context).about),
                  onPressed: (context) => buildShowAboutPage(context),
                ),
                SettingsTile.navigation(
                  leading: const Icon(Icons.feedback_outlined),
                  title: Text(S.of(context).suggestFeatureOrReportIssue),
                  onPressed: (context) => _openFeedbackUrl(),
                ),
              ],
            ),
            SettingsSection(
              title: Text(S.current.backup),
              tiles: [
                SettingsTile.navigation(
                  leading: const Icon(Icons.save_outlined),
                  title: Text(S.current.createBackup),
                  onPressed: (context) async {
                    await runCreateBackup(context);
                  },
                ),
                SettingsTile.navigation(
                  leading: const Icon(Icons.settings_backup_restore_outlined),
                  title: Text(S.current.restoreBackup),
                  onPressed: (context) async {
                    // 1. Mostra o diálogo de aviso e aguarda a confirmação do usuário.
                    final bool userConfirmed = await _showRestoreConfirmationDialog(context);

                    // 2. Prossiga com a restauração apenas se o usuário confirmou.
                    if (userConfirmed) {
                      // A verificação `mounted` é uma boa prática em `async` callbacks.
                      if (context.mounted) {
                        await runBackupRestore(context);
                      }
                    }
                  },
                ),
              ],
            ),
            // SettingsSection(
            //   title: Text(S.of(context).dangerZone,
            //           style: TextStyle(color: Theme.of(context).brightness == Brightness.light
            //               ? Colors.red
            //               : Colors.redAccent,)),
            //   tiles: [
            //   // Option to delete app data
            //   SettingsTile(
            //       leading: Icon(
            //         const Icons.delete_forever,
            //         color: Theme.of(context).brightness == Brightness.light
            //               ? Colors.red
            //               : Colors.redAccent,
            //       ),
            //       title: Text(S.of(context).deleteAppData,
            //           style: TextStyle(color: Theme.of(context).brightness == Brightness.light
            //               ? Colors.red
            //               : Colors.redAccent,)),
            //       description: Text(S.of(context).deleteAppDataDescription),
            //       onPressed: (context) {
            //         _showDeleteConfirmationDialog(context);
            //       }),
            // ]),
          ],
        ),
      ),
    );
  }

  Future<String?> buildObserverDialog(BuildContext context) async {
    return await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        String observer = '';
        return AlertDialog(
          title: Text(S.of(context).observer),
          content: TextField(
            textCapitalization: TextCapitalization.characters,
            onChanged: (value) {
              observer = value;
            },
            decoration: InputDecoration(
              labelText: S.of(context).observerAbbreviation,
              border: OutlineInputBorder(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(S.of(context).cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(observer),
              child: Text(S.of(context).save),
            ),
          ],
        );
      },
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
                    // RadioListTile<SupportedCountry>(
                    //   title: Text(S.current.countryBrazil),
                    //   value: SupportedCountry.BR,
                    // ),
                    // RadioListTile<SupportedCountry>(
                    //   title: Text(S.current.countryParaguay),
                    //   value: SupportedCountry.PY,
                    // ),
                    // RadioListTile<SupportedCountry>(
                    //   title: Text(S.current.countryUruguay),
                    //   value: SupportedCountry.UY,
                    // ),

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

  Future<void> buildShowAboutPage(BuildContext context) {
    return showAboutPage(
      context: context,
      title: Text(S.of(context).about),
      values: {
        'version': '${_packageInfo?.version}',
        'buildNumber': '${_packageInfo?.buildNumber}',
        'year': '2024-${DateTime.now().year}',
        'author': 'Christian Beier',
      },
      applicationIcon: Image.asset(
        'assets/xolmis_icon.png',
        width: 150,
        height: 150,
      ),
      applicationLegalese: '© {{ year }}  {{ author }}',
      applicationName: _packageInfo?.appName ?? 'Xolmis',
      applicationVersion: '{{ version }}+{{ buildNumber }}',
      applicationDescription: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(S.of(context).platinumSponsor),
          Image.asset('assets/alianza_del_pastizal_logo.png', scale: 3),
        ],
      ),
      children: [
        MarkdownPageListTile(
          icon: const Icon(Icons.list),
          title: Text(S.current.changelog),
          filename: 'assets/changelog.md',
        ),
        MarkdownPageListTile(
          filename: 'assets/license.md',
          title: Text(S.current.viewLicense),
          icon: const Icon(Icons.description),
        ),
        // MarkdownPageListTile(
        //   filename: 'CONTRIBUTING.md',
        //   title: Text('Contributing'),
        //   icon: const Icon(Icons.share),
        // ),
        LicensesPageListTile(
          title: Text(S.current.openSourceLicenses),
          icon: const Icon(Icons.favorite),
        ),
      ],
    );
  }

  /// Abre a URL para feedback, com tratamento de erros.
  void _openFeedbackUrl() async {
    final Uri url = Uri.parse('https://github.com/cbeier-studio/xolmis_mobile/issues');

    // Verifica se o dispositivo pode abrir a URL antes de tentar
    try  {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (e) {
      // Se não puder abrir, mostra uma mensagem de erro para o usuário
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch $url')),
        );
      }
      debugPrint('[SETTINGS] !!! ERROR: Could not launch $url: $e');
    }
  }

  Future<void> runCreateBackup(BuildContext context) async {
    bool isDialogShown = false;
    try {
      final directory = await getDownloadsDirectory();
      final now = DateTime.now();
      final formatter = DateFormat('yyyyMMdd_HHmmss');
      final formattedDate = formatter.format(now);
      final backupFilePath =
          '${directory!.path}/xolmis_backup_$formattedDate.zip';

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext dialogContext) {
            return Dialog(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(width: 20),
                    Text(S.of(dialogContext).backingUpData),
                  ],
                ),
              ),
            );
          },
        );
        isDialogShown = true;
      }

      final success = await backupDatabase(backupFilePath);

      if (isDialogShown && mounted) {
        Navigator.of(context).pop();
        isDialogShown = false;
      }

      if (success) {
        final result = await SharePlus.instance.share(
          ShareParams(
            files: [XFile(backupFilePath, mimeType: 'application/zip')],
            text: S.current.sendBackupTo,
          ),
        );

        if (result.status == ShareResultStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(S.current.backupCreatedAndSharedSuccessfully),
            ),
          );
        }
      } else {
        if (isDialogShown && mounted) {
          Navigator.of(context).pop();
          isDialogShown = false;
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(S.current.errorBackupNotFound)));
      }
    } catch (e) {
      if (isDialogShown && mounted) {
        Navigator.of(context).pop();
        isDialogShown = false;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${S.current.errorCreatingBackup}: ${e.toString()}'),
        ),
      );
    }
  }

  /// Mostra um diálogo de aviso antes de restaurar o backup.
  /// Retorna `true` se o usuário confirmar, `false` caso contrário.
  Future<bool> _showRestoreConfirmationDialog(BuildContext context) async {
    // `showDialog` retorna o valor passado para `Navigator.of(context).pop()`
    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // O usuário deve pressionar um dos botões
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(S.current.warningTitle),
          content: Text(S.current.restoreBackupConfirmation),
          actions: <Widget>[
            // Botão para cancelar a ação
            TextButton(
              child: Text(S.of(context).cancel),
              onPressed: () {
                Navigator.of(context).pop(false); // Retorna 'false'
              },
            ),
            // Botão para confirmar a ação, com destaque
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: Text(S.current.restore),
              onPressed: () {
                Navigator.of(context).pop(true); // Retorna 'true'
              },
            ),
          ],
        );
      },
    );
    // Se o usuário fechar o diálogo de outra forma, `confirmed` pode ser null.
    // Tratamos null como `false`.
    return confirmed ?? false;
  }

  Future<void> runBackupRestore(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );

    if (result != null && result.files.single.path != null) {
      final filePath = result.files.single.path!;
      bool isDialogShown = false;
      try {
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext dialogContext) {
              return Dialog(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 20),
                      Text(S.of(dialogContext).restoringData),
                    ],
                  ),
                ),
              );
            },
          );
          isDialogShown = true;
        }

        final success = await restoreDatabase(filePath);

        if (isDialogShown && mounted) {
          Navigator.of(context).pop();
          isDialogShown = false;
        }

        if (success) {
          if (mounted) {
            showDialog(
              context: context,
              builder: (BuildContext dialogContext) {
                return AlertDialog.adaptive(
                  title: Text(S.of(dialogContext).restoreBackup),
                  content: Text(S.of(dialogContext).backupRestoredSuccessfully),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text(S.of(context).ok),
                    ),
                  ],
                );
              },
            );
          }
        } else {
          if (isDialogShown && mounted) {
            Navigator.of(context).pop();
            isDialogShown = false;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(S.current.errorRestoringBackup)),
          );
        }
      } catch (e) {
        if (isDialogShown && mounted) {
          Navigator.of(context).pop();
          isDialogShown = false;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${S.current.errorRestoringBackup}: ${e.toString()}'),
          ),
        );
      }
    }
  }

  // Future<void> _showDeleteConfirmationDialog(BuildContext context) async {
  //   return showDialog<void>(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog.adaptive(
  //         title: Text(S.of(context).deleteData),
  //         content: Text(S.of(context).deleteDataMessage),
  //         actions: <Widget>[
  //           TextButton(
  //             child: Text(S.of(context).cancel),
  //             onPressed: () {
  //               Navigator.of(context).pop();
  //             },
  //           ),
  //           TextButton(
  //             child: Text(S.of(context).delete),
  //             onPressed: () async {
  //               // Delete the app data
  //               await _deleteAppData();
  //               Navigator.of(context).pop();
  //               ScaffoldMessenger.of(context).showSnackBar(
  //                 SnackBar(content: Text(S.of(context).dataDeleted)),
  //               );
  //             },
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  //   Future<void> _deleteAppData() async {
  //     // 1. Get the database path
  //     var databasesPath = await getDatabasesPath();
  //     String path = join(databasesPath, 'xolmis_database.db');

  //     DatabaseHelper databaseHelper = DatabaseHelper();
  //     await databaseHelper.closeDatabase();

  //     // 2. Delete the database file
  //     await deleteDatabase(path);

  //     // 3. Recreate the database

  //     await databaseHelper.initDatabase();

  //     // 4. Clear other app data, if necessary (ex: SharedPreferences)
  //     // ...
  //   }
}

// Auxiliary widget to select a number
class NumberPickerDialog extends StatefulWidget {
  final int minValue;
  final int maxValue;
  final int initialValue;
  final String title;

  const NumberPickerDialog({
    super.key,
    required this.minValue,
    required this.maxValue,
    required this.initialValue,
    required this.title,
  });

  @override
  State<NumberPickerDialog> createState() => _NumberPickerDialogState();
}

class _NumberPickerDialogState extends State<NumberPickerDialog> {
  int _currentValue = 0;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: NumberPicker(
        value: _currentValue,
        minValue: widget.minValue,
        maxValue: widget.maxValue,
        onChanged: (value) {
          setState(() {
            _currentValue = value;
          });
        },
      ),
      actions: [
        TextButton(
          child: Text(S.of(context).cancel),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        TextButton(
          child: Text(S.of(context).ok),
          onPressed: () {
            Navigator.pop(context, _currentValue);
          },
        ),
      ],
    );
  }
}
