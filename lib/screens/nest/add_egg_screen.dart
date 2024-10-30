import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/nest.dart';
import '../../providers/egg_provider.dart';

import '../utils.dart';
import '../species_search_delegate.dart';

class AddEggScreen extends StatefulWidget {
  final Nest nest;
  final String? initialFieldNumber;
  final String? initialSpeciesName;

  const AddEggScreen({super.key, required this.nest, this.initialFieldNumber, this.initialSpeciesName});

  @override
  _AddEggScreenState createState() => _AddEggScreenState();
}

class _AddEggScreenState extends State<AddEggScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fieldNumberController = TextEditingController();
  final _speciesNameController = TextEditingController();
  EggShapeType _selectedEggShape = EggShapeType.estOval;
  final _widthController = TextEditingController();
  final _lengthController = TextEditingController();
  final _massController = TextEditingController();
  bool _isSubmitting = false;

  void _addSpeciesToEgg(String speciesName) async {
    // Empty
  }

  void _updateEgg() async {
    // Empty
  }

  @override
  void initState() {
    super.initState();
    _fieldNumberController.text = widget.initialFieldNumber ?? '';
    _speciesNameController.text = widget.initialSpeciesName ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adicionar Ovo'),
          actions: [
            _isSubmitting
                ? CircularProgressIndicator()
                : TextButton(
              onPressed: _submitForm,
              child: const Text('Salvar'),
            ),
          ]
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView( // Prevent keyboard overflow
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextFormField(
                controller: _fieldNumberController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Número de Campo',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira o número de campo';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _speciesNameController,
                decoration: const InputDecoration(
                  labelText: 'Espécie',
                  border: OutlineInputBorder(),
                ),
                readOnly: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, selecione uma espécie';
                  }
                  return null;
                },
                onTap: () async {
                  final allSpecies = await loadSpeciesSearchData();
                  allSpecies.sort((a, b) => a.compareTo(b));
                  final speciesSearchDelegate = SpeciesSearchDelegate(allSpecies, _addSpeciesToEgg, _updateEgg);
                  final selectedSpecies = await showSearch(
                    context: context,
                    delegate: speciesSearchDelegate,
                  );

                  if (selectedSpecies != null) {
                    setState(() {
                      _speciesNameController.text = selectedSpecies;
                    });
                  }
                },
              ),
              const SizedBox(height: 16.0),
              DropdownButtonFormField<EggShapeType>(
                  value: _selectedEggShape,
                  decoration: const InputDecoration(
                    labelText: 'Forma do ovo',
                    border: OutlineInputBorder(),
                  ),
                  items: EggShapeType.values.map((eggShape) {
                    return DropdownMenuItem(
                      value: eggShape,
                      child: Text(eggShapeTypeFriendlyNames[eggShape]!),
                    );
                  }).toList(),
                  onChanged: (EggShapeType? newValue) {
                    setState(() {
                      _selectedEggShape = newValue!;
                    });
                  }
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _widthController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Largura',
                  border: OutlineInputBorder(),
                  suffixText: 'mm',
                ),
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _lengthController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Comprimento',
                  border: OutlineInputBorder(),
                  suffixText: 'mm',
                ),
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _massController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Massa',
                  border: OutlineInputBorder(),
                  suffixText: 'g',
                ),
              ),
              // const SizedBox(height: 16.0),
              // ElevatedButton(
              //   onPressed: () async {
              //
              //   },
              //   child: _isSubmitting
              //       ? const CircularProgressIndicator()
              //       : const Text('Salvar'),
              // ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitForm() async {
    final eggProvider = Provider.of<EggProvider>(context, listen: false);

    if (_formKey.currentState!.validate()) {
      // Create Nest object with form data
      final newEgg = Egg(
        fieldNumber: _fieldNumberController.text,
        speciesName: _speciesNameController.text,
        eggShape: _selectedEggShape,
        width: double.tryParse(_widthController.text),
        length: double.tryParse(_lengthController.text),
        mass: double.tryParse(_massController.text),
        sampleTime: DateTime.now(),
      );

      setState(() {
        _isSubmitting = false;
      });

      try {
        await eggProvider.addEgg(context, widget.nest.id!, newEgg);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Row(
            children: [
              Icon(Icons.check_circle_outlined, color: Colors.green),
              SizedBox(width: 8),
              Text('Ovo adicionado!'),
            ],
          ),
          ),
        );
      } catch (error) {
        if (kDebugMode) {
          print('Error adding egg: $error');
        }
        if (error.toString().contains('Já existe um ovo com este número de campo.')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content:
            Row(
              children: [
                Icon(Icons.info_outlined, color: Colors.blue),
                SizedBox(width: 8),
                Text('Já existe um ovo com este número de campo.'),
              ],
            ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content:
            Row(
              children: [
                Icon(Icons.error_outlined, color: Colors.red),
                SizedBox(width: 8),
                Text('Erro ao salvar o ovo'),
              ],
            ),
            ),
          );
        }
      }
    }
  }
}