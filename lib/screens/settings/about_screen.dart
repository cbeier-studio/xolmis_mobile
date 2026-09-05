import 'package:material_ui/material_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../generated/l10n.dart';
import 'markdown_viewer_screen.dart';

/// Custom about screen to replace the 'about' package implementation.
class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = info;
    });
  }

  @override
  Widget build(BuildContext context) {
    final year = DateTime.now().year;

    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).about),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 24),
            // App Icon
            Center(
              child: Image.asset(
                'assets/xolmis_icon.png',
                width: 120,
                height: 120,
              ),
            ),
            const SizedBox(height: 16),
            // App Name & Version
            Text(
              _packageInfo?.appName ?? 'Xolmis',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            Text(
              '${_packageInfo?.version ?? ''}+${_packageInfo?.buildNumber ?? ''}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            // Legalese
            Text(
              '© 2024-$year Christian Beier',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            const Divider(),
            // Description / Sponsors
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  Text(
                    S.of(context).platinumSponsor,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  Image.asset(
                    'assets/alianza_del_pastizal_logo.png',
                    scale: 3,
                  ),
                ],
              ),
            ),
            const Divider(),
            // Tiles for sub-pages
            ListTile(
              leading: const Icon(Icons.list),
              title: Text(S.current.changelog),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MarkdownViewerScreen(
                      title: S.current.changelog,
                      assetPath: 'assets/changelog.md',
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.description),
              title: Text(S.current.viewLicense),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MarkdownViewerScreen(
                      title: S.current.viewLicense,
                      assetPath: 'assets/license.md',
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.favorite),
              title: Text(S.current.openSourceLicenses),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                showLicensePage(
                  context: context,
                  applicationName: _packageInfo?.appName ?? 'Xolmis',
                  applicationVersion: '${_packageInfo?.version ?? ''}+${_packageInfo?.buildNumber ?? ''}',
                  applicationIcon: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Image.asset(
                      'assets/xolmis_icon.png',
                      width: 60,
                      height: 60,
                    ),
                  ),
                  applicationLegalese: '© 2024-$year Christian Beier',
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
