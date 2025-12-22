import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:xolmis/generated/l10n.dart';

import '../data/models/inventory.dart';
import '../data/models/nest.dart';
import '../data/models/specimen.dart';

import '../providers/inventory_provider.dart';
import '../providers/nest_provider.dart';
import '../providers/specimen_provider.dart';

Future<void> importInventoryFromJson(BuildContext context) async {
  bool isDialogShown = false;
  int successfullyImportedCount = 0;
  int totalInventoriesToImport = 0;
  List<String> importErrors = [];
  
  try {
    // Pick a JSON file
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    // Se nenhum arquivo foi selecionado, sai sem erro
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

    // Show a loading dialog (apenas se context está montado)
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

    // Read the JSON file (funciona mesmo com context desmontado)
    final jsonString = await file.readAsString();
    final jsonData = jsonDecode(jsonString);

    // Obter o provider ANTES de tentar usar context
    late InventoryProvider inventoryProvider;
    if (context.mounted) {
      inventoryProvider = Provider.of<InventoryProvider>(context, listen: false);
    } else {
      // Se context foi desmontado, não podemos usar o provider
      // Fechar diálogo se foi mostrado e sair
      if (isDialogShown && context.mounted) {
        Navigator.of(context).pop();
      }
      debugPrint('Context unmounted during file reading');
      return;
    }

    List<Inventory> inventoriesToImport = [];

    if (jsonData is List) {
      // Case 1: JSON is an array of inventories
      totalInventoriesToImport = jsonData.length;
      for (final item in jsonData) {
        if (item is Map<String, dynamic>) {
          try {
            inventoriesToImport.add(Inventory.fromJson(item));
          } catch (e) {
            importErrors.add(S.current.errorParsingArrayItem(item.toString(), e.toString()));
          }
        } else {
          importErrors.add(S.current.errorUnexpectedArrayItem(item.toString()));
        }
      }
    } else if (jsonData is Map<String, dynamic>) {
      // Case 2: JSON is an inventory only (or have a key "inventories")
      if (jsonData.containsKey('inventories') && jsonData['inventories'] is List) {
        // Subcase 2.1: JSON have a key "inventories" and it's a list
        final List<dynamic> inventoriesJsonList = jsonData['inventories'];
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
        // Subcase 2.2: JSON is an inventory only
        totalInventoriesToImport = 1;
        try {
          inventoriesToImport.add(Inventory.fromJson(jsonData));
        } catch (e) {
          importErrors.add(S.current.errorParsingObject(e.toString()));
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
            content: Text(message), duration: Duration(seconds: 4)),
        );
      }
      return;
    }

    // Save the inventory to the database
    for (final inventory in inventoriesToImport) {
      try {
        final success = await inventoryProvider.importInventory(inventory);
        if (success) {
          successfullyImportedCount++;
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

    // Show import summary (apenas se context está montado)
    if (context.mounted) {
      String summaryMessage;
      if (importErrors.isEmpty) {
        summaryMessage = S.current.inventoriesImportedSuccessfully(successfullyImportedCount);
      } else {
        summaryMessage = S.current.importCompletedWithErrors(successfullyImportedCount, importErrors.length);
        debugPrint("Import errors: \n${importErrors.join('\n')}");
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          showCloseIcon: true,
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
          content: Row(
            children: [
              Icon(Icons.error_outlined, color: Colors.red),
              SizedBox(width: 8),
              Text(errorMessage),
            ],
          ),
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

Future<void> importNestsFromJson(BuildContext context) async {
  bool isDialogShown = false;
  int successfullyImportedCount = 0;
  // int totalNestsToImport = 0;
  List<String> importErrors = [];

  try {
    // Pick a JSON file
    FilePickerResult? result = await FilePicker.platform.pickFiles(
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

      final nestProvider = Provider.of<NestProvider>(context, listen: false);
      List<Nest> nestsToImport = [];

      if (jsonData is List) {
        // totalNestsToImport = jsonData.length;
        for (final item in jsonData) {
          if (item is Map<String, dynamic>) {
            try {
              nestsToImport.add(Nest.fromJson(item));
            } catch (e) {
              importErrors.add(S.current.errorParsingArrayItem(item.toString(), e.toString()));
            }
          } else {
            importErrors.add(S.current.errorUnexpectedArrayItem(item.toString()));
          }
        }
      } else if (jsonData is Map<String, dynamic> && jsonData.containsKey('nests') && jsonData['nests'] is List) {
        final List<dynamic> nestsJsonList = jsonData['nests'];
        // totalNestsToImport = nestsJsonList.length;
        for (final item in nestsJsonList) {
          if (item is Map<String, dynamic>) {
            try {
              nestsToImport.add(Nest.fromJson(item)); // Alterado para Nest.fromJson
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
      // Save the nests to the database
      for (final nest in nestsToImport) {
        final success = await nestProvider.importNest(nest);
        if (success) {
          successfullyImportedCount++;
        } else {
          importErrors.add(S.current.failedToImportNestWithId(nest.id!));
        }
      }

      if (isDialogShown && context.mounted) Navigator.of(context).pop();
      isDialogShown = false;

      if (!context.mounted) return;

      String summaryMessage = importErrors.isEmpty
          ? S.current.nestsImportedSuccessfully(successfullyImportedCount)
          : S.current.importCompletedWithErrors(successfullyImportedCount, importErrors.length);
      if (importErrors.isNotEmpty) debugPrint("Import errors: \n${importErrors.join('\n')}");

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(summaryMessage)));
    } else {
      // if (isDialogShown && context.mounted) Navigator.of(context).pop();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.current.noFileSelected)));
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
        content: Row(children: [
          Icon(Icons.error_outlined, color: Colors.red), 
          SizedBox(width: 8), 
          Text(errorMessage)]), 
        )
        );
  } finally {
    if (isDialogShown && context.mounted) Navigator.of(context).pop();
  }
}

Future<void> importSpecimensFromJson(BuildContext context) async {
  bool isDialogShown = false;
  int successfullyImportedCount = 0;
  // int totalSpecimensToImport = 0;
  List<String> importErrors = [];

  try {
    // Pick a JSON file
    FilePickerResult? result = await FilePicker.platform.pickFiles(
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

      final specimenProvider = Provider.of<SpecimenProvider>(context, listen: false);
      List<Specimen> specimensToImport = [];

      if (jsonData is List) {
        // totalSpecimensToImport = jsonData.length;
        for (final item in jsonData) {
          if (item is Map<String, dynamic>) {
            try {
              specimensToImport.add(Specimen.fromJson(item));
            } catch (e) {
              importErrors.add(S.current.errorParsingArrayItem(item.toString(), e.toString()));
            }
          } else {
            importErrors.add(S.current.errorUnexpectedArrayItem(item.toString()));
          }
        }
      } else if (jsonData is Map<String, dynamic> && jsonData.containsKey('specimens') && jsonData['specimens'] is List) {
        final List<dynamic> specimensJsonList = jsonData['specimens'];
        // totalSpecimensToImport = specimensJsonList.length;
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
      // Save the specimens to the database
      for (final specimen in specimensToImport) {
        final success = await specimenProvider.importSpecimen(specimen);
        if (success) {
          successfullyImportedCount++;
        } else {
          importErrors.add(S.current.failedToImportSpecimenWithId(specimen.id!));
        }
      }

      if (isDialogShown && context.mounted) Navigator.of(context).pop();
      isDialogShown = false;

      if (!context.mounted) return;

      String summaryMessage = importErrors.isEmpty
          ? S.current.specimensImportedSuccessfully(successfullyImportedCount)
          : S.current.importCompletedWithErrors(successfullyImportedCount, importErrors.length);
      if (importErrors.isNotEmpty) debugPrint("Import errors: \n${importErrors.join('\n')}");

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(summaryMessage)));
    } else {
      // if (isDialogShown && context.mounted) Navigator.of(context).pop();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.current.noFileSelected)));
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
        content: Row(children: [
          Icon(Icons.error_outlined, color: Colors.red), 
          SizedBox(width: 8), 
          Text(errorMessage)]), 
          )
          );
  } finally {
    if (isDialogShown && context.mounted) Navigator.of(context).pop();
  }
}
