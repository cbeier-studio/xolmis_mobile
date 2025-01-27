import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../data/models/nest.dart';
import '../../providers/egg_provider.dart';

import '../../utils/utils.dart';
import '../../generated/l10n.dart';

class AddEggScreen extends StatefulWidget {
  final Nest nest;
  final Egg? egg;
  final bool isEditing;
  final String? initialFieldNumber;
  final String? initialSpeciesName;

  const AddEggScreen({
    super.key,
    required this.nest,
    this.egg,
    this.isEditing = false,
    this.initialFieldNumber,
    this.initialSpeciesName
  });

  @override
  AddEggScreenState createState() => AddEggScreenState();
}

class AddEggScreenState extends State<AddEggScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fieldNumberController;
  late TextEditingController _speciesNameController;
  EggShapeType _selectedEggShape = EggShapeType.estOval;
  late TextEditingController _widthController;
  late TextEditingController _lengthController;
  late TextEditingController _massController;
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
    _fieldNumberController = TextEditingController();
    _speciesNameController = TextEditingController();
    _widthController = TextEditingController();
    _lengthController = TextEditingController();
    _massController = TextEditingController();

    if (widget.isEditing) {
      _fieldNumberController.text = widget.egg!.fieldNumber!;
      _speciesNameController.text = widget.egg!.speciesName!;
      _selectedEggShape = widget.egg!.eggShape;
      _widthController.text = widget.egg!.width != null ? widget.egg!.width.toString() : '';
      _lengthController.text = widget.egg!.length != null ? widget.egg!.length.toString() : '';
      _massController.text = widget.egg!.mass != null ? widget.egg!.mass.toString() : '';
    } else {
      _fieldNumberController.text = widget.initialFieldNumber ?? '';
      _speciesNameController.text = widget.initialSpeciesName ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(S.of(context).addEgg),
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
                          decoration: InputDecoration(
                            labelText: '${S.of(context).fieldNumber} *',
                            helperText: S.of(context).requiredField,
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return S.of(context).insertFieldNumber;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16.0),
                        SearchAnchor(
                      builder: (context, controller) {
                        return TextFormField(
                          controller: _speciesNameController,
                          decoration: InputDecoration(
                            labelText: '${S.of(context).species(1)} *',
                            helperText: S.of(context).requiredField,
                            border: OutlineInputBorder(),
                          ),
                          readOnly: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return S.of(context).selectSpecies;
                            }
                            return null;
                          },
                          onTap: () {
                            controller.openView();
                          },
                        );
                      },
                      suggestionsBuilder: (context, controller) {
                        return List<String>.from(allSpeciesNames)
                            .where((species) => speciesMatchesQuery(
                                species, controller.text.toLowerCase()))
                            .map((species) {
                          return ListTile(
                            title: Text(species),
                            onTap: () async {
                              setState(() {
                                _speciesNameController.text = species;
                              });
                              controller.closeView(species);
                              controller.clear();
                            },
                          );
                        }).toList();
                      }
                        ),                        
                        const SizedBox(height: 16.0),
                        DropdownButtonFormField<EggShapeType>(
                            value: _selectedEggShape,
                            decoration: InputDecoration(
                              labelText: '${S.of(context).eggShape} *',
                              helperText: S.of(context).requiredField,
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
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}$'))],
                          decoration: InputDecoration(
                            labelText: S.of(context).width,
                            border: OutlineInputBorder(),
                            suffixText: 'mm',
                          ),
                        ),
                        const SizedBox(height: 16.0),
                        TextFormField(
                          controller: _lengthController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}$'))],
                          decoration: InputDecoration(
                            labelText: S.of(context).length,
                            border: OutlineInputBorder(),
                            suffixText: 'mm',
                          ),
                        ),
                        const SizedBox(height: 16.0),
                        TextFormField(
                          controller: _massController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$'))],
                          decoration: InputDecoration(
                            labelText: S.of(context).weight,
                            border: OutlineInputBorder(),
                            suffixText: 'g',
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
                        child: Text(S.of(context).save),
                      ),
                    )
                ),
              ),
            ]
        )
    );
  }

  void _submitForm() async {
    final eggProvider = Provider.of<EggProvider>(context, listen: false);

    if (_formKey.currentState!.validate()) {
      if (widget.isEditing) {
        final updatedEgg = widget.egg!.copyWith(
          fieldNumber: _fieldNumberController.text,
          speciesName: _speciesNameController.text,
          eggShape: _selectedEggShape,
          width: double.tryParse(_widthController.text),
          length: double.tryParse(_lengthController.text),
          mass: double.tryParse(_massController.text),
        );

        try {        
          await eggProvider.updateEgg(updatedEgg);

          Navigator.pop(context);
        } catch (error) {
          if (kDebugMode) {
            print('Error saving egg: $error');
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error_outlined, color: Colors.red),
                  SizedBox(width: 8),
                  Text(S.current.errorSavingEgg),
                ],
              ),
            ),
          );
        }
      } else {
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
        } catch (error) {
          if (kDebugMode) {
            print('Error adding egg: $error');
          }
          if (error.toString().contains(S.current.errorEggAlreadyExists)) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.info_outlined, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(S.current.errorEggAlreadyExists),
                  ],
                ),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.error_outlined, color: Colors.red),
                    SizedBox(width: 8),
                    Text(S.current.errorSavingEgg),
                  ],
                ),
              ),
            );
          }
        }
      }
    } else {
      setState(() {
        _isSubmitting = false;
      });
    }
  }
}