import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../models/nest.dart';
import '../providers/nest_provider.dart';
import 'inventory_detail_helpers.dart';
import 'species_search_delegate.dart';

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
    bool serviceEnabled;
    LocationPermission permission;

    // Verificar se os serviços de localização estão habilitados.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Os serviços de localização não estão habilitados.
      return Future.error('Os serviços de localização estão desabilitados.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // As permissões foram negadas permanentemente, não podemos solicitar permissões.
        return Future.error(
            'As permissões de localização foram negadas permanentemente.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // As permissões foram negadas permanentemente, não podemos solicitar permissões.
      return Future.error(
          'As permissões de localização foram negadas permanentemente.');
    }

    // Quando chegamos aqui, as permissões são concedidas e podemos
    // continuar acessando a posição do usuário.
    _currentPosition = await Geolocator.getCurrentPosition();
    setState(() {}); // Atualizar a tela com a localização
  }

  void _addSpeciesToNest(String speciesName) async {
    // Empty
  }

  void _updateNest() async {
    // Empty
  }

  @override
  Widget build(BuildContext context) {
    final nestProvider = Provider.of<NestProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adicionar Ninho'),
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
                  final allSpecies = await loadSpeciesData();
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
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    // Create Nest object with form data
                    final newNest = Nest(
                      fieldNumber: _fieldNumberController.text,
                      speciesName: _speciesNameController.text,
                      localityName: _localityNameController.text,
                      longitude: _currentPosition!.longitude,
                      latitude: _currentPosition!.latitude,
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
                            Icon(Icons.check, color: Colors.green),
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Row(
                          children: [
                            Icon(Icons.error, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Erro ao salvar o ninho'),
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
}