import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  String _observerAcronym = '';

  @override
  void initState() {
    super.initState();
    _nextFieldNumber();
    _getCurrentLocation();
  }

  Future<void> _nextFieldNumber() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _observerAcronym = prefs.getString('observerAcronym') ?? '';
    });

    final ano = DateTime.now().year;
    final mes = DateTime.now().month;

    final numSeq = Provider.of<SpecimenProvider>(context, listen: false).specimens.length + 1;

    _fieldNumberController.text = "$_observerAcronym$ano${mes.toString().padLeft(2, '0')}${numSeq.toString().padLeft(4, '0')}";
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
                            labelText: 'Número de Campo *',
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
                            labelText: 'Tipo de Espécime *',
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
                            labelText: 'Espécie *',
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
                            // final allSpecies = await loadSpeciesSearchData();
                            // allSpecies.sort((a, b) => a.compareTo(b));
                            final speciesSearchDelegate = SpeciesSearchDelegate(allSpeciesNames, _addSpeciesToSpecimen, _updateSpecimen);
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
                        Autocomplete<String>(
                          optionsBuilder: (TextEditingValue textEditingValue) async {
                            if (textEditingValue.text == '') {
                              return const Iterable<String>.empty();
                            }

                            final options = await Provider.of<SpecimenProvider>(context, listen: false).getDistinctLocalities();
                            return options.where((String option) {
                              return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                            });
                          },
                          onSelected: (String selection) {
                            _localityNameController.text = selection;
                          },
                          fieldViewBuilder: (BuildContext context, TextEditingController fieldTextEditingController, FocusNode fieldFocusNode, VoidCallback onFieldSubmitted) {
                            return TextFormField(
                              controller: _localityNameController,
                              focusNode: fieldFocusNode,
                              textCapitalization: TextCapitalization.words,
                              decoration: const InputDecoration(
                                labelText: 'Localidade *',
                                helperText: '* campo obrigatório',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor, insira o nome da localidade';
                                }
                                return null;
                              },
                              onFieldSubmitted: (String value) {
                                onFieldSubmitted();
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 16.0),
                        TextFormField(
                          controller: _notesController,
                          maxLines: 3,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: const InputDecoration(
                            labelText: 'Observações',
                            helperText: '* opcional',
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
        // ScaffoldMessenger.of(context).showSnackBar(
        //   const SnackBar(content: Row(
        //     children: [
        //       Icon(Icons.check_circle_outlined, color: Colors.green),
        //       SizedBox(width: 8),
        //       Text('Espécime adicionado!'),
        //     ],
        //   ),
        //   ),
        // );
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
    } else {
      setState(() {
        _isSubmitting = false;
      });
    }
  }
}