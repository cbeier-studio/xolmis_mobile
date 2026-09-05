import 'dart:core';
import 'package:material_ui/material_ui.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../utils/themes.dart';
import '../../generated/l10n.dart';
import 'general_settings.dart';
import 'import_export_settings.dart';
import 'inventory_settings.dart';
import 'observer_settings.dart';
import 'backup_settings.dart';
import 'about_screen.dart';

/// Displays user-configurable application settings and backup actions.
class SettingsScreen extends StatefulWidget {
  /// Creates the settings screen.
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.of(context).settings)),
      body: SafeArea(
        child: SettingsList(
          // side_sheet keeps the original MediaQuery width from the root route.
          // Disable automatic 810px centering/padding so content fills the sheet.
          contentPadding: EdgeInsets.zero,
          crossAxisAlignment: CrossAxisAlignment.start,
          applicationType: ApplicationType.material,
          platform: DevicePlatform.android,
          brightness: Theme.of(context).brightness,
          lightTheme: getSettingsLightTheme(context),
          darkTheme: getSettingsDarkTheme(context),
          sections: [
            SettingsSection(
              tiles: [
                SettingsTile.navigation(
                  // leading: const Icon(Icons.person_outlined),
                  title: Text(S.of(context).generalSettings),
                  description: Text('${S.current.appearance} • ${S.current.startupModule} • ${S.current.speciesSearchCountry} • ${S.current.tags}'),
                  onPressed: (context) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const GeneralSettings(),
                      ),
                    );
                  },
                ),
                // Observers
                SettingsTile.navigation(
                  // leading: const Icon(Icons.person_outlined),
                  title: Text(S.of(context).observersSettings),
                  description: Text(S.current.defaultObserver),
                  onPressed: (context) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ObserverSettings(),
                      ),
                    );
                  },
                ),
                SettingsTile.navigation(
                  // leading: const Icon(Icons.person_outlined),
                  title: Text(S.of(context).inventories),
                  description: Text('${S.current.inventoryRules} • ${S.current.defaults} • ${S.current.reminders}'),
                  onPressed: (context) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const InventorySettings(),
                      ),
                    );
                  },
                ),
                SettingsTile.navigation(
                  // leading: const Icon(Icons.person_outlined),
                  title: Text(S.of(context).importExportSettings),
                  description: Text('${S.current.importExistingRecords} • ${S.current.formatNumbers}'),
                  onPressed: (context) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ImportExportSettings(),
                      ),
                    );
                  },
                ),
                SettingsTile.navigation(
                  // leading: const Icon(Icons.person_outlined),
                  title: Text(S.of(context).backup),
                  description: Text('${S.current.createBackup} • ${S.current.restoreBackup}'),
                  onPressed: (context) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BackupSettings(),
                      ),
                    );
                  },
                ),
              ],
            ),
            SettingsSection(
              // title: Text(S.of(context).general.toUpperCase()),
              tiles: [
                // About the app
                SettingsTile.navigation(
                  // leading: const Icon(Icons.info_outlined),
                  title: Text(S.of(context).about),
                  description: Text('${S.current.version} • ${S.current.changelog} • ${S.current.viewLicense}'),
                  onPressed: (context) => buildShowAboutPage(context),
                ),
                SettingsTile.navigation(
                  // leading: const Icon(Icons.feedback_outlined),
                  title: Text(S.of(context).suggestFeatureOrReportIssue),
                  description: Text(S.current.giveFeedbackOnGitHub),
                  onPressed: (context) => _openFeedbackUrl(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> buildShowAboutPage(BuildContext context) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AboutScreen(),
      ),
    );
  }

  /// Opens the feedback issue tracker URL and reports launch errors.
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
}


