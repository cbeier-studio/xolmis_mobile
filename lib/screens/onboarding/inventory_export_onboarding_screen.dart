import 'package:material_ui/material_ui.dart';

import '../../generated/l10n.dart';

/// Full-screen onboarding that explains the updated inventory export formats.
class InventoryExportOnboardingScreen extends StatelessWidget {
  final VoidCallback onClose;

  /// Creates the inventory export onboarding screen.
  const InventoryExportOnboardingScreen({
    super.key,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final strings = S.of(context);

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(automaticallyImplyLeading: false),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                children: [
                  Icon(
                    Icons.file_download_done_outlined,
                    size: 64,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    strings.inventoryExportOnboardingTitle,
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    strings.inventoryExportOnboardingMessage,
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 12),
                  _OnboardingInfoCard(
                    icon: Icons.table_chart_outlined,
                    title: strings.inventoryExportOnboardingCsvTitle,
                    description:
                        strings.inventoryExportOnboardingCsvDescription,
                  ),
                  const SizedBox(height: 16),
                  _OnboardingInfoCard(
                    icon: Icons.grid_view_outlined,
                    title: strings.inventoryExportOnboardingExcelTitle,
                    description:
                        strings.inventoryExportOnboardingExcelDescription,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    strings.inventoryExportOnboardingSupport,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: onClose,
                    child: Text(strings.inventoryExportOnboardingAction),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact card used to highlight one export format change.
class _OnboardingInfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  /// Creates an informational card for the onboarding screen.
  const _OnboardingInfoCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(description, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


