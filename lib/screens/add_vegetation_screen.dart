import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/inventory.dart';
import '../data/database_helper.dart';

class AddVegetationDataScreen extends StatefulWidget {
  final Inventory inventory;
  final Function(Vegetation) onVegetationAdded;

  const AddVegetationDataScreen({
    super.key,
    required this.inventory,
    required this.onVegetationAdded
  });

  @override
  AddVegetationDataScreenState createState() => AddVegetationDataScreenState();
}

class AddVegetationDataScreenState extends State<AddVegetationDataScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _herbsProportionController;
  late TextEditingController _herbsDistributionController;
  late TextEditingController _herbsHeightController;
  late TextEditingController _shrubsProportionController;
  late TextEditingController _shrubsDistributionController;
  late TextEditingController _shrubsHeightController;
  late TextEditingController _treesProportionController;
  late TextEditingController _treesDistributionController;
  late TextEditingController _treesHeightController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _herbsProportionController = TextEditingController();
    _herbsDistributionController = TextEditingController();
    _herbsHeightController = TextEditingController();
    _shrubsProportionController = TextEditingController();
    _shrubsDistributionController = TextEditingController();
    _shrubsHeightController = TextEditingController();
    _treesProportionController = TextEditingController();
    _treesDistributionController = TextEditingController();
    _treesHeightController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _herbsProportionController.dispose();
    _herbsDistributionController.dispose();
    _herbsHeightController.dispose();
    _shrubsProportionController.dispose();
    _shrubsDistributionController.dispose();
    _shrubsHeightController.dispose();
    _treesProportionController.dispose();
    _treesDistributionController.dispose();
    _treesHeightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Novos Dados de Vegetação'),
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Text('Herbáceas',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              _buildVegetationRow(_herbsProportionController, _herbsDistributionController, _herbsHeightController),
              const Text('Arbustos',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              _buildVegetationRow(_shrubsProportionController, _shrubsDistributionController, _shrubsHeightController),
              const Text('Árvores',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              _buildVegetationRow(_treesProportionController, _treesDistributionController, _treesHeightController),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Observações',
                ),
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    Position position = await Geolocator.getCurrentPosition(
                      locationSettings: LocationSettings(
                    accuracy: LocationAccuracy.high,
                  ),
                    );

                    // Save the vegetation data
                    final vegetation = Vegetation(
                      inventoryId: widget.inventory.id,
                      sampleTime: DateTime.now(),
                      latitude: position.latitude,
                      longitude: position.longitude,
                      herbsProportion: int.tryParse(_herbsProportionController.text) ?? 0,
                      herbsDistribution: int.tryParse(_herbsDistributionController.text) ?? 0,
                      herbsHeight: int.tryParse(_herbsHeightController.text) ?? 0,
                      shrubsProportion: int.tryParse(_shrubsProportionController.text) ?? 0,
                      shrubsDistribution: int.tryParse(_shrubsDistributionController.text) ?? 0,
                      shrubsHeight: int.tryParse(_shrubsHeightController.text) ?? 0,
                      treesProportion: int.tryParse(_treesProportionController.text) ?? 0,
                      treesDistribution: int.tryParse(_treesDistributionController.text) ?? 0,
                      treesHeight: int.tryParse(_treesHeightController.text) ?? 0,
                      notes: _notesController.text,
                    );
                    int? result = await DatabaseHelper().insertVegetation(vegetation).then((result) {
                      if (result != 0) {
                        // Successful insert
                        widget.onVegetationAdded(vegetation);
                        Navigator.pop(context);
                        return result;
                      } else {
                        // Insert failed
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Erro ao salvar os dados de vegetação')),
                        );
                        return null;
                      }
                    }).catchError((error) {
                      if (kDebugMode) {
                        print('Error inserting vegetation data: $error');
                      }
                      return null;
                    });
                  }
                },
                child: const Text('Salvar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVegetationRow(TextEditingController proportionController, TextEditingController distributionController, TextEditingController heightController) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: proportionController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Proporção %',
            ),
          ),
        ),
        const SizedBox(width: 8.0),
        Expanded(
          child: TextFormField(
            controller: distributionController,
            decoration: const InputDecoration(
              labelText: 'Distribuição',
            ),
          ),
        ),
        const SizedBox(width: 8.0),
        Expanded(
          child: TextFormField(
            controller: heightController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Altura cm',
            ),
          ),
        ),
      ],
    );
  }
}