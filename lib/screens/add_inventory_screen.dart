import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';
import '../models/inventory.dart';

class AddInventoryScreen extends StatefulWidget {const AddInventoryScreen({super.key});

  @override
  AddInventoryScreenState createState() => AddInventoryScreenState();
}

class AddInventoryScreenState extends State<AddInventoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  InventoryType _selectedType = InventoryType.invQualitative;
  final _durationController = TextEditingController();
  final _maxSpeciesController = TextEditingController();
  bool _isSubmitting = false;

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
                decoration: const InputDecoration(
                  labelText: 'ID do Inventário',
                  border: OutlineInputBorder(),
                ),
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
                decoration: const InputDecoration(
                  labelText: 'Tipo de Inventário',
                  border: OutlineInputBorder(),
                ),
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
                      _durationController.text = '30';
                    } else if (newValue == InventoryType.invMackinnon) {
                      _maxSpeciesController.text = '10';
                    } else {
                      _durationController.text = '';
                      _maxSpeciesController.text = '';
                    }
                  });
                },
              ), const SizedBox(height: 16.0),
              Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _durationController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Duração',
                          border: OutlineInputBorder(),
                          suffixText: 'minutos',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: TextFormField(
                        controller: _maxSpeciesController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Máx. espécies',
                          border: OutlineInputBorder(),
                          suffixText: 'spp.',
                        ),
                      ),
                    ),
                  ]
              ),
              const SizedBox(height: 32.0),
              Center(
                child: _isSubmitting
                    ? CircularProgressIndicator()
                    : ElevatedButton(
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

  void _submitForm() async {
    setState(() {
      _isSubmitting = true;
    });

    if (_formKey.currentState!.validate()) {
      final newInventory = Inventory(
        id: _idController.text,
        type: _selectedType,
        duration: int.tryParse(_durationController.text) ?? 0,
        maxSpecies: int.tryParse(_maxSpeciesController.text) ?? 0,
        speciesList: [],
        vegetationList: [],
      );

      // Check if the ID already exists in the database
      final inventoryProvider = Provider.of<InventoryProvider>(
          context, listen: false);
      final idExists = await inventoryProvider.inventoryIdExists(
          newInventory.id);

      if (idExists) {
        // ID already exists, show a SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Row(
            children: [
              const Icon(Icons.info, color: Colors.blue),
              const SizedBox(width: 8),
              const Text('Já existe um inventário com esta ID.'),
            ],
          ),
          ),
        );
        return; // Prevent adding inventory
      }

      // ID do not exist, insert inventory
      final success = await inventoryProvider.addInventory(newInventory);

      setState(() {
        _isSubmitting = false;
      });

      if (success) {
        // Inventory inserted successfully
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check, color: Colors.green),
                SizedBox(width: 8),
                Text('Inventário inserido com sucesso.'),
              ],
            ),
          ),
        );
        Navigator.pop(context); // Return to the previous screen
      } else {
        // Handle insertion error
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Row(
            children: [
              const Icon(Icons.error, color: Colors.red),
              const SizedBox(width: 8),
              const Text('Erro ao inserir inventário.'),
            ],
          ),
          ),
        );
      }
    }
  }
}