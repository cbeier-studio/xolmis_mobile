import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../../data/models/inventory.dart';
import '../../providers/vegetation_provider.dart';

import '../../utils/utils.dart';

class AddVegetationDataScreen extends StatefulWidget {
  final Inventory inventory;

  const AddVegetationDataScreen({
    super.key,
    required this.inventory,
  });

  @override
  AddVegetationDataScreenState createState() => AddVegetationDataScreenState();
}

class AddVegetationDataScreenState extends State<AddVegetationDataScreen> {
  final _formKey = GlobalKey<FormState>();
  DistributionType _selectedHerbsDistribution = DistributionType.disNone;
  DistributionType _selectedShrubsDistribution = DistributionType.disNone;
  DistributionType _selectedTreesDistribution = DistributionType.disNone;
  late TextEditingController _herbsProportionController;
  late TextEditingController _herbsHeightController;
  late TextEditingController _shrubsProportionController;
  late TextEditingController _shrubsHeightController;
  late TextEditingController _treesProportionController;
  late TextEditingController _treesHeightController;
  late TextEditingController _notesController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _herbsProportionController = TextEditingController();
    _herbsHeightController = TextEditingController();
    _shrubsProportionController = TextEditingController();
    _shrubsHeightController = TextEditingController();
    _treesProportionController = TextEditingController();
    _treesHeightController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _herbsProportionController.dispose();
    _herbsHeightController.dispose();
    _shrubsProportionController.dispose();
    _shrubsHeightController.dispose();
    _treesProportionController.dispose();
    _treesHeightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Dados de Vegetação'),
        ),
        body: Column(
            children: [
              Expanded(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView( // Prevent keyboard overflow
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: const Text('Herbáceas'),
                        ),
                        const SizedBox(height: 8.0),
                        DropdownButtonFormField<DistributionType>(
                            value: _selectedHerbsDistribution,
                            decoration: const InputDecoration(
                              labelText: 'Distribuição',
                              border: OutlineInputBorder(),
                            ),
                            items: DistributionType.values.map((distribution) {
                              return DropdownMenuItem(
                                value: distribution,
                                child: Text(distributionTypeFriendlyNames[distribution]!),
                              );
                            }).toList(),
                            onChanged: (DistributionType? newValue) {
                              setState(() {
                                _selectedHerbsDistribution = newValue!;
                              });
                            }
                        ),
                        const SizedBox(height: 8.0),
                        _buildVegetationRow(_selectedHerbsDistribution, _herbsProportionController, _herbsHeightController),
                        const SizedBox(height: 8.0),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: const Text('Arbustos'),
                        ),
                        const SizedBox(height: 8.0),
                        DropdownButtonFormField<DistributionType>(
                            value: _selectedShrubsDistribution,
                            decoration: const InputDecoration(
                              labelText: 'Distribuição',
                              border: OutlineInputBorder(),
                            ),
                            items: DistributionType.values.map((distribution) {
                              return DropdownMenuItem(
                                value: distribution,
                                child: Text(distributionTypeFriendlyNames[distribution]!),
                              );
                            }).toList(),
                            onChanged: (DistributionType? newValue) {
                              setState(() {
                                _selectedShrubsDistribution = newValue!;
                              });
                            }
                        ),
                        const SizedBox(height: 8.0),
                        _buildVegetationRow(_selectedShrubsDistribution, _shrubsProportionController, _shrubsHeightController),
                        const SizedBox(height: 8.0),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: const Text('Árvores'),
                        ),
                        const SizedBox(height: 8.0),
                        DropdownButtonFormField<DistributionType>(
                            value: _selectedTreesDistribution,
                            decoration: const InputDecoration(
                              labelText: 'Distribuição',
                              border: OutlineInputBorder(),
                            ),
                            items: DistributionType.values.map((distribution) {
                              return DropdownMenuItem(
                                value: distribution,
                                child: Text(distributionTypeFriendlyNames[distribution]!),
                              );
                            }).toList(),
                            onChanged: (DistributionType? newValue) {
                              setState(() {
                                _selectedTreesDistribution = newValue!;
                              });
                            }
                        ),
                        const SizedBox(height: 8.0),
                        _buildVegetationRow(_selectedTreesDistribution, _treesProportionController, _treesHeightController),
                        const SizedBox(height: 16.0),
                        TextFormField(
                          controller: _notesController,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: const InputDecoration(
                            labelText: 'Observações',
                            border: OutlineInputBorder(),
                          ),
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
                      child: const Text('Salvar'),
                    ),
                  )
                ),
              ),
            ]
        )
    );
  }

  Widget _buildVegetationRow(DistributionType selectedDistribution, TextEditingController proportionController, TextEditingController heightController) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: proportionController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Proporção',
              border: OutlineInputBorder(),
              suffixText: '%',
            ),
            validator: (value) {
              if (selectedDistribution != DistributionType.disNone && (value == null || value.isEmpty)) {
                return 'Insira a proporção';
              }
              return null;
            },
          ),
        ),
        const SizedBox(width: 8.0),
        Expanded(
          child: TextFormField(
            controller: heightController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Altura',
              border: OutlineInputBorder(),
              suffixText: 'cm',
            ),
            validator: (value) {
              if (selectedDistribution != DistributionType.disNone && (value == null || value.isEmpty)) {
                return 'Insira a altura';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  void _submitForm() async {
    setState(() {
      _isSubmitting = true;
    });

    if (_formKey.currentState!.validate()) {
      Position? position = await getPosition();

      // Save the vegetation data
      final vegetation = Vegetation(
        inventoryId: widget.inventory.id,
        sampleTime: DateTime.now(),
        latitude: position?.latitude,
        longitude: position?.longitude,
        herbsProportion: int.tryParse(_herbsProportionController.text) ?? 0,
        herbsDistribution: _selectedHerbsDistribution,
        herbsHeight: int.tryParse(_herbsHeightController.text) ?? 0,
        shrubsProportion: int.tryParse(_shrubsProportionController.text) ?? 0,
        shrubsDistribution: _selectedShrubsDistribution,
        shrubsHeight: int.tryParse(_shrubsHeightController.text) ?? 0,
        treesProportion: int.tryParse(_treesProportionController.text) ?? 0,
        treesDistribution: _selectedTreesDistribution,
        treesHeight: int.tryParse(_treesHeightController.text) ?? 0,
        notes: _notesController.text,
      );

      setState(() {
        _isSubmitting = false;
      });

      final vegetationProvider = Provider.of<VegetationProvider>(context, listen: false);
      try {
        await vegetationProvider.addVegetation(context, widget.inventory.id, vegetation);
        Navigator.pop(context);
        // ScaffoldMessenger.of(context).showSnackBar(
        //   const SnackBar(content: Row(
        //     children: [
        //       Icon(Icons.check_circle_outlined, color: Colors.green),
        //       SizedBox(width: 8),
        //       Text('Dados de vegetação adicionados!'),
        //     ],
        //   ),
        //   ),
        // );
      } catch (error) {
        if (kDebugMode) {
          print('Error adding vegetation: $error');
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Row(
            children: [
              Icon(Icons.error_outlined, color: Colors.red),
              SizedBox(width: 8),
              Text('Erro ao salvar os dados de vegetação'),
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