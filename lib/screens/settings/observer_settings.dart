import 'package:flutter/material.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../generated/l10n.dart';

class ObserverSettings extends StatefulWidget {
  const ObserverSettings({super.key});

  @override
  State<ObserverSettings> createState() => _ObserverSettingsState();
}

class _ObserverSettingsState extends State<ObserverSettings> {
  String _observerAbbreviation = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  /// Loads persisted settings from shared preferences into local state.
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _observerAbbreviation = prefs.getString('observerAcronym') ?? '';
    });
  }

  /// Persists the current in-memory settings to shared preferences.
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('observerAcronym', _observerAbbreviation);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.current.observersSettings),
      ),
      body: SettingsList(
        contentPadding: EdgeInsets.zero,
        crossAxisAlignment: CrossAxisAlignment.start,
        applicationType: ApplicationType.material,
        platform: DevicePlatform.android,
        sections: [
          SettingsSection(
            title: Text(S.current.defaultObserver.toUpperCase()),
            tiles: [
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
        ],
      ),
    );
  }

  /// Shows a dialog to edit the observer abbreviation stored in settings.
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
}
