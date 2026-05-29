import 'package:flutter/material.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/core_consts.dart';
import '../../generated/l10n.dart';

class ImportExportSettings extends StatefulWidget {
  const ImportExportSettings({super.key});

  @override
  State<ImportExportSettings> createState() => _ImportExportSettingsState();
}

class _ImportExportSettingsState extends State<ImportExportSettings> {
  bool _formatNumbers = true;
  /// Selected policy index for handling existing records during imports.
  int _importExistingRecordPolicyIndex =
      ImportExistingRecordPolicy.askEveryTime.index;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  /// Loads persisted settings from shared preferences into local state.
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _formatNumbers = prefs.getBool('formatNumbers') ?? true;
      _importExistingRecordPolicyIndex =
          prefs.getInt(kImportExistingRecordsPolicyPreferenceKey) ??
              ImportExistingRecordPolicy.askEveryTime.index;

      if (_importExistingRecordPolicyIndex < 0 ||
          _importExistingRecordPolicyIndex >=
              ImportExistingRecordPolicy.values.length) {
        _importExistingRecordPolicyIndex =
            ImportExistingRecordPolicy.askEveryTime.index;
      }
    });
  }

  /// Persists the current in-memory settings to shared preferences.
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('formatNumbers', _formatNumbers);
    await prefs.setInt(
      kImportExistingRecordsPolicyPreferenceKey,
      _importExistingRecordPolicyIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.current.importExportSettings),
      ),
      body: SettingsList(
        contentPadding: EdgeInsets.zero,
        crossAxisAlignment: CrossAxisAlignment.start,
        applicationType: ApplicationType.material,
        platform: DevicePlatform.android,
        sections: [
          SettingsSection(
            title: Text(S.current.import.toUpperCase()),
            tiles: [
              SettingsTile.navigation(
                leading: const Icon(Icons.find_replace_outlined),
                title: Text(S.of(context).importExistingRecords),
                value: Text(
                  _getImportExistingRecordPolicyLabel(
                    context,
                    _importExistingRecordPolicyIndex,
                  ),
                ),
                onPressed: (context) async {
                  final selectedPolicy =
                  await _showImportConflictPolicySelectionDialog(context);

                  if (selectedPolicy != null &&
                      selectedPolicy != _importExistingRecordPolicyIndex) {
                    setState(() {
                      _importExistingRecordPolicyIndex = selectedPolicy;
                    });
                    await _saveSettings();
                  }
                },
              ),
            ],
          ),
          SettingsSection(
            title: Text(S.current.export.toUpperCase()),
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
        ],
      ),
    );
  }

  /// Returns the localized label for an import conflict policy index.
  String _getImportExistingRecordPolicyLabel(
      BuildContext context,
      int policyIndex,
      ) {
    switch (ImportExistingRecordPolicy.values[policyIndex]) {
      case ImportExistingRecordPolicy.askEveryTime:
        return S.of(context).importPolicyAskEveryTime;
      case ImportExistingRecordPolicy.updateExisting:
        return S.of(context).importPolicyUpdateExisting;
      case ImportExistingRecordPolicy.skipExisting:
        return S.of(context).importPolicySkipExisting;
    }
  }

  /// Shows a dialog to choose how imports handle existing records.
  Future<int?> _showImportConflictPolicySelectionDialog(
      BuildContext context,
      ) async {
    int tempSelectedPolicy = _importExistingRecordPolicyIndex;

    return showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(S.of(context).importExistingRecords),
              content: SingleChildScrollView(
                child: RadioGroup<int>(
                  groupValue: tempSelectedPolicy,
                  onChanged: (int? value) {
                    if (value == null) return;
                    setDialogState(() {
                      tempSelectedPolicy = value;
                    });
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RadioListTile<int>(
                        title: Text(S.of(context).importPolicyAskEveryTime),
                        value: ImportExistingRecordPolicy.askEveryTime.index,
                      ),
                      RadioListTile<int>(
                        title: Text(S.of(context).importPolicyUpdateExisting),
                        value: ImportExistingRecordPolicy.updateExisting.index,
                      ),
                      RadioListTile<int>(
                        title: Text(S.of(context).importPolicySkipExisting),
                        value: ImportExistingRecordPolicy.skipExisting.index,
                      ),
                    ],
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
                  onPressed: () => Navigator.of(context).pop(tempSelectedPolicy),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
