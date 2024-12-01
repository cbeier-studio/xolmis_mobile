import 'dart:core';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../data/database/database_helper.dart';
import '../utils/themes.dart';
import '../generated/l10n.dart';

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
  int _cumulativeTimeDuration = 30;
  String _observerAcronym = '';
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    _setPackageInfo();
    _loadSettings();
  }

  Future<void> _setPackageInfo() async => PackageInfo.fromPlatform().then(
        (PackageInfo packageInfo) => setState(() => _packageInfo = packageInfo),
  );

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _themeMode = ThemeMode.values[prefs.getInt('themeMode') ?? 0];
      _maxSimultaneousInventories = prefs.getInt('maxSimultaneousInventories') ?? 2;
      _maxSpeciesMackinnon = prefs.getInt('maxSpeciesMackinnon') ?? 10;
      _pointCountsDuration = prefs.getInt('pointCountsDuration') ?? 8;
      _cumulativeTimeDuration = prefs.getInt('cumulativeTimeDuration') ?? 30;
      _observerAcronym = prefs.getString('observerAcronym') ?? '';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', _themeMode.index);
    await prefs.setInt('maxSimultaneousInventories', _maxSimultaneousInventories);
    await prefs.setInt('maxSpeciesMackinnon', _maxSpeciesMackinnon);
    await prefs.setInt('pointCountsDuration', _pointCountsDuration);
    await prefs.setInt('cumulativeTimeDuration', _cumulativeTimeDuration);
    await prefs.setString('observerAcronym', _observerAcronym);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).settings),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          ListTile(
            leading: const Icon(Icons.dark_mode_outlined),
            title: Text(S.of(context).appearance),
            subtitle: Text(_themeMode.name),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) {
                  return SimpleDialog(
                    title: Text(S.of(context).selectMode),
                    children: [
                      SimpleDialogOption(
                        child: Text(S.of(context).lightMode),
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
                        child: Text(S.of(context).darkMode),
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
                        child: Text(S.of(context).systemMode),
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
            },
          ),
          Divider(),
          ListTile(
            leading: const Icon(Icons.person_outlined),
            title: Text(S.of(context).observerSetting),
            subtitle: Text(_observerAcronym),
            onTap: () async {
              String? newObserver = await showDialog<String>(
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
                        labelText: S.of(context).observerAcronym,
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

              if (newObserver != null && newObserver.isNotEmpty) {
                setState(() {
                  _observerAcronym = newObserver;
                });
                _saveSettings();
              }
            },
          ),
          Divider(),
          ListTile(
            leading: const Icon(Icons.list_alt_outlined),
            title: Text(S.of(context).simultaneousInventories),
            subtitle: Text('$_maxSimultaneousInventories ${S.of(context).inventory(_maxSimultaneousInventories)}'),
            onTap: () async {
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
          ListTile(
            leading: const Icon(Icons.checklist_outlined),
            title: Text(S.of(context).mackinnonLists),
            subtitle: Text(S.of(context).speciesPerList(_maxSpeciesMackinnon)),
            onTap: () async {
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
          ListTile(
            leading: const Icon(Icons.timer_outlined),
            title: Text(S.of(context).pointCounts),
            subtitle: Text(S.of(context).inventoryDuration(_pointCountsDuration)),
            onTap: () async {
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
          ListTile(
            leading: const Icon(Icons.timer_outlined),
            title: Text(S.of(context).timedQualitativeLists),
            subtitle: Text(S.of(context).inventoryDuration(_cumulativeTimeDuration)),
            onTap: () async {
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
          Divider(),
          ListTile(
            leading: const Icon(Icons.info_outlined),
            title: Text(S.of(context).about),
            onTap: () => showLicensePage(
              context: context,
              applicationIcon: Image.asset(
                'assets/xolmis_icon.png',
                scale: 3,
              ),
              applicationLegalese: '© ${DateTime.now().year} Christian Beier',
              applicationName: _packageInfo?.appName ?? 'Xolmis',
              applicationVersion: _packageInfo?.version ?? '',
            ),
          ),
          Divider(),
          ExpansionTile(
            title: Text(S.of(context).dangerZone, style: TextStyle(fontSize: 16,),),
            children: [
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red,),
                title: Text(
                  S.of(context).deleteAppData,
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  _showDeleteConfirmationDialog(context);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteConfirmationDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(S.of(context).deleteData),
          content: Text(S.of(context).deleteDataMessage),
          actions: <Widget>[
            TextButton(
              child: Text(S.of(context).cancel),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(S.of(context).delete),
              onPressed: () async {
                // Delete the app data
                await _deleteAppData();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(S.of(context).dataDeleted)),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAppData() async {
    // 1. Get the database path
    var databasesPath = await getDatabasesPath();
    String path = join(databasesPath, 'xolmis_database.db');

    DatabaseHelper databaseHelper = DatabaseHelper();
    await databaseHelper.closeDatabase();

    // 2. Delete the database file
    await deleteDatabase(path);

    // 3. Recreate the database

    await databaseHelper.initDatabase();

    // 4. Clear other app data, if necessary (ex: SharedPreferences)
    // ...
  }
}

// Auxiliary widget to select a number
class NumberPickerDialog extends StatefulWidget {
  final int minValue;
  final int maxValue;
  final int initialValue;
  final String title;

  const NumberPickerDialog({
    Key? key,
    required this.minValue,
    required this.maxValue,
    required this.initialValue,
    required this.title,
  }) : super(key: key);

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