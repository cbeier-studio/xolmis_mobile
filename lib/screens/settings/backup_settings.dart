import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

import '../../utils/backup_utils.dart';
import '../../generated/l10n.dart';

class BackupSettings extends StatefulWidget {
  const BackupSettings({super.key});

  @override
  State<BackupSettings> createState() => _BackupSettingsState();
}

class _BackupSettingsState extends State<BackupSettings> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.current.backup),
      ),
      body: SettingsList(
        contentPadding: EdgeInsets.zero,
        crossAxisAlignment: CrossAxisAlignment.start,
        applicationType: ApplicationType.material,
        platform: DevicePlatform.android,
        sections: [
          SettingsSection(
            tiles: [
              SettingsTile(
                leading: const Icon(Icons.save_outlined),
                title: Text(S.current.createBackup),
                description: Text(S.current.createBackupDescription),
                onPressed: (context) async {
                  await runCreateBackup(context);
                },
              ),
            ],
          ),
          SettingsSection(
            tiles: [
              SettingsTile(
                leading: const Icon(Icons.settings_backup_restore_outlined),
                title: Text(S.current.restoreBackup),
                description: Text(S.current.restoreBackupDescription),
                onPressed: (context) async {
                  // 1. Mostra o diálogo de aviso e aguarda a confirmação do usuário.
                  final bool userConfirmed = await _showRestoreConfirmationDialog(context);

                  // 2. Prossiga com a restauração apenas se o usuário confirmou.
                  if (userConfirmed) {
                    // A verificação `mounted` é uma boa prática em `async` callbacks.
                    if (context.mounted) {
                      await runBackupRestore(context);
                    }
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Creates a ZIP backup and opens the share sheet for the generated file.
  Future<void> runCreateBackup(BuildContext context) async {
    bool isDialogShown = false;
    try {
      final directory = await getTemporaryDirectory();
      final now = DateTime.now();
      final formatter = DateFormat('yyyyMMdd_HHmmss');
      final formattedDate = formatter.format(now);
      final backupFilePath =
          '${directory!.path}/xolmis_backup_$formattedDate.zip';

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext dialogContext) {
            return Dialog(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(width: 20),
                    Text(S.of(dialogContext).backingUpData),
                  ],
                ),
              ),
            );
          },
        );
        isDialogShown = true;
      }

      final success = await backupDatabase(backupFilePath);

      if (isDialogShown && mounted) {
        Navigator.of(context).pop();
        isDialogShown = false;
      }

      if (success) {
        final result = await SharePlus.instance.share(
          ShareParams(
            files: [XFile(backupFilePath, mimeType: 'application/zip')],
            text: S.current.sendBackupTo,
          ),
        );

        if (result.status == ShareResultStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.green,
              content: Text(S.current.backupCreatedAndSharedSuccessfully),
            ),
          );
        }
      } else {
        if (isDialogShown && mounted) {
          Navigator.of(context).pop();
          isDialogShown = false;
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
            SnackBar(
                persist: true,
                showCloseIcon: true,
                backgroundColor: Theme.of(context).colorScheme.error,
                content: Text(S.current.errorBackupNotFound)
            )
        );
      }
    } catch (e) {
      if (isDialogShown && mounted) {
        Navigator.of(context).pop();
        isDialogShown = false;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          persist: true,
          showCloseIcon: true,
          backgroundColor: Theme.of(context).colorScheme.error,
          content: Text('${S.current.errorCreatingBackup}: ${e.toString()}'),
        ),
      );
    }
  }

  /// Shows a confirmation dialog before starting the backup restore flow.
  ///
  /// Returns `true` when the user confirms and `false` otherwise.
  Future<bool> _showRestoreConfirmationDialog(BuildContext context) async {
    // `showDialog` retorna o valor passado para `Navigator.of(context).pop()`
    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // O usuário deve pressionar um dos botões
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(S.current.restoreBackup),
          content: Text(S.current.restoreBackupConfirmation),
          actions: <Widget>[
            // Botão para cancelar a ação
            TextButton(
              child: Text(S.of(context).cancel),
              onPressed: () {
                Navigator.of(context).pop(false); // Retorna 'false'
              },
            ),
            // Botão para confirmar a ação, com destaque
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: Text(S.current.restore),
              onPressed: () {
                Navigator.of(context).pop(true); // Retorna 'true'
              },
            ),
          ],
        );
      },
    );
    // Se o usuário fechar o diálogo de outra forma, `confirmed` pode ser null.
    // Tratamos null como `false`.
    return confirmed ?? false;
  }

  /// Restores app data from a backup ZIP selected by the user.
  Future<void> runBackupRestore(BuildContext context) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );

    if (result != null && result.files.single.path != null) {
      final filePath = result.files.single.path!;
      bool isDialogShown = false;
      try {
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext dialogContext) {
              return Dialog(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 20),
                      Text(S.of(dialogContext).restoringData),
                    ],
                  ),
                ),
              );
            },
          );
          isDialogShown = true;
        }

        final success = await restoreDatabase(filePath);

        if (isDialogShown && mounted) {
          Navigator.of(context).pop();
          isDialogShown = false;
        }

        if (success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                showCloseIcon: true,
                backgroundColor: Colors.green,
                content: Text(S.of(context).backupRestoredSuccessfully),
              ),
            );
          }
        } else {
          if (isDialogShown && mounted) {
            Navigator.of(context).pop();
            isDialogShown = false;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                persist: true,
                showCloseIcon: true,
                backgroundColor: Theme.of(context).colorScheme.error,
                content: Text(S.current.errorRestoringBackup)),
          );
        }
      } catch (e) {
        if (isDialogShown && mounted) {
          Navigator.of(context).pop();
          isDialogShown = false;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            persist: true,
            showCloseIcon: true,
            backgroundColor: Theme.of(context).colorScheme.error,
            content: Text('${S.current.errorRestoringBackup}: ${e.toString()}'),
          ),
        );
      }
    }
  }
}
