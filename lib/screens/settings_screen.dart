import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:numberpicker/numberpicker.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  ThemeMode _themeMode = ThemeMode.system;
  int _maxSpeciesMackinnon = 10;
  int _countingPointDuration = 8; // em minutos
  int _cumulativeTimeDuration = 30; // em minutos

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _themeMode = ThemeMode.values[prefs.getInt('themeMode') ?? 0];
      _maxSpeciesMackinnon = prefs.getInt('maxSpeciesMackinnon') ?? 10;
      _countingPointDuration = prefs.getInt('countingPointDuration') ?? 8;
      _cumulativeTimeDuration = prefs.getInt('cumulativeTimeDuration') ?? 30;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', _themeMode.index);
    await prefs.setInt('maxSpeciesMackinnon', _maxSpeciesMackinnon);
    await prefs.setInt('countingPointDuration', _countingPointDuration);
    await prefs.setInt('cumulativeTimeDuration', _cumulativeTimeDuration);
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
            title: const Text('Tema'),
            subtitle: Text(_themeMode.name),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) {
                  return SimpleDialog(
                    title: const Text('Selecione o tema'),
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
                        child: const Text('Sistema'),
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
          ListTile(
            title: const Text('Máximo de espécies (Mackinnon)'),
            subtitle: Text('$_maxSpeciesMackinnon spp.'),
            onTap: () async {
              final newMaxSpecies = await showDialog<int>(
                context: context,
                builder: (context) {
                  return NumberPickerDialog(
                    minValue: 1,
                    maxValue: 50,
                    initialValue: _maxSpeciesMackinnon,
                    title: 'Máximo de espécies',
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
            title: const Text('Duração dos pontos de contagem'),
            subtitle: Text('$_countingPointDuration minutos'),
            onTap: () async {
              final newDuration = await showDialog<int>(
                context: context,
                builder: (context) {
                  return NumberPickerDialog(
                    minValue: 1,
                    maxValue: 60,
                    initialValue: _countingPointDuration,
                    title: 'Duração dos pontos de contagem',
                  );
                },
              );
              if (newDuration != null) {
                setState(() {
                  _countingPointDuration = newDuration;
                });
                _saveSettings();
              }
            },
          ),
          ListTile(
            title: const Text('Duração do inventário (Tempo Cumulativo)'),
            subtitle: Text('$_cumulativeTimeDuration minutos'),
            onTap: () async {
              final newDuration = await showDialog<int>(
                context: context,
                builder: (context) {
                  return NumberPickerDialog(
                    minValue: 1,
                    maxValue: 120,
                    initialValue: _cumulativeTimeDuration,
                    title: 'Duração do inventário',
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
        ],
      ),
    );
  }
}

// Widget auxiliar para selecionar um número
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