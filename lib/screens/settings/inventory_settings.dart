import 'package:flutter/material.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:numberpicker/numberpicker.dart';

import '../../generated/l10n.dart';

class InventorySettings extends StatefulWidget {
  const InventorySettings({super.key});

  @override
  State<InventorySettings> createState() => _InventorySettingsState();
}

class _InventorySettingsState extends State<InventorySettings> {
  int _maxSimultaneousInventories = 2;
  int _maxSpeciesMackinnon = 10;
  int _pointCountsDuration = 8;
  int _cumulativeTimeDuration = 45;
  int _intervalsDuration = 10;
  bool _remindVegetationEmpty = false;
  bool _remindWeatherEmpty = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  /// Loads persisted settings from shared preferences into local state.
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _maxSimultaneousInventories =
          prefs.getInt('maxSimultaneousInventories') ?? 3;
      _maxSpeciesMackinnon = prefs.getInt('maxSpeciesMackinnon') ?? 10;
      _pointCountsDuration = prefs.getInt('pointCountsDuration') ?? 8;
      _cumulativeTimeDuration = prefs.getInt('cumulativeTimeDuration') ?? 45;
      _intervalsDuration = prefs.getInt('intervalsDuration') ?? 10;
      _remindVegetationEmpty = prefs.getBool('remindVegetationEmpty') ?? false;
      _remindWeatherEmpty = prefs.getBool('remindWeatherEmpty') ?? false;
    });
  }

  /// Persists the current in-memory settings to shared preferences.
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('maxSimultaneousInventories', _maxSimultaneousInventories);
    await prefs.setInt('maxSpeciesMackinnon', _maxSpeciesMackinnon);
    await prefs.setInt('pointCountsDuration', _pointCountsDuration);
    await prefs.setInt('cumulativeTimeDuration', _cumulativeTimeDuration);
    await prefs.setInt('intervalsDuration', _intervalsDuration);
    await prefs.setBool('remindVegetationEmpty', _remindVegetationEmpty);
    await prefs.setBool('remindWeatherEmpty', _remindWeatherEmpty);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.current.inventorySettings),
      ),
      body: SettingsList(
        contentPadding: EdgeInsets.zero,
        crossAxisAlignment: CrossAxisAlignment.start,
        applicationType: ApplicationType.material,
        platform: DevicePlatform.android,
        sections: [
          SettingsSection(
            title: Text(S.current.limits.toUpperCase()),
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
            ],
          ),
          SettingsSection(
            title: Text(S.current.defaults.toUpperCase()),
              tiles: [
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
          ]),
          SettingsSection(
            title: Text(S.current.reminders.toUpperCase()),
              tiles: [
                SettingsTile.switchTile(
                  title: Text(S.of(context).remindMissingVegetationData),
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
                  leading: const Icon(Icons.notification_important_outlined),
                  initialValue: _remindWeatherEmpty,
                  onToggle: (bool value) {
                    setState(() {
                      _remindWeatherEmpty = value;
                    });
                    _saveSettings();
                  },
                ),
              ])
        ],
      ),
    );
  }
}

/// Dialog widget that lets the user pick a number from a bounded range.
class NumberPickerDialog extends StatefulWidget {
  final int minValue;
  final int maxValue;
  final int initialValue;
  final String title;

  /// Creates a number picker dialog.
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
