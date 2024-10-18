import 'package:flutter/material.dart';
import 'inventory.dart';
import 'database_helper.dart';

class AddInventoryScreen extends StatefulWidget {const AddInventoryScreen({super.key});

@override
_AddInventoryScreenState createState() => _AddInventoryScreenState();
}

class _AddInventoryScreenState extends State<AddInventoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  InventoryType _selectedType = InventoryType.invQualitative;
  final _durationController = TextEditingController();

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _idController,
                decoration: const InputDecoration(labelText: 'ID do Inventário'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira um ID para o inventário';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              DropdownButtonFormField<InventoryType>(
                value: _selectedType,
                decoration: const InputDecoration(labelText: 'Tipo de Inventário'),
                items: InventoryType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(inventoryTypeFriendlyNames[type]!),
                  );
                }).toList(),
                onChanged: (InventoryType? newValue) {
                  setState(() {
                    _selectedType = newValue!;
                    if (newValue == InventoryType.invCumulativeTime) {
                      _durationController.text = '30'; // Define duration to 30 minutes
                    } else {
                      _durationController.text = ''; // Clear duration field
                    }
                  });
                },
              ),const SizedBox(height: 16.0),
              TextFormField(
                controller: _durationController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Duração (minutos)'),
              ),
              const SizedBox(height: 32.0),
              Center(
                child: ElevatedButton(
                  onPressed: _submitForm,
                  child: const Text('Iniciar Inventário'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final newInventory = Inventory(
        id: _idController.text,
        type: _selectedType,
        duration: int.tryParse(_durationController.text) ?? 0,
        speciesList: [],
        vegetationList: [],
      );

      DatabaseHelper().insertInventory(newInventory).then((success) {
        if (success) {
          // Inventory inserted successfully
          Navigator.pop(context, newInventory);
        } else {
          // Handle insertion error
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erro ao inserir inventário')),
          );
        }
      });
    }
  }
}