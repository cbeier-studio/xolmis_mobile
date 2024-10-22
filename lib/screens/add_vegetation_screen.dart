import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../models/inventory.dart';
import '../providers/vegetation_provider.dart';

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
  bool _isSubmitting = false;

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
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Observações',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _isSubmitting ? null : () async {
                  setState(() {
                    _isSubmitting = true;
                  });

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

                    setState(() {
                      _isSubmitting = false;
                    });

                    final vegetationProvider = Provider.of<VegetationProvider>(context, listen: false);
                    try {
                      await vegetationProvider.addVegetation(context, widget.inventory.id, vegetation);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Row(
                          children: [
                            Icon(Icons.check, color: Colors.green),
                            SizedBox(width: 8),
                            Text('Dados de vegetação adicionados!'),
                          ],
                        ),
                        ),
                      );
                    } catch (error) {
                      if (kDebugMode) {
                        print('Error adding vegetation: $error');
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Row(
                          children: [
                            Icon(Icons.error, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Erro ao salvar os dados de vegetação'),
                          ],
                        ),
                        ),
                      );
                    }
                  }
                },
                child: _isSubmitting
                    ? const CircularProgressIndicator()
                    : const Text('Salvar'),
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
              labelText: 'Proporção',
              border: OutlineInputBorder(),
              suffixText: '%',
            ),
          ),
        ),
        const SizedBox(width: 8.0),
        Expanded(
          child: TextFormField(
            controller: distributionController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Distribuição',
              border: OutlineInputBorder(),
            ),
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
          ),
        ),
      ],
    );
  }
}