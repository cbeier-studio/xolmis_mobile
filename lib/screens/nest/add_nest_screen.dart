import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../../data/models/nest.dart';
import '../../providers/nest_provider.dart';

import '../utils.dart';
import '../species_search_delegate.dart';

class AddNestScreen extends StatefulWidget {
  const AddNestScreen({super.key});

  @override
  _AddNestScreenState createState() => _AddNestScreenState();
}

class _AddNestScreenState extends State<AddNestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fieldNumberController = TextEditingController();
  final _speciesNameController = TextEditingController();
  final _localityNameController = TextEditingController();
  final _supportController = TextEditingController();
  final _heightAboveGroundController = TextEditingController();
  final _maleController = TextEditingController();
  final _femaleController = TextEditingController();
  final _helpersController = TextEditingController();
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

  void _addSpeciesToNest(String speciesName) async {
    // Empty
  }

  void _updateNest() async {
    // Empty
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Novo Ninho'),
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
                            final speciesSearchDelegate = SpeciesSearchDelegate(allSpecies, _addSpeciesToNest, _updateNest);
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
                          controller: _supportController,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: const InputDecoration(
                            labelText: 'Suporte do ninho',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor, insira o suporte do ninho';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16.0),
                        TextFormField(
                          controller: _heightAboveGroundController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Altura acima do solo',
                            border: OutlineInputBorder(),
                            suffixText: 'm',
                          ),
                        ),
                        const SizedBox(height: 16.0),
                        TextFormField(
                          controller: _maleController,
                          decoration: const InputDecoration(
                            labelText: 'Macho',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16.0),
                        TextFormField(
                          controller: _femaleController,
                          decoration: const InputDecoration(
                            labelText: 'Fêmea',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16.0),
                        TextFormField(
                          controller: _helpersController,
                          decoration: const InputDecoration(
                            labelText: 'Ajudantes de ninho',
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
                    child: _isSubmitting
                        ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton(
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

  void _submitForm() async {
    final nestProvider = Provider.of<NestProvider>(context, listen: false);

    if (_formKey.currentState!.validate()) {
      // Create Nest object with form data
      final newNest = Nest(
        fieldNumber: _fieldNumberController.text,
        speciesName: _speciesNameController.text,
        localityName: _localityNameController.text,
        longitude: _currentPosition?.longitude,
        latitude: _currentPosition?.latitude,
        support: _supportController.text,
        heightAboveGround: double.tryParse(_heightAboveGroundController.text),
        male: _maleController.text,
        female: _femaleController.text,
        helpers: _helpersController.text,
        foundTime: DateTime.now(),
        isActive: true,
        nestFate: NestFateType.fatUnknown,
      );

      setState(() {
        _isSubmitting = false;
      });

      try {
        await nestProvider.addNest(newNest);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Row(
            children: [
              Icon(Icons.check_circle_outlined, color: Colors.green),
              SizedBox(width: 8),
              Text('Ninho adicionado!'),
            ],
          ),
          ),
        );
      } catch (error) {
        if (kDebugMode) {
          print('Error adding nest: $error');
        }
        if (error.toString().contains('Já existe um ninho com este número de campo.')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content:
            Row(
              children: [
                Icon(Icons.info_outlined, color: Colors.blue),
                SizedBox(width: 8),
                Text('Já existe um ninho com este número de campo.'),
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
                Text('Erro ao salvar o ninho'),
              ],
            ),
            ),
          );
        }
      }
    }
  }
}