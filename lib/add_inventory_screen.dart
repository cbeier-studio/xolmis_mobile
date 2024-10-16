import 'package:flutter/material.dart';
import 'inventory.dart';
import 'database_helper.dart';

class AddInventoryScreen extends StatefulWidget {const AddInventoryScreen({Key? key}) : super(key: key);

@override
_AddInventoryScreenState createState() => _AddInventoryScreenState();
}

class _AddInventoryScreenState extends State<AddInventoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  InventoryType _selectedType = InventoryType.invQualitative;
  int _duration = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adicionar Inventário'),),
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
                onChanged: (value) {
                  setState(() {
                    _selectedType = value!;
                  });
                },
              ),const SizedBox(height: 16.0),
              TextFormField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Duração (minutos)'),
                onChanged: (value) {
                  setState(() {
                    _duration = int.tryParse(value) ?? 0;
                  });
                },
              ),
              const SizedBox(height: 32.0),
              Center(
                child: ElevatedButton(
                  onPressed: _submitForm,
                  child: const Text('Criar Inventário'),
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
        duration: _duration,
        speciesList: [],
        vegetationList: [],
      );

      DatabaseHelper().insertInventory(newInventory).then((success) {
        if (success) {
          // Inventário inserido com sucesso
          Navigator.pop(context, newInventory); // Retorna o novo inventário
        } else {
          // Lidar com erro de inserção
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erro ao inserir inventário')),
          );
        }
      });
    }
  }
}