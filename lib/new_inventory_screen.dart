import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'inventory.dart';
import 'inventory_provider.dart';

class NewInventoryScreen extends StatefulWidget {
  const NewInventoryScreen({super.key});

  @override
  _NewInventoryScreenState createState() => _NewInventoryScreenState();
}

class _NewInventoryScreenState extends State<NewInventoryScreen> {
final _formKey = GlobalKey<FormState>();
final _idController = TextEditingController();
final _durationController = TextEditingController();
InventoryType _selectedType = InventoryType.invQualitative;

@override
void dispose() {
  _idController.dispose();
  _durationController.dispose();
  super.dispose();
}

void _saveInventory(BuildContext context) async {
  if (_formKey.currentState!.validate()) {
    try {
      int duration = int.tryParse(_durationController.text) ?? 0;

      Inventory newInventory = Inventory(
        id: _idController.text,
        type: _selectedType,
        duration: duration,
        speciesList: [],
      );

      bool success = await Provider.of<InventoryProvider>(context, listen: false).addInventory(newInventory);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inventário iniciado')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao salvar inventário. Por favor, tente novamente.')),
        );
      }
    } catch (e) {
      if (e is FormatException) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Duração inválida. Por favor, insira um número inteiro.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar inventário: $e')),);
      }
    }
  }
}

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Novo Inventário'),
    ),
    body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _idController,
              decoration: const InputDecoration(
                labelText: 'ID do Inventário',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, insira um ID de inventário';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<InventoryType>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Tipo de Inventário',
                border: OutlineInputBorder(),
              ),
              onChanged: (InventoryType? newValue) {
                setState(() {
                  _selectedType = newValue!;
                });
              },
              items: InventoryType.values.map((InventoryType type) {
                return DropdownMenuItem<InventoryType>(
                  value: type,
                  child: Text(inventoryTypeFriendlyNames[type]!),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _durationController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Duração (minutos)',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  if (int.tryParse(value) == null) {
                    return 'Por favor, insira um número inteiro válido';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _saveInventory(context),
              child: const Text('Iniciar Inventário'),
            ),
          ],
        ),
      ),
    ),
  );
}
}