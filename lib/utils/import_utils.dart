import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xolmis/generated/l10n.dart';

import '../core/core_consts.dart';
import '../data/models/inventory.dart';
import '../data/models/journal.dart';
import '../data/models/nest.dart';
import '../data/models/specimen.dart';

import '../providers/inventory_provider.dart';
import '../providers/journal_provider.dart';
import '../providers/nest_provider.dart';
import '../providers/specimen_provider.dart';
import 'export_utils.dart';

/// Loads the persisted import-conflict behavior from shared preferences.
///
/// Falls back to [ImportExistingRecordPolicy.askEveryTime] when the value is
/// missing or out of bounds.
Future<ImportExistingRecordPolicy> _getImportConflictPolicy() async {
  final prefs = await SharedPreferences.getInstance();
  final savedPolicyIndex =
      prefs.getInt(kImportExistingRecordsPolicyPreferenceKey) ??
      ImportExistingRecordPolicy.askEveryTime.index;

  if (savedPolicyIndex < 0 ||
      savedPolicyIndex >= ImportExistingRecordPolicy.values.length) {
    return ImportExistingRecordPolicy.askEveryTime;
  }

  return ImportExistingRecordPolicy.values[savedPolicyIndex];
}

/// Resolves whether existing records should be updated for the current import.
///
/// Returns `true` to update conflicts, `false` to skip conflicting records, and
/// `null` when the user cancels from the confirmation dialog.
Future<bool?> _resolveUpdateExistingDecision(
  BuildContext context,
  int conflictsCount,
) async {
  if (conflictsCount <= 0) {
    return true;
  }

  final policy = await _getImportConflictPolicy();
  switch (policy) {
    case ImportExistingRecordPolicy.updateExisting:
      return true;
    case ImportExistingRecordPolicy.skipExisting:
      return false;
    case ImportExistingRecordPolicy.askEveryTime:
      if (!context.mounted) return null;
      return await showDialog<bool>(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: Text(S.of(dialogContext).importConflictDialogTitle),
            content: Text(
              S.of(dialogContext).importConflictDialogMessage(conflictsCount),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(S.of(dialogContext).cancel),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(S.of(dialogContext).importConflictDialogSkipAction),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(
                  S.of(dialogContext).importConflictDialogUpdateAction,
                ),
              ),
            ],
          );
        },
      );
  }
}

/// Builds a localized import summary message including conflict outcomes.
///
/// Uses [successFallback] when there were no updates, skips, or errors.
String _buildImportSummaryMessage(
  BuildContext context, {
  required int newCount,
  required int updatedCount,
  required int skippedCount,
  required int errorsCount,
  required String successFallback,
}) {
  if (updatedCount == 0 && skippedCount == 0 && errorsCount == 0) {
    return successFallback;
  }

  return S.of(context).importCompletedSummary(
    newCount,
    updatedCount,
    skippedCount,
    errorsCount,
  );
}

/// Imports inventory records from an exported JSON file selected by the user.
///
/// The selected file must use the shared export envelope defined by
/// `kExportSource` and contain the `inventories` schema. Valid records are
/// deserialized into [Inventory] instances and imported through
/// [InventoryProvider], while malformed entries are collected and reported in
/// the final feedback shown to the user.
///
/// A modal progress dialog is displayed during the operation and completion or
/// error states are surfaced with `SnackBar`s.
///
/// The [context] is used to obtain localized strings, access the provider, and
/// show UI feedback. The method guards against using the context after it is no
/// longer mounted.
Future<void> importInventoryFromJson(BuildContext context) async {
  bool isDialogShown = false;
  int newImportedCount = 0;
  int updatedCount = 0;
  int skippedCount = 0;
  int totalInventoriesToImport = 0;
  List<String> importErrors = [];
  
  try {
    // Pick a JSON file
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    // If no file was selected, exit without error
    if (result == null || result.files.single.path == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            showCloseIcon: true,
            content: Text(S.current.noFileSelected)),
        );
      }
      return;
    }

    final filePath = result.files.single.path!;
    final file = File(filePath);

    // Show a loading dialog
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 16),
                  Text(S.current.importingInventory),
                ],
              ),
            ),
          );
        },
      );
      isDialogShown = true;
    }

    // Read the JSON file
    final jsonString = await file.readAsString();
    final jsonData = jsonDecode(jsonString);

    if (jsonData is Map<String, dynamic>) {
      if (jsonData['source'] != kExportSource) {
        throw FormatException(S.current.invalidJsonSource);
      }
      if (jsonData['schema'] != 'inventories') {
        throw FormatException(S.current.invalidJsonSchema);
      }
    }

    // Get the provider BEFORE trying to use context
    late InventoryProvider inventoryProvider;
    if (context.mounted) {
      inventoryProvider = Provider.of<InventoryProvider>(context, listen: false);
    } else {
      // If context was unmounted, we cannot use the provider
      // Close dialog if shown and exit
      if (isDialogShown && context.mounted) {
        Navigator.of(context).pop();
      }
      debugPrint('Context unmounted during file reading');
      return;
    }

    List<Inventory> inventoriesToImport = [];

    if (jsonData is Map<String, dynamic> && jsonData.containsKey('records') && jsonData['records'] is List) {
      // Case: JSON has a key "records" and it's a list
      final List<dynamic> inventoriesJsonList = jsonData['records'];
      totalInventoriesToImport = inventoriesJsonList.length;
      for (final item in inventoriesJsonList) {
        if (item is Map<String, dynamic>) {
          try {
            inventoriesToImport.add(Inventory.fromJson(item));
          } catch (e) {
            importErrors.add(S.current.errorParsingInventoriesArrayItem(item.toString(), e.toString()));
          }
        } else {
          importErrors.add(S.current.errorUnexpectedInventoriesArrayItem(item.toString()));
        }
      }
    } else {
      throw FormatException(S.current.invalidJsonFormatExpectedObjectOrArray);
    }

    // If there were no items in the JSON at all
    if (totalInventoriesToImport == 0) {
      if (isDialogShown && context.mounted) {
        Navigator.of(context).pop();
        isDialogShown = false;
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            showCloseIcon: true,
            content: Text(S.current.noInventoriesFoundInFile)),
        );
      }
      return;
    }

    // If the file had items but none parsed into valid Inventory objects
    if (inventoriesToImport.isEmpty) {
      if (isDialogShown && context.mounted) {
        Navigator.of(context).pop();
        isDialogShown = false;
      }
      if (context.mounted) {
        final errorCount = importErrors.length;
        final message = errorCount > 0
            ? S.current.importCompletedWithErrors(0, errorCount)
            : S.current.noValidInventoriesFoundInFile;
        if (importErrors.isNotEmpty) debugPrint("Import errors: \n${importErrors.join('\n')}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            showCloseIcon: true,
            backgroundColor: errorCount > 0
              ? Theme.of(context).colorScheme.error
              : Colors.green,
            content: Text(message), duration: Duration(seconds: 4)),
        );
      }
      return;
    }

    final Set<String> conflictingInventoryIds = <String>{};
    for (final inventory in inventoriesToImport) {
      final exists = await inventoryProvider.inventoryIdExists(inventory.id);
      if (exists) {
        conflictingInventoryIds.add(inventory.id);
      }
    }

    final bool? shouldUpdateExisting = await _resolveUpdateExistingDecision(
      context,
      conflictingInventoryIds.length,
    );

    if (shouldUpdateExisting == null) {
      if (isDialogShown && context.mounted) {
        Navigator.of(context).pop();
        isDialogShown = false;
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            showCloseIcon: true,
            content: Text(S.current.importCancelled),
          ),
        );
      }
      return;
    }

    // Save the inventory to the database
    for (final inventory in inventoriesToImport) {
      try {
        final isExisting = conflictingInventoryIds.contains(inventory.id);
        if (isExisting && !shouldUpdateExisting) {
          skippedCount++;
          continue;
        }

        final success = await inventoryProvider.importInventory(
          inventory,
          updateExisting: shouldUpdateExisting,
        );
        if (success) {
          if (isExisting) {
            updatedCount++;
          } else {
            newImportedCount++;
          }
        } else {
          importErrors.add(S.current.failedToImportInventoryWithId(inventory.id));
        }
      } catch (e) {
        importErrors.add(S.current.errorImportingInventoryWithId(inventory.id, e.toString()));
      }
    }

    // Close the loading dialog
    if (isDialogShown && context.mounted) {
      Navigator.of(context).pop();
      isDialogShown = false;
    }

    // Show import summary
    if (context.mounted) {
      final summaryMessage = _buildImportSummaryMessage(
        context,
        newCount: newImportedCount,
        updatedCount: updatedCount,
        skippedCount: skippedCount,
        errorsCount: importErrors.length,
        successFallback:
            S.current.inventoriesImportedSuccessfully(newImportedCount),
      );
      if (importErrors.isNotEmpty) {
        debugPrint("Import errors: \n${importErrors.join('\n')}");
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          showCloseIcon: true,
          backgroundColor: importErrors.isNotEmpty
            ? Theme.of(context).colorScheme.error
            : Colors.green,
          content: Text(summaryMessage),
          duration: Duration(seconds: importErrors.isEmpty ? 2 : 5),
        ),
      );
    }
  } catch (error) {
    debugPrint('Error importing inventory: $error');
    if (isDialogShown && context.mounted) {
      Navigator.of(context).pop();
      isDialogShown = false;
    }

    if (context.mounted) {
      String errorMessage = '${S.current.errorImportingInventory}: ${error.toString()}';
      if (error is FormatException) {
        errorMessage = S.current.errorImportingInventoryWithFormatError(error.message);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          persist: true,
              showCloseIcon: true,
          backgroundColor: Theme.of(context).colorScheme.error,
          content: Text(errorMessage),
          duration: Duration(seconds: 5),
        ),
      );
    }
  } finally {
    // Ensure the dialog is always closed if it was shown
    if (isDialogShown && context.mounted) {
      Navigator.of(context).pop();
    }
  }
}

/// Imports nest records from an exported JSON file selected by the user.
///
/// The file must match the standard Xolmis export envelope and use the `nests`
/// schema. Each valid item in `records` is converted into a [Nest] and saved
/// through [NestProvider]. Entries that cannot be parsed or persisted are
/// tracked and included in the import summary.
///
/// The [context] is used to access the provider, localized strings, and UI
/// elements such as the progress dialog and result `SnackBar`s.
Future<void> importNestsFromJson(BuildContext context) async {
  bool isDialogShown = false;
  int newImportedCount = 0;
  int updatedCount = 0;
  int skippedCount = 0;
  List<String> importErrors = [];

  try {
    // Pick a JSON file
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result != null && result.files.single.path != null) {
      final filePath = result.files.single.path!;
      final file = File(filePath);

      // Show a loading dialog
      if (!context.mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(year2023: false,),
                  SizedBox(width: 16),
                  Text(S.current.importingNests),
                ],
              ),
            ),
          );
        },
      );
      isDialogShown = true;

      // Read the JSON file
      final jsonString = await file.readAsString();
      final jsonData = jsonDecode(jsonString);

      if (jsonData is Map<String, dynamic>) {
        if (jsonData['source'] != kExportSource) {
          throw FormatException(S.current.invalidJsonSource);
        }
        if (jsonData['schema'] != 'nests') {
          throw FormatException(S.current.invalidJsonSchema);
        }
      }

      final nestProvider = Provider.of<NestProvider>(context, listen: false);
      List<Nest> nestsToImport = [];

      if (jsonData is Map<String, dynamic> && jsonData.containsKey('records') && jsonData['records'] is List) {
        final List<dynamic> nestsJsonList = jsonData['records'];
        for (final item in nestsJsonList) {
          if (item is Map<String, dynamic>) {
            try {
              nestsToImport.add(Nest.fromJson(item));
            } catch (e) {
              importErrors.add(S.current.errorParsingNestsArrayItem(e.toString(), item.toString()));
            }
          } else {
            importErrors.add(S.current.errorUnexpectedNestsArrayItem(item.toString()));
          }
        }
      } else {
        throw FormatException(S.current.invalidJsonFormatExpectedObjectOrArray);
      }

      if (!context.mounted) return;

      final Set<String> conflictingNestFieldNumbers = <String>{};
      for (final nest in nestsToImport) {
        final fieldNumber = nest.fieldNumber;
        if (fieldNumber == null || fieldNumber.isEmpty) continue;
        final exists = await nestProvider.nestFieldNumberExists(fieldNumber);
        if (exists) {
          conflictingNestFieldNumbers.add(fieldNumber.toLowerCase());
        }
      }

      final bool? shouldUpdateExisting = await _resolveUpdateExistingDecision(
        context,
        conflictingNestFieldNumbers.length,
      );

      if (shouldUpdateExisting == null) {
        if (isDialogShown && context.mounted) {
          Navigator.of(context).pop();
          isDialogShown = false;
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              showCloseIcon: true,
              content: Text(S.current.importCancelled),
            ),
          );
        }
        return;
      }

      // Save the nests to the database
      for (final nest in nestsToImport) {
        final fieldNumber = nest.fieldNumber;
        final isExisting =
            fieldNumber != null &&
            conflictingNestFieldNumbers.contains(fieldNumber.toLowerCase());
        if (isExisting && !shouldUpdateExisting) {
          skippedCount++;
          continue;
        }

        final success = await nestProvider.importNest(
          nest,
          updateExisting: shouldUpdateExisting,
        );
        if (success) {
          if (isExisting) {
            updatedCount++;
          } else {
            newImportedCount++;
          }
        } else {
          importErrors.add(S.current.failedToImportNestWithId(nest.id ?? -1));
        }
      }

      if (isDialogShown && context.mounted) Navigator.of(context).pop();
      isDialogShown = false;

      if (!context.mounted) return;

      final summaryMessage = _buildImportSummaryMessage(
        context,
        newCount: newImportedCount,
        updatedCount: updatedCount,
        skippedCount: skippedCount,
        errorsCount: importErrors.length,
        successFallback: S.current.nestsImportedSuccessfully(newImportedCount),
      );
      if (importErrors.isNotEmpty) debugPrint("Import errors: \n${importErrors.join('\n')}");

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: importErrors.isNotEmpty
              ? Theme.of(context).colorScheme.error
              : Colors.green,
            content: Text(summaryMessage)
          )
      );
    } else {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(S.current.noFileSelected)
          )
      );
    }
  } catch (error) {
    if (isDialogShown && context.mounted) Navigator.of(context).pop();
    debugPrint('Error importing nests: $error');
    if (!context.mounted) return;
    String errorMessage = '${S.current.errorImportingNests}: ${error.toString()}';
    if (error is FormatException) errorMessage = S.current.errorImportingNestsWithFormatError(error.message);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        persist: true,
        showCloseIcon: true,
        backgroundColor: Theme.of(context).colorScheme.error,
        content: Text(errorMessage),
          )
          );
  } finally {
    if (isDialogShown && context.mounted) Navigator.of(context).pop();
  }
}

/// Imports specimen records from an exported JSON file selected by the user.
///
/// The selected JSON file must contain the standard export envelope with the
/// `specimens` schema. Each valid record is deserialized into a [Specimen] and
/// imported via [SpecimenProvider], while invalid or failed records are logged
/// and summarized for the user.
///
/// The [context] provides access to the provider tree, localized messages, and
/// transient UI feedback such as dialogs and `SnackBar`s.
Future<void> importSpecimensFromJson(BuildContext context) async {
  bool isDialogShown = false;
  int newImportedCount = 0;
  int updatedCount = 0;
  int skippedCount = 0;
  List<String> importErrors = [];

  try {
    // Pick a JSON file
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result != null && result.files.single.path != null) {
      final filePath = result.files.single.path!;
      final file = File(filePath);

      // Show a loading dialog
      if (!context.mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(year2023: false,),
                  SizedBox(width: 16),
                  Text(S.current.importingSpecimens),
                ],
              ),
            ),
          );
        },
      );
      isDialogShown = true;

      // Read the JSON file
      final jsonString = await file.readAsString();
      final jsonData = jsonDecode(jsonString);

      if (jsonData is Map<String, dynamic>) {
        if (jsonData['source'] != kExportSource) {
          throw FormatException(S.current.invalidJsonSource);
        }
        if (jsonData['schema'] != 'specimens') {
          throw FormatException(S.current.invalidJsonSchema);
        }
      }

      final specimenProvider = Provider.of<SpecimenProvider>(context, listen: false);
      List<Specimen> specimensToImport = [];

      if (jsonData is Map<String, dynamic> && jsonData.containsKey('records') && jsonData['records'] is List) {
        final List<dynamic> specimensJsonList = jsonData['records'];
        for (final item in specimensJsonList) {
          if (item is Map<String, dynamic>) {
            try {
              specimensToImport.add(Specimen.fromJson(item));
            } catch (e) {
              importErrors.add(S.current.errorParsingSpecimensArrayItem(item.toString(), e.toString()));
            }
          } else {
            importErrors.add(S.current.errorUnexpectedSpecimensArrayItem(item.toString()));
          }
        }
      } else {
        throw FormatException(S.current.invalidJsonFormatExpectedObjectOrArray);
      }

      if (!context.mounted) return;

      final Set<String> conflictingSpecimenFieldNumbers = <String>{};
      for (final specimen in specimensToImport) {
        final fieldNumber = specimen.fieldNumber;
        if (fieldNumber.isEmpty) continue;
        final exists = await specimenProvider.specimenFieldNumberExists(fieldNumber);
        if (exists) {
          conflictingSpecimenFieldNumbers.add(fieldNumber.toLowerCase());
        }
      }

      final bool? shouldUpdateExisting = await _resolveUpdateExistingDecision(
        context,
        conflictingSpecimenFieldNumbers.length,
      );

      if (shouldUpdateExisting == null) {
        if (isDialogShown && context.mounted) {
          Navigator.of(context).pop();
          isDialogShown = false;
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              showCloseIcon: true,
              content: Text(S.current.importCancelled),
            ),
          );
        }
        return;
      }

      // Save the specimens to the database
      for (final specimen in specimensToImport) {
        final isExisting =
            conflictingSpecimenFieldNumbers.contains(
              specimen.fieldNumber.toLowerCase(),
            );
        if (isExisting && !shouldUpdateExisting) {
          skippedCount++;
          continue;
        }

        final success = await specimenProvider.importSpecimen(
          specimen,
          updateExisting: shouldUpdateExisting,
        );
        if (success) {
          if (isExisting) {
            updatedCount++;
          } else {
            newImportedCount++;
          }
        } else {
          importErrors.add(
            S.current.failedToImportSpecimenWithId(specimen.id ?? -1),
          );
        }
      }

      if (isDialogShown && context.mounted) Navigator.of(context).pop();
      isDialogShown = false;

      if (!context.mounted) return;

      final summaryMessage = _buildImportSummaryMessage(
        context,
        newCount: newImportedCount,
        updatedCount: updatedCount,
        skippedCount: skippedCount,
        errorsCount: importErrors.length,
        successFallback: S.current.specimensImportedSuccessfully(newImportedCount),
      );
      if (importErrors.isNotEmpty) debugPrint("Import errors: \n${importErrors.join('\n')}");

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: importErrors.isNotEmpty
              ? Theme.of(context).colorScheme.error
              : Colors.green,
            content: Text(summaryMessage)
          )
      );
    } else {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(S.current.noFileSelected)
          )
      );
    }
  } catch (error) {
    if (isDialogShown && context.mounted) Navigator.of(context).pop();
    debugPrint('Error importing specimens: $error');
    if (!context.mounted) return;
    String errorMessage = '${S.current.errorImportingSpecimens}: ${error.toString()}';
    if (error is FormatException) errorMessage = S.current.errorImportingSpecimensWithFormatError(error.message);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        persist: true,
        showCloseIcon: true,
        backgroundColor: Theme.of(context).colorScheme.error,
        content: Text(errorMessage),
          )
          );
  } finally {
    if (isDialogShown && context.mounted) Navigator.of(context).pop();
  }
}

Map<String, dynamic> _normalizeFleatherImageEmbed(Map<dynamic, dynamic> insert) {
  final normalized = Map<String, dynamic>.from(insert);

  String? readSource(Map<dynamic, dynamic> map) {
    final candidates = [map['source'], map['src'], map['url'], map['path']];
    for (final candidate in candidates) {
      if (candidate is String && candidate.trim().isNotEmpty) {
        return candidate.trim();
      }
    }
    return null;
  }

  String? source = readSource(normalized);
  final nestedData = normalized['data'];
  if ((source == null || source.isEmpty) && nestedData is Map) {
    source = readSource(nestedData);
  }

  if (source != null && source.isNotEmpty) {
    final uri = Uri.tryParse(source);
    if (uri != null && uri.scheme == 'file') {
      source = uri.toFilePath();
    } else {
      source = Uri.decodeFull(source);
    }

    normalized['source'] = source;

    // Keep fleather image renderer behavior stable when source_type is missing.
    if (normalized['source_type'] == null || normalized['source_type'].toString().isEmpty) {
      if (source.startsWith('http://') || source.startsWith('https://')) {
        normalized['source_type'] = 'url';
      } else if (source.startsWith('assets/')) {
        normalized['source_type'] = 'assets';
      } else {
        normalized['source_type'] = 'file';
      }
    }
  }

  return normalized;
}

String _normalizeJournalNotesJson(dynamic rawNotes) {
  dynamic parsed = rawNotes;

  if (rawNotes is String) {
    final trimmed = rawNotes.trim();
    if (trimmed.isEmpty) return rawNotes;

    try {
      parsed = jsonDecode(trimmed);
    } catch (_) {
      return rawNotes;
    }
  }

  List<dynamic>? ops;
  if (parsed is List) {
    ops = parsed;
  } else if (parsed is Map && parsed['ops'] is List) {
    ops = parsed['ops'] as List<dynamic>;
  }

  if (ops == null) {
    if (rawNotes is List || rawNotes is Map) {
      return jsonEncode(rawNotes);
    }
    return rawNotes?.toString() ?? '';
  }

  final normalizedOps = <dynamic>[];
  for (final op in ops) {
    if (op is Map) {
      final normalizedOp = Map<String, dynamic>.from(op);
      final insert = normalizedOp['insert'];
      if (insert is Map) {
        final type = insert['_type']?.toString();
        if (type == 'image') {
          normalizedOp['insert'] = _normalizeFleatherImageEmbed(insert);
        }
      }
      normalizedOps.add(normalizedOp);
    } else {
      normalizedOps.add(op);
    }
  }

  if (parsed is Map && parsed['ops'] is List) {
    final normalizedDoc = Map<String, dynamic>.from(parsed);
    normalizedDoc['ops'] = normalizedOps;
    return jsonEncode(normalizedDoc);
  }

  return jsonEncode(normalizedOps);
}

Map<String, dynamic> _normalizeJournalJsonRecord(Map<String, dynamic> item) {
  final normalized = Map<String, dynamic>.from(item);

  final rawId = normalized['id'];
  if (rawId is String) {
    normalized['id'] = int.tryParse(rawId);
  } else if (rawId is num) {
    normalized['id'] = rawId.toInt();
  } else if (rawId != null && rawId is! int) {
    normalized['id'] = null;
  }

  final rawTitle = normalized['title'];
  final title = rawTitle?.toString().trim();
  normalized['title'] = (title == null || title.isEmpty) ? null : title;

  final rawNotes = normalized['notes'];
  if (rawNotes is List || rawNotes is Map || rawNotes is String) {
    normalized['notes'] = _normalizeJournalNotesJson(rawNotes);
  } else if (rawNotes == null) {
    normalized['notes'] = rawNotes;
  } else {
    normalized['notes'] = rawNotes.toString();
  }

  final rawObserver = normalized['observer'];
  if (rawObserver != null && rawObserver is! String) {
    normalized['observer'] = rawObserver.toString();
  }

  final rawCreationDate = normalized['creationDate'];
  if (rawCreationDate is DateTime) {
    normalized['creationDate'] = rawCreationDate.toIso8601String();
  } else if (rawCreationDate != null && rawCreationDate is! String) {
    normalized['creationDate'] = rawCreationDate.toString();
  }

  final rawLastModifiedDate = normalized['lastModifiedDate'];
  if (rawLastModifiedDate is DateTime) {
    normalized['lastModifiedDate'] = rawLastModifiedDate.toIso8601String();
  } else if (rawLastModifiedDate != null && rawLastModifiedDate is! String) {
    normalized['lastModifiedDate'] = rawLastModifiedDate.toString();
  }

  return normalized;
}

/// Imports field journal entries from an exported JSON file selected by the user.
///
/// The file must use the standard Xolmis export envelope and the `journals`
/// schema. Each valid record is converted into a [FieldJournal] and stored
/// through [FieldJournalProvider]. Since journal entries are flat records with
/// their rich text kept as a JSON string, the import flow preserves the notes as
/// exported, including any image placeholders or embeds present in the source.
///
/// Entries with conflicting titles can be updated or skipped based on user
/// preference, following the same conflict resolution pattern as specimens and nests.
Future<void> importJournalsFromJson(BuildContext context) async {
  bool isDialogShown = false;
  int newImportedCount = 0;
  int updatedCount = 0;
  int skippedCount = 0;
  int errorCount = 0;
  List<String> importErrors = [];

  try {
    // Get provider reference BEFORE any async operations that might unmount context
    late FieldJournalProvider journalProvider;
    if (!context.mounted) {
      debugPrint('[importJournalsFromJson] Context not mounted at start');
      return;
    }
    journalProvider = Provider.of<FieldJournalProvider>(context, listen: false);

    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null) {
      debugPrint('[importJournalsFromJson] FilePicker returned null (user cancelled)');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            showCloseIcon: true,
            content: Text(S.current.noFileSelected),
          ),
        );
      }
      return;
    }

    if (result.files.isEmpty) {
      debugPrint('[importJournalsFromJson] FilePicker returned result but files list is empty');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            showCloseIcon: true,
            content: Text(S.current.noFileSelected),
          ),
        );
      }
      return;
    }

    final filePath = result.files.first.path;
    if (filePath == null) {
      debugPrint('[importJournalsFromJson] Selected file has null path');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            showCloseIcon: true,
            content: Text(S.current.noFileSelected),
          ),
        );
      }
      return;
    }

    debugPrint('[importJournalsFromJson] File selected: $filePath');
    final file = File(filePath);

    if (!context.mounted) {
      debugPrint('[importJournalsFromJson] Context unmounted after file selection, reading file without dialog');
    } else {
      debugPrint('[importJournalsFromJson] Context still mounted, showing progress dialog');
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 16),
                  Text(S.current.importingInventory),
                ],
              ),
            ),
          );
        },
      );
      isDialogShown = true;
    }

    debugPrint('[importJournalsFromJson] Reading JSON file...');
    final jsonString = await file.readAsString();
    debugPrint('[importJournalsFromJson] File read successfully, parsing JSON...');
    final jsonData = jsonDecode(jsonString);
    debugPrint('[importJournalsFromJson] JSON parsed successfully');

    if (jsonData is Map<String, dynamic>) {
      if (jsonData['source'] != kExportSource) {
        throw FormatException(S.current.invalidJsonSource);
      }
      if (jsonData['schema'] != 'journals') {
        throw FormatException(S.current.invalidJsonSchema);
      }
    } else {
      throw FormatException(S.current.invalidJsonFormatExpectedObjectOrArray);
    }


    final List<dynamic> journalList =
        jsonData['records'] is List ? jsonData['records'] as List<dynamic> : <dynamic>[];

    debugPrint('[importJournalsFromJson] Journal list extracted: ${journalList.length} entries');

    if (journalList.isEmpty) {
      debugPrint('[importJournalsFromJson] Journal list is empty in JSON records');
      if (isDialogShown && context.mounted) {
        Navigator.of(context).pop();
        isDialogShown = false;
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            showCloseIcon: true,
            content: Text(S.current.noJournalEntriesFound),
          ),
        );
      }
      return;
    }

    final journalsToImport = <FieldJournal>[];
    debugPrint('[importJournalsFromJson] Starting to parse ${journalList.length} journal entries...');
    for (final item in journalList) {
      if (item is Map<String, dynamic>) {
        try {
          final normalizedItem = _normalizeJournalJsonRecord(item);
          journalsToImport.add(FieldJournal.fromJson(normalizedItem));
        } catch (e) {
          final errorMsg = S.current.errorParsingJournalsArrayItem(item.toString(), e.toString());
          importErrors.add(errorMsg);
          debugPrint('[importJournalsFromJson] Parse error: $errorMsg');
        }
      } else {
        final errorMsg = S.current.errorUnexpectedJournalsArrayItem(item.toString());
        importErrors.add(errorMsg);
        debugPrint('[importJournalsFromJson] Unexpected item type: $errorMsg');
      }
    }
    debugPrint('[importJournalsFromJson] Parsing completed: ${journalsToImport.length} valid entries, ${importErrors.length} errors');

    if (journalsToImport.isEmpty) {
      debugPrint('[importJournalsFromJson] No valid journal entries parsed from JSON. Parse errors: ${importErrors.length}');
      importErrors.forEach((error) => debugPrint('  - $error'));
      if (isDialogShown && context.mounted) {
        Navigator.of(context).pop();
        isDialogShown = false;
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            showCloseIcon: true,
            backgroundColor: importErrors.isNotEmpty
                ? Theme.of(context).colorScheme.error
                : null,
            content: Text(
              importErrors.isNotEmpty
                  ? S.current.noValidJournalEntriesFoundInFile
                  : S.current.noJournalEntriesFound,
            ),
          ),
        );
      }
      return;
    }

    if (!context.mounted) {
      debugPrint('[importJournalsFromJson] Context unmounted before conflict detection, but will continue processing with provider reference');
    }

    debugPrint('[importJournalsFromJson] Parsing completed: ${journalsToImport.length} valid journals to import');

    // Detect conflicting titles
    final Set<String> conflictingJournalTitles = <String>{};
    for (final journal in journalsToImport) {
      final title = journal.title ?? '';
      if (title.isNotEmpty) {
        final exists = await journalProvider.journalTitleExists(title);
        if (exists) {
          conflictingJournalTitles.add(title.toLowerCase());
        }
      }
    }
    debugPrint('[importJournalsFromJson] Conflict detection completed: ${conflictingJournalTitles.length} conflicts found');

    final bool? shouldUpdateExisting = await _resolveUpdateExistingDecision(
      context,
      conflictingJournalTitles.length,
    );

    if (shouldUpdateExisting == null) {
      debugPrint('[importJournalsFromJson] User cancelled import at conflict resolution dialog');
      if (isDialogShown && context.mounted) {
        Navigator.of(context).pop();
        isDialogShown = false;
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            showCloseIcon: true,
            content: Text(S.current.importCancelled),
          ),
        );
      }
      return;
    }

    debugPrint('[importJournalsFromJson] Starting import process: updateExisting=$shouldUpdateExisting');

    // Import the journals using the provider
    final importResult = await journalProvider.importJournalEntries(
      journalsToImport,
      updateExisting: shouldUpdateExisting,
    );
    newImportedCount = importResult['newCount'] as int? ?? 0;
    updatedCount = importResult['updatedCount'] as int? ?? 0;
    skippedCount = importResult['skippedCount'] as int? ?? 0;
    final persistenceErrors =
        (importResult['errors'] as List<dynamic>? ?? [])
            .map((error) => error.toString())
            .toList();
    importErrors.addAll(persistenceErrors);
    errorCount = importErrors.length;

    debugPrint('[importJournalsFromJson] Import completed: newCount=$newImportedCount, updatedCount=$updatedCount, skippedCount=$skippedCount, errorCount=$errorCount');
    if (persistenceErrors.isNotEmpty) {
      debugPrint('[importJournalsFromJson] Persistence errors:');
      persistenceErrors.forEach((error) => debugPrint('  - $error'));
    }

    if (isDialogShown && context.mounted) {
      Navigator.of(context).pop();
      isDialogShown = false;
    }

    if (!context.mounted) {
      debugPrint('[importJournalsFromJson] Context unmounted after import completion. Import results: newCount=$newImportedCount, updatedCount=$updatedCount, skippedCount=$skippedCount, errorCount=$errorCount');
      if (importErrors.isNotEmpty) {
        debugPrint('[importJournalsFromJson] Import completed with errors: ${importErrors.join(", ")}');
      }
      return;
    }
    if (importErrors.isNotEmpty) debugPrint('Import errors: \n${importErrors.join('\n')}');

    final summaryMessage = _buildImportSummaryMessage(
      context,
      newCount: newImportedCount,
      updatedCount: updatedCount,
      skippedCount: skippedCount,
      errorsCount: errorCount,
      successFallback: S.current.journalsImportedSuccessfully(newImportedCount),
    );
    debugPrint('[importJournalsFromJson] Displaying import summary to user: $summaryMessage');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor:
            newImportedCount == 0 || errorCount > 0
                ? Theme.of(context).colorScheme.error
                : Colors.green,
        showCloseIcon: true,
        content: Text(summaryMessage),
        duration: Duration(seconds: errorCount > 0 ? 5 : 2),
      ),
    );
  } catch (error) {
    debugPrint('[importJournalsFromJson] Exception caught during import: $error');
    if (isDialogShown && context.mounted) {
      Navigator.of(context).pop();
    }
    if (!context.mounted) {
      debugPrint('[importJournalsFromJson] Context unmounted during error handling');
      return;
    }
    String errorMessage = '${S.current.errorImportingJournals}: ${error.toString()}';
    if (error is FormatException) {
      errorMessage = '${S.current.errorImportingJournals}: ${error.message}';
    }
    debugPrint('[importJournalsFromJson] Showing error to user: $errorMessage');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        persist: true,
        showCloseIcon: true,
        backgroundColor: Theme.of(context).colorScheme.error,
        content: Text(errorMessage),
      ),
    );
  } finally {
    debugPrint('[importJournalsFromJson] Finally block - cleaning up (closing dialog if needed)');
    if (isDialogShown && context.mounted) {
      Navigator.of(context).pop();
    }
  }
}
