import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../../data/models/specimen.dart';
import '../../providers/specimen_provider.dart';
import '../utils.dart';
import '../species_search_delegate.dart';

class AddSpecimenScreen extends StatefulWidget {
  const AddSpecimenScreen({super.key});

  @override
  _AddSpecimenScreenState createState() => _AddSpecimenScreenState();
}

class _AddSpecimenScreenState extends State<AddSpecimenScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fieldNumberController = TextEditingController();
  final _speciesNameController = TextEditingController();
  final _localityNameController = TextEditingController();
  final _notesController = TextEditingController();
  SpecimenType _selectedType = SpecimenType.spcFeathers;
  bool _isSubmitting = false;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    Position? position = await getPosition();
    if (position != null) {
      setState(() {
        _currentPosition = position;
      });
    } else {
      // Mostrar campos de latitude e longitude para preenchimento manual
      // ...
    }
  }

  void _addSpeciesToSpecimen(String speciesName) async {
    // Empty
  }

  void _updateSpecimen() async {
    // Empty
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('Novo Espécime'),
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
              DropdownButtonFormField<SpecimenType>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Tipo de Espécime',
                  border: OutlineInputBorder(),
                ),
                items: SpecimenType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(specimenTypeFriendlyNames[type]!),
                  );
                }).toList(),
                onChanged: (SpecimenType? newValue) {
                  setState(() async {
                    _selectedType = newValue!;
                  });
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
                  final allSpecies = await loadSpeciesData();
                  allSpecies.sort((a, b) => a.compareTo(b));
                  final speciesSearchDelegate = SpeciesSearchDelegate(allSpecies, _addSpeciesToSpecimen, _updateSpecimen);
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
              TextFormField(
                controller: _localityNameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Localidade',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira o nome da localidade';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Observações',
                  border: OutlineInputBorder(),
                ),
              ),
              // const SizedBox(height: 16.0),
              // ElevatedButton(
              //   onPressed: () async {
              //     _submitForm();
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
    final specimenProvider = Provider.of<SpecimenProvider>(context, listen: false);

    if (_formKey.currentState!.validate()) {
      // Create Nest object with form data
      final newSpecimen = Specimen(
        fieldNumber: _fieldNumberController.text,
        speciesName: _speciesNameController.text,
        locality: _localityNameController.text,
        longitude: _currentPosition?.longitude,
        latitude: _currentPosition?.latitude,
        notes: _notesController.text,
        type: _selectedType,
        sampleTime: DateTime.now(),
      );

      setState(() {
        _isSubmitting = false;
      });

      try {
        await specimenProvider.addSpecimen(newSpecimen);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Row(
            children: [
              Icon(Icons.check_circle_outlined, color: Colors.green),
              SizedBox(width: 8),
              Text('Espécime adicionado!'),
            ],
          ),
          ),
        );
      } catch (error) {
        if (kDebugMode) {
          print('Error adding specimen: $error');
        }
        if (error.toString().contains('Já existe um espécime com este número de campo.')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content:
            Row(
              children: [
                Icon(Icons.info_outlined, color: Colors.blue),
                SizedBox(width: 8),
                Text('Já existe um espécime com este número de campo.'),
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
                Text('Erro ao salvar o espécime'),
              ],
            ),
            ),
          );
        }
      }
    }
  }
}