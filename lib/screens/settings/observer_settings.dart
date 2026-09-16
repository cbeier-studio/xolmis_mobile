import 'package:material_ui/material_ui.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/themes.dart';
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
        brightness: Theme.of(context).brightness,
        lightTheme: getSettingsLightTheme(context),
        darkTheme: getSettingsDarkTheme(context),
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
      builder: (BuildContext dialogContext) {
        return _ObserverDialogContent(initialValue: _observerAbbreviation);
      },
    );
  }
}

class _ObserverDialogContent extends StatefulWidget {
  final String initialValue;
  const _ObserverDialogContent({required this.initialValue});

  @override
  State<_ObserverDialogContent> createState() => _ObserverDialogContentState();
}

class _ObserverDialogContentState extends State<_ObserverDialogContent> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(S.of(context).observer),
      content: TextField(
        controller: _controller,
        textCapitalization: TextCapitalization.characters,
        decoration: InputDecoration(
          labelText: S.of(context).observerAbbreviation,
          border: const OutlineInputBorder(),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(S.of(context).cancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: Text(S.of(context).save),
        ),
      ],
    );
  }
}
