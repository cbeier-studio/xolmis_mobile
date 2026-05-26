import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/core_consts.dart';
import '../data/models/inventory.dart';
import '../providers/inventory_provider.dart';
import '../providers/vegetation_provider.dart';
import '../providers/weather_provider.dart';
import '../data/daos/inventory_dao.dart';

import '../screens/inventory/add_vegetation_screen.dart';
import '../screens/inventory/add_weather_screen.dart';
import '../generated/l10n.dart';

/// Coordinates the finalization flow for inventories, including reminders.
class InventoryCompletionService {
  final BuildContext context;
  final Inventory inventory;
  final InventoryProvider inventoryProvider;
  final InventoryDao inventoryDao;

  InventoryCompletionService({
    required this.context,
    required this.inventory,
    required this.inventoryProvider,
    required this.inventoryDao,
  });

  /// Stops and persists the inventory as finished.
  Future<void> _finalizeInventory(BuildContext context) async {
    inventory.stopTimer(context, inventoryDao);
    inventoryProvider.updateInventory(inventory);
  }

  /// Shows a reminder dialog asking whether to add missing data or continue.
  static Future<ConditionalAction?> _showConditionalReminderDialog(
      BuildContext dialogContext,
          {
        required String title,
        required String content,
      }
      ) async {
    return showDialog<ConditionalAction>(
      context: dialogContext,
      barrierDismissible: false,
      builder: (BuildContext alertContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              child: Text(S.current.cancel),
              onPressed: () => Navigator.of(alertContext).pop(ConditionalAction.cancelDialog),
            ),
            TextButton(
              child: Text(S.current.ignoreButton),
              onPressed: () => Navigator.of(alertContext).pop(ConditionalAction.ignore),
            ),
            FilledButton(
              child: Text(S.current.addButton),
              onPressed: () => Navigator.of(alertContext).pop(ConditionalAction.add),
            ),
          ],
        );
      },
    );
  }

  /// Processes reminder rules and finalizes the inventory when allowed.
  ///
  /// Depending on the current settings, this method can prompt the user to add
  /// missing vegetation or weather data before finishing the inventory.
  Future<void> processConditionalRemindersAndFinalize(BuildContext context) async {
    bool proceedToFinalize = true;

    final VegetationProvider vegetationProvider = context.read<VegetationProvider>();
    final WeatherProvider weatherProvider = context.read<WeatherProvider>();

    final prefs = await SharedPreferences.getInstance();
    final bool remindVegetationEmpty = prefs.getBool('remindVegetationEmpty') ?? false;
    final bool remindWeatherEmpty = prefs.getBool('remindWeatherEmpty') ?? false;

    bool isVegetationListEmpty = inventory.vegetationList.isEmpty;
    bool isWeatherListEmpty = inventory.weatherList.isEmpty;

    // 1. Vegetation reminder
    if (remindVegetationEmpty && isVegetationListEmpty) {
      final vegetationAction = await _showConditionalReminderDialog(
        context,
        title: S.of(context).warningTitle,
        content: S.of(context).missingVegetationData,
      );

      if (vegetationAction == ConditionalAction.add) {
        proceedToFinalize = false;
        if (context.mounted) {
          bool? vegetationAdded = await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => AddVegetationDataScreen(inventory: inventory)),
          );
          if (vegetationAdded != null && vegetationAdded) {
            await vegetationProvider.loadVegetationForInventory(inventory.id);
            proceedToFinalize = true;
          }
        }
      } else if (vegetationAction == ConditionalAction.cancelDialog) {
        proceedToFinalize = false;
        return;
      }
    }

    // 2. Weather reminder
    if (proceedToFinalize && remindWeatherEmpty && isWeatherListEmpty) {
      final weatherAction = await _showConditionalReminderDialog(
        context,
        title: S.of(context).warningTitle,
        content: S.of(context).missingWeatherData,
      );

      if (weatherAction == ConditionalAction.add) {
        proceedToFinalize = false;
        if (context.mounted) {
          bool? weatherAdded = await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => AddWeatherScreen(inventory: inventory)),
          );
          if (weatherAdded != null && weatherAdded) {
            await weatherProvider.loadWeatherForInventory(inventory.id);
            proceedToFinalize = true;
          }
        }
      } else if (weatherAction == ConditionalAction.cancelDialog) {
        proceedToFinalize = false;
        return;
      }
    }

    // 3. Finish the inventory
    if (proceedToFinalize) {
      if (context.mounted) {
        await _finalizeInventory(context);
      }
    }
  }

  /// Starts the inventory finish flow by asking the user for confirmation.
  Future<void> attemptFinishInventory(BuildContext context) async {
    final bool? confirmedFinish = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog.adaptive(
          title: Text(S.of(dialogContext).confirmFinish),
          content: Text(S.of(dialogContext).confirmFinishMessage(inventory.id)),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(S.of(dialogContext).cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(S.of(dialogContext).finish),
            ),
          ],
        );
      },
    );

    if (confirmedFinish == true) {
      if (context.mounted) {
        await processConditionalRemindersAndFinalize(context);
      }
    }
  }
}

