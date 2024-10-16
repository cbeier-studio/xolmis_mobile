import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'inventory.dart';
import 'database_helper.dart';

class AddVegetationDataScreen extends StatefulWidget {
  final Inventory inventory;

  const AddVegetationDataScreen({Key? key,required this.inventory}) : super(key: key);

  @override
  _AddVegetationDataScreenState createState() => _AddVegetationDataScreenState();
}

class _AddVegetationDataScreenState extends State<AddVegetationDataScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _herbsProportionController;
  late TextEditingController _herbsDistributionController;
  late TextEditingController _herbsHeightController;
  late TextEditingController _shrubsProportionController;
  late TextEditingController _shrubsDistributionController;
  late TextEditingController _shrubsHeightController;late TextEditingController _treesProportionController;
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
        title: const Text('Adicionar Dados de Vegetação'),
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildVegetationRow('Ervas', _herbsProportionController, _herbsDistributionController, _herbsHeightController),
              _buildVegetationRow('Arbustos', _shrubsProportionController, _shrubsDistributionController, _shrubsHeightController),
              _buildVegetationRow('Árvores', _treesProportionController, _treesDistributionController, _treesHeightController),
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
                      desiredAccuracy: LocationAccuracy.high,
                    );

                    // Salve os dados de vegetação
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
                    DatabaseHelper().insertVegetation(vegetation);
                    Navigator.pop(context); // Volte para a tela anterior
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

  Widget _buildVegetationRow(String label, TextEditingController proportionController, TextEditingController distributionController, TextEditingController heightController) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: proportionController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: '$label - Proporção',
            ),
          ),
        ),
        const SizedBox(width: 8.0),
        Expanded(
          child: TextFormField(
            controller: distributionController,
            decoration: InputDecoration(
              labelText: '$label - Distribuição',
            ),
          ),
        ),
        const SizedBox(width: 8.0),
        Expanded(
          child: TextFormField(
            controller: heightController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: '$label - Altura',
            ),
          ),
        ),
      ],
    );
  }
}