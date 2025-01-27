import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/specimen.dart';
import '../../providers/specimen_provider.dart';
import '../../utils/utils.dart';
import '../../utils/species_search_delegate.dart';
import '../../generated/l10n.dart';

class AddSpecimenScreen extends StatefulWidget {
  final Specimen? specimen;
  final bool isEditing;

  const AddSpecimenScreen({
    super.key,
    this.specimen,
    this.isEditing = false,
  });

  @override
  AddSpecimenScreenState createState() => AddSpecimenScreenState();
}

class AddSpecimenScreenState extends State<AddSpecimenScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fieldNumberController;
  late TextEditingController _speciesNameController;
  late TextEditingController _localityNameController;
  late TextEditingController _notesController;
  late TextEditingController _fieldLocalityEditingController;
  SpecimenType _selectedType = SpecimenType.spcFeathers;
  bool _isSubmitting = false;
  Position? _currentPosition;
  String _observerAcronym = '';

  @override
  void initState() {
    super.initState();
    _fieldNumberController = TextEditingController();
    _speciesNameController = TextEditingController();
    _localityNameController = TextEditingController(text: widget.specimen?.locality ?? '');
    _fieldLocalityEditingController = TextEditingController(text: widget.specimen?.locality ?? '');
    _notesController = TextEditingController();
    
    if (widget.isEditing) {
      _selectedType = widget.specimen!.type;
      _fieldNumberController.text = widget.specimen!.fieldNumber;
      _speciesNameController.text = widget.specimen!.speciesName ?? '';
      _localityNameController.text = widget.specimen!.locality ?? '';
      _fieldLocalityEditingController.text = widget.specimen!.locality ?? '';
      _notesController.text = widget.specimen!.notes ?? '';
    } else {
      _nextFieldNumber();
      _getCurrentLocation();
    }
  }

  Future<void> _nextFieldNumber() async {
    final specimenProvider = Provider.of<SpecimenProvider>(context, listen: false);
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _observerAcronym = prefs.getString('observerAcronym') ?? '';
    });

    final ano = DateTime.now().year;
    final mes = DateTime.now().month;

    final numSeq = await specimenProvider.getNextSequentialNumber(_observerAcronym, ano, mes);

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
          title: Text(S.of(context).newSpecimen),
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
                        DropdownButtonFormField<SpecimenType>(
                          value: _selectedType,
                          decoration: InputDecoration(
                            labelText: '${S.of(context).specimenType} *',
                            border: OutlineInputBorder(),
                          ),
                          items: SpecimenType.values.map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Text(specimenTypeFriendlyNames[type]!),
                            );
                          }).toList(),
                          onChanged: (SpecimenType? newValue) {
                            setState(() {
                              _selectedType = newValue!;
                            });
                          },
                        ),
                        const SizedBox(height: 16.0),
                        SearchAnchor(
                      builder: (context, controller) {
                        return TextFormField(
                          controller: _speciesNameController,
                          decoration: InputDecoration(
                            labelText: '${S.of(context).species(1)} *',
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
                            _fieldLocalityEditingController.text = selection;
                          },
                          fieldViewBuilder: (BuildContext context, TextEditingController fieldTextEditingController, FocusNode fieldFocusNode, VoidCallback onFieldSubmitted) {
                            _fieldLocalityEditingController = fieldTextEditingController;
                            if (widget.isEditing && !_isSubmitting) {                              
                              _fieldLocalityEditingController.text = widget.specimen?.locality ?? '';
                            }                            
                            return TextFormField(
                              controller: _fieldLocalityEditingController,
                              focusNode: fieldFocusNode,
                              textCapitalization: TextCapitalization.words,
                              decoration: InputDecoration(
                                labelText: '${S.of(context).locality} *',
                                helperText: S.of(context).requiredField,
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return S.of(context).insertLocality;
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
                          decoration: InputDecoration(
                            labelText: S.of(context).notes,
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
    final specimenProvider = Provider.of<SpecimenProvider>(context, listen: false);
    setState(() {
      _isSubmitting = true;
    });

    if (_formKey.currentState!.validate()) {
      if (widget.isEditing) {
        final updatedSpecimen = widget.specimen!.copyWith(
          fieldNumber: _fieldNumberController.text,
          speciesName: _speciesNameController.text,
          locality: _fieldLocalityEditingController.text,
          notes: _notesController.text,
          type: _selectedType,
        );

        try {
          await specimenProvider.updateSpecimen(updatedSpecimen);

          Navigator.pop(context);
        } catch (error) {
          if (kDebugMode) {
            print('Error saving specimen: $error');
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error_outlined, color: Colors.red),
                  SizedBox(width: 8),
                  Text(S.current.errorSavingSpecimen),
                ],
              ),
            ),
          );
        }
      } else {
        // Create Nest object with form data
        final newSpecimen = Specimen(
          fieldNumber: _fieldNumberController.text,
          speciesName: _speciesNameController.text,
          locality: _fieldLocalityEditingController.text,
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
        } catch (error) {
          if (kDebugMode) {
            print('Error adding specimen: $error');
          }
          if (error.toString().contains(S.current.errorSpecimenAlreadyExists)) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.info_outlined, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(S.current.errorSpecimenAlreadyExists),
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
                    Text(S.current.errorSavingSpecimen),
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