import 'dart:core';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:about/about.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:xolmis/screens/settings/backup_settings.dart';

import '../../generated/l10n.dart';
import 'general_settings.dart';
import 'import_export_settings.dart';
import 'inventory_settings.dart';
import 'observer_settings.dart';
import 'backup_settings.dart';

/// Displays user-configurable application settings and backup actions.
class SettingsScreen extends StatefulWidget {
  /// Creates the settings screen.
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    _setPackageInfo();
  }

  /// Loads package metadata used by the about screen.
  Future<void> _setPackageInfo() async => PackageInfo.fromPlatform().then(
    (PackageInfo packageInfo) => setState(() => _packageInfo = packageInfo),
  );

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
          // lightTheme: SettingsThemeData(
          //   settingsListBackground: ThemeData.light().scaffoldBackgroundColor,
          //   titleTextColor: Colors.deepPurple,
          // ),
          // darkTheme: SettingsThemeData(
          //   settingsListBackground: ThemeData.dark().scaffoldBackgroundColor,
          //   titleTextColor: Colors.deepPurple[300],
          // ),
          sections: [
            SettingsSection(
              tiles: [
                SettingsTile.navigation(
                  // leading: const Icon(Icons.person_outlined),
                  title: Text(S.of(context).generalSettings),
                  description: Text('${S.current.appearance}, ${S.current.startupModule}, ${S.current.speciesSearchCountry}'),
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
                  title: Text(S.of(context).inventorySettings),
                  description: Text('${S.current.limits}, ${S.current.defaults}, ${S.current.reminders}'),
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
                  description: Text('${S.current.importExistingRecords}, ${S.current.formatNumbers}'),
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
                  description: Text('${S.current.createBackup}, ${S.current.restoreBackup}'),
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
                  description: Text('${S.current.version}, ${S.current.changelog}, ${S.current.viewLicense}'),
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

  /// Shows the application about page with version and license information.
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


