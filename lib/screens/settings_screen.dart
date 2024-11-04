import 'dart:core';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../data/database/database_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  ThemeMode _themeMode = ThemeMode.system;
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
      _maxSpeciesMackinnon = prefs.getInt('maxSpeciesMackinnon') ?? 10;
      _pointCountsDuration = prefs.getInt('pointCountsDuration') ?? 8;
      _cumulativeTimeDuration = prefs.getInt('cumulativeTimeDuration') ?? 30;
      _observerAcronym = prefs.getString('observerAcronym') ?? '';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', _themeMode.index);
    await prefs.setInt('maxSpeciesMackinnon', _maxSpeciesMackinnon);
    await prefs.setInt('pointCountsDuration', _pointCountsDuration);
    await prefs.setInt('cumulativeTimeDuration', _cumulativeTimeDuration);
    await prefs.setString('observerAcronym', _observerAcronym);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          ListTile(
            leading: const Icon(Icons.dark_mode_outlined),
            title: const Text('Aparência'),
            subtitle: Text(_themeMode.name),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) {
                  return SimpleDialog(
                    title: const Text('Selecione o modo'),
                    children: [
                      SimpleDialogOption(
                        child: const Text('Claro'),
                        onPressed: () {
                          setState(() {
                            _themeMode = ThemeMode.light;
                          });
                          _saveSettings();
                          Navigator.pop(context);
                        },
                      ),
                      SimpleDialogOption(
                        child: const Text('Escuro'),
                        onPressed: () {
                          setState(() {
                            _themeMode = ThemeMode.dark;
                          });
                          _saveSettings();
                          Navigator.pop(context);
                        },
                      ),
                      SimpleDialogOption(
                        child: const Text('Tema do sistema'),
                        onPressed: () {
                          setState(() {
                            _themeMode = ThemeMode.system;
                          });
                          _saveSettings();
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
            title: const Text('Observador (sigla)'),
            subtitle: Text(_observerAcronym),
            onTap: () async {
              String? newObserver = await showDialog<String>(
                context: context,
                builder: (BuildContext context) {
                  String observer = '';
                  return AlertDialog(
                    title: const Text('Observador'),
                    content: TextField(
                      textCapitalization: TextCapitalization.characters,
                      onChanged: (value) {
                        observer = value;
                      },
                      decoration: const InputDecoration(
                        labelText: 'Sigla do observador',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(observer),
                        child: const Text('Salvar'),
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
            leading: const Icon(Icons.checklist_outlined),
            title: const Text('Listas de Mackinnon'),
            subtitle: Text('$_maxSpeciesMackinnon espécies por lista'),
            onTap: () async {
              final newMaxSpecies = await showDialog<int>(
                context: context,
                builder: (context) {
                  return NumberPickerDialog(
                    minValue: 1,
                    maxValue: 50,
                    initialValue: _maxSpeciesMackinnon,
                    title: 'Espécies por lista',
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
            title: const Text('Pontos de contagem'),
            subtitle: Text('$_pointCountsDuration minutos de duração'),
            onTap: () async {
              final newDuration = await showDialog<int>(
                context: context,
                builder: (context) {
                  return NumberPickerDialog(
                    minValue: 1,
                    maxValue: 60,
                    initialValue: _pointCountsDuration,
                    title: 'Duração (min)',
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
            title: const Text('Listas qualitativas temporizadas'),
            subtitle: Text('$_cumulativeTimeDuration minutos de duração'),
            onTap: () async {
              final newDuration = await showDialog<int>(
                context: context,
                builder: (context) {
                  return NumberPickerDialog(
                    minValue: 1,
                    maxValue: 120,
                    initialValue: _cumulativeTimeDuration,
                    title: 'Duração (min)',
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
            title: const Text('Sobre o app'),
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
            leading: const Icon(Icons.warning_outlined, color: Colors.amber,),
            title: const Text('Área perigosa', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),),
            children: [
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red,),
                title: const Text(
                  'Apagar dados do aplicativo',
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
          title: const Text('Apagar dados'),
          content: const Text('Tem certeza que deseja apagar todos os dados do aplicativo? Esta ação não poderá ser desfeita.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Apagar'),
              onPressed: () async {
                // Delete the app data
                await _deleteAppData();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Dados do aplicativo apagados com sucesso!')),
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

    // 2. Delete the database file
    await deleteDatabase(path);

    // 3. Recreate the database
    DatabaseHelper databaseHelper = DatabaseHelper();
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
          child: const Text('Cancelar'),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        TextButton(
          child: const Text('OK'),
          onPressed: () {
            Navigator.pop(context, _currentValue);
          },
        ),
      ],
    );
  }
}