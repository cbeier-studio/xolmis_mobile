import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/inventory_provider.dart';
import '../../data/models/inventory.dart';
import '../utils.dart';

class AddInventoryScreen extends StatefulWidget {
  final String? initialInventoryId;
  final InventoryType? initialInventoryType;
  final int? initialMaxSpecies;

  const AddInventoryScreen({super.key, this.initialInventoryId, this.initialInventoryType, this.initialMaxSpecies});

  @override
  AddInventoryScreenState createState() => AddInventoryScreenState();
}

class AddInventoryScreenState extends State<AddInventoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _durationController = TextEditingController();
  final _maxSpeciesController = TextEditingController();
  InventoryType _selectedType = InventoryType.invFreeQualitative;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _idController.text = widget.initialInventoryId ?? '';
    _selectedType = widget.initialInventoryType ?? _selectedType;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Novo Inventário'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView( // Prevent keyboard overflow
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _idController,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: 'ID do Inventário *',
                        helperText: '* campo obrigatório',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.auto_mode_outlined),
                          onPressed: () async {
                            final result = await showDialog<String>(
                              context: context,
                              builder: (BuildContext context) {
                                String acronym = '';
                                return AlertDialog(
                                  title: const Text('Gerar ID'),
                                  content: TextField(
                                    maxLength: 10,
                                    textCapitalization: TextCapitalization.words,
                                    autofocus: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Nome ou sigla do local',
                                      border: OutlineInputBorder(),
                                      helperText: '* opcional',
                                    ),
                                    onChanged: (value) {
                                      setState(() {
                                        acronym = value;
                                      });
                                    },
                                  ),
                                  actions: <Widget>[
                                    TextButton(
                                      child: const Text('Cancelar'),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                    TextButton(
                                      child: const Text('OK'),
                                      onPressed: () {
                                        Navigator.of(context).pop(acronym);
                                      },
                                    ),
                                  ],
                                );
                              },
                            );

                            if (result != null) {
                              // Concatenate the inventory ID in the specified format
                              final prefs = await SharedPreferences.getInstance();
                              final observerAcronym = prefs.getString('observerAcronym') ?? '';
                              final now = DateTime.now();
                              final year = now.year.toString();
                              final month = now.month.toString().padLeft(2, '0');
                              final day = now.day.toString().padLeft(2, '0');
                              final inventoryTypeLetter = getInventoryTypeLetter(_selectedType);
                              final sequentialNumber = await Provider.of<InventoryProvider>(context, listen: false).getNextSequentialNumber(result, observerAcronym, now.year, now.month, now.day, inventoryTypeLetter);

                              final inventoryId = '${result != null ? '$result-' : ''}$observerAcronym-$year$month$day-${inventoryTypeLetter != null ? '$inventoryTypeLetter' : ''}${sequentialNumber.toString().padLeft(2, '0')}';

                              _idController.text = inventoryId;
                            }
                          },
                        ),
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
                        labelText: 'Tipo de Inventário *',
                        helperText: '* campo obrigatório',
                        border: OutlineInputBorder(),
                      ),
                      items: InventoryType.values.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(inventoryTypeFriendlyNames[type]!),
                        );
                      }).toList(),
                      onChanged: (InventoryType? newValue) {
                        if (newValue != null) {
                          _updateFormFields(newValue);
                        }
                      },
                      validator: (value) {
                        if (value == null || value.index < 0) {
                          return 'Por favor, selecione um tipo de inventário';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16.0),
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
                              validator: (value) {
                                if ((_selectedType == InventoryType.invTimedQualitative || _selectedType == InventoryType.invPointCount) && (value == null || value.isEmpty)) {
                                  return 'Insira uma duração';
                                }
                                return null;
                              },
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
                              validator: (value) {
                                if ((_selectedType == InventoryType.invMackinnonList) && (value == null || value.isEmpty)) {
                                  return 'Insira o máximo de espécies';
                                }
                                return null;
                              },
                            ),
                          ),
                        ]
                    ),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Container(
              padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
              width: double.infinity,
              child: Align(
                alignment: Alignment.centerRight,
                child: _isSubmitting
                    ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : FilledButton(
                  onPressed: _submitForm,
                  child: const Text('Iniciar inventário'),
                ),
              )
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateFormFields(InventoryType newValue) async {
    final prefs = await SharedPreferences.getInstance();
    final maxSpeciesMackinnon = prefs.getInt('maxSpeciesMackinnon') ?? 10;
    final pointCountsDuration = prefs.getInt('pointCountsDuration') ?? 8;
    final cumulativeTimeDuration = prefs.getInt('cumulativeTimeDuration') ?? 30;

    setState(() {
      _selectedType = newValue;
      if (newValue == InventoryType.invTimedQualitative) {
        _durationController.text = cumulativeTimeDuration.toString();
        _maxSpeciesController.text = '';
      } else if (newValue == InventoryType.invMackinnonList) {
        _maxSpeciesController.text = maxSpeciesMackinnon.toString();
        _durationController.text = '';
      } else if (newValue == InventoryType.invPointCount) {
        _durationController.text = pointCountsDuration.toString();
        _maxSpeciesController.text = '';
      } else {
        _durationController.text = '';
        _maxSpeciesController.text = '';
      }
    });
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
        weatherList: [],
      );

      // Check if the ID already exists in the database
      final inventoryProvider = Provider.of<InventoryProvider>(
          context, listen: false);
      final idExists = await inventoryProvider.inventoryIdExists(
          newInventory.id);

      if (idExists) {
        setState(() {
          _isSubmitting = false;
        });
        // ID already exists, show a SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Row(
            children: [
              Icon(Icons.info_outlined, color: Colors.blue),
              SizedBox(width: 8),
              Text('Já existe um inventário com esta ID.'),
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
                Icon(Icons.check_circle_outlined, color: Colors.green),
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
              Icon(Icons.error_outlined, color: Colors.red),
              SizedBox(width: 8),
              Text('Erro ao inserir inventário.'),
            ],
          ),
          ),
        );
      }
    } else {
      setState(() {
        _isSubmitting = false;
      });
    }
  }
}