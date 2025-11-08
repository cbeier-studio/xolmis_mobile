// lib/services/inventory_completion_service.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Para configurações

// Importe seus modelos e providers necessários
import '../../data/models/inventory.dart';
import '../providers/inventory_provider.dart'; // Exemplo
import '../data/daos/inventory_dao.dart'; // Exemplo
// Importe suas telas de adição de vegetação/tempo e strings S.of(context)
import '../screens/inventory/add_vegetation_screen.dart';
import '../screens/inventory/add_weather_screen.dart';
import '../generated/l10n.dart'; // Ou onde quer que S esteja

// Enum para as ações do diálogo de aviso (pode ser movido para um arquivo comum se usado em mais lugares)
enum ConditionalAction { add, ignore, cancelDialog }

class InventoryCompletionService {
  final BuildContext context; // Precisa do contexto para navegação, diálogos, ScaffoldMessenger
  final Inventory inventory;
  final InventoryProvider inventoryProvider;
  final InventoryDao inventoryDao;
  // Adicione quaisquer outros providers ou repositórios necessários, ex: VegetationRepository

  InventoryCompletionService({
    required this.context,
    required this.inventory,
    required this.inventoryProvider,
    required this.inventoryDao,
  });

  // Função para realmente finalizar o inventário
  Future<void> _finalizeInventory(BuildContext context) async {
    inventory.stopTimer(context, inventoryDao);
    inventoryProvider.updateInventory(inventory);
    // inventoryProvider.notifyListeners();

    // if (context.mounted) {
    //   Navigator.of(context).pop(true);
      // Navigator.of(context).pop();
    // }
  }

  // Helper para mostrar o diálogo de aviso condicional (pode ser estático se não depender de membros da classe)
  static Future<ConditionalAction?> _showConditionalReminderDialog(
      BuildContext dialogContext, // Usa o contexto específico do diálogo
          {
        required String title,
        required String content,
      }
      ) async {
    return showDialog<ConditionalAction>(
      context: dialogContext,
      barrierDismissible: false,
      builder: (BuildContext alertContext) {
        return AlertDialog.adaptive(
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

  // Função principal para processar os avisos e finalizar
  Future<void> processConditionalRemindersAndFinalize(BuildContext context) async {
    bool proceedToFinalize = true;

    final prefs = await SharedPreferences.getInstance();
    final bool remindVegetationEmpty = prefs.getBool('remindVegetationEmpty') ?? false;
    final bool remindWeatherEmpty = prefs.getBool('remindWeatherEmpty') ?? false;

    // Adapte estas verificações à estrutura do seu objeto 'inventory'
    bool isVegetationListEmpty = inventory.vegetationList.isEmpty; // Supondo que inventory.vegetationList existe
    bool isWeatherListEmpty = inventory.weatherList.isEmpty;   // Supondo que inventory.weatherList existe

    // 1. Aviso de Vegetação
    if (remindVegetationEmpty && isVegetationListEmpty) {
      final vegetationAction = await _showConditionalReminderDialog(
        context, // Usa o contexto principal para o diálogo
        title: S.of(context).warningTitle, // "Aviso" ou mais específico
        content: S.of(context).missingVegetationData, // "Dados de vegetação estão faltando..."
      );

      if (vegetationAction == ConditionalAction.add) {
        proceedToFinalize = false;
        if (context.mounted) {
          bool? vegetationAdded = await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => AddVegetationDataScreen(inventory: inventory)),
          );
          if (vegetationAdded != null && vegetationAdded) {
            await inventoryProvider.fetchInventories(context);
            proceedToFinalize = true;
          }
        }
      } else if (vegetationAction == ConditionalAction.cancelDialog) {
        proceedToFinalize = false;
        return; // Interrompe o processo
      }
    }

    // 2. Aviso de Tempo
    if (proceedToFinalize && remindWeatherEmpty && isWeatherListEmpty) {
      final weatherAction = await _showConditionalReminderDialog(
        context,
        title: S.of(context).warningTitle,
        content: S.of(context).missingWeatherData, // "Dados do tempo estão faltando..."
      );

      if (weatherAction == ConditionalAction.add) {
        proceedToFinalize = false;
        if (context.mounted) {
          bool? weatherAdded = await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => AddWeatherScreen(inventory: inventory)),
          );
          if (weatherAdded != null && weatherAdded) {
            await inventoryProvider.fetchInventories(context);
            proceedToFinalize = true;
          }
        }
      } else if (weatherAction == ConditionalAction.cancelDialog) {
        proceedToFinalize = false;
        return; // Interrompe o processo
      }
    }

    // 3. Finalizar o inventário
    if (proceedToFinalize) {
      if (context.mounted) {
        await _finalizeInventory(context);
      }
    }
  }

  // Função pública para iniciar o processo de finalização (chamada pela UI)
  Future<void> attemptFinishInventory(BuildContext context) async {
    final bool? confirmedFinish = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog.adaptive(
          title: Text(S.of(dialogContext).confirmFinish),
          content: Text(S.of(dialogContext).confirmFinishMessage),
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

