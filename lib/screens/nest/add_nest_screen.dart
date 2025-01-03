import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/nest.dart';
import '../../providers/nest_provider.dart';

import '../../utils/utils.dart';
import '../../utils/species_search_delegate.dart';
import '../../generated/l10n.dart';

class AddNestScreen extends StatefulWidget {
  final Nest? nest;
  final bool isEditing;

  const AddNestScreen({
    super.key,
    this.nest,
    this.isEditing = false,
  });

  @override
  AddNestScreenState createState() => AddNestScreenState();
}

class AddNestScreenState extends State<AddNestScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fieldNumberController;
  late TextEditingController _speciesNameController;
  late TextEditingController _localityNameController;
  late TextEditingController _supportController;
  late TextEditingController _heightAboveGroundController;
  late TextEditingController _maleController;
  late TextEditingController _femaleController;
  late TextEditingController _helpersController;
  late TextEditingController _fieldLocalityEditingController;
  late TextEditingController _fieldSupportEditingController;
  bool _isSubmitting = false;
  Position? _currentPosition;
  String _observerAcronym = '';

  @override
  void initState() {
    super.initState();
    _fieldNumberController = TextEditingController();
    _speciesNameController = TextEditingController();
    _localityNameController = TextEditingController();
    _supportController = TextEditingController();
    _heightAboveGroundController = TextEditingController();
    _maleController = TextEditingController();
    _femaleController = TextEditingController();
    _helpersController = TextEditingController();
    _fieldLocalityEditingController = TextEditingController();
    _fieldSupportEditingController = TextEditingController();

  if (widget.isEditing) {
      _fieldNumberController.text = widget.nest!.fieldNumber!;
      _speciesNameController.text = widget.nest!.speciesName!;
      _localityNameController.text = widget.nest!.localityName!;
      _supportController.text = widget.nest!.support!;
      _heightAboveGroundController.text = widget.nest!.heightAboveGround != null
          ? widget.nest!.heightAboveGround.toString()
          : '';
      _maleController.text = widget.nest!.male!;
      _femaleController.text = widget.nest!.female!;
      _helpersController.text = widget.nest!.helpers!;
    } else {
      _nextFieldNumber();
      _getCurrentLocation();
    }
  }

  Future<void> _nextFieldNumber() async {
    final nestProvider = Provider.of<NestProvider>(context, listen: false);
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _observerAcronym = prefs.getString('observerAcronym') ?? '';
    });

    final ano = DateTime.now().year;
    final mes = DateTime.now().month;
    final numSeq = await nestProvider.getNextSequentialNumber(_observerAcronym, ano, mes);

    _fieldNumberController.text = "$_observerAcronym$ano${mes.toString().padLeft(2, '0')}${numSeq.toString().padLeft(3, '0')}";
  }

  Future<void> _getCurrentLocation() async {
    Position? position = await getPosition();
    if (position != null) {
      setState(() {
        _currentPosition = position;
      });
    } else {
      // Show latitude and longitude fields to fill manually
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
          title: Text(S.of(context).newNest),
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
                        TextFormField(
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
                          onTap: () async {
                            // final allSpecies = await loadSpeciesSearchData();
                            // allSpecies.sort((a, b) => a.compareTo(b));
                            final speciesSearchDelegate = SpeciesSearchDelegate(allSpeciesNames, _addSpeciesToNest, _updateNest);
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

                            final options = await Provider.of<NestProvider>(context, listen: false).getDistinctLocalities();
                            return options.where((String option) {
                              return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                            });
                          },
                          onSelected: (String selection) {
                            _localityNameController.text = selection;
                            _fieldLocalityEditingController.text = selection;
                          },
                          fieldViewBuilder: (BuildContext context, TextEditingController fieldTextEditingController, FocusNode fieldFocusNode, VoidCallback onFieldSubmitted) {
                            // _fieldLocalityEditingController = fieldTextEditingController;
                            if (widget.isEditing && !_isSubmitting) {                              
                              _fieldLocalityEditingController.text = widget.nest?.localityName ?? '';
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
                        Autocomplete<String>(
                          optionsBuilder: (TextEditingValue textEditingValue) async {
                            if (textEditingValue.text == '') {
                              return const Iterable<String>.empty();
                            }

                            final options = await Provider.of<NestProvider>(context, listen: false).getDistinctSupports();
                            return options.where((String option) {
                              return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                            });
                          },
                          onSelected: (String selection) {
                            _supportController.text = selection;
                            _fieldSupportEditingController.text = selection;
                          },
                          fieldViewBuilder: (BuildContext context, TextEditingController fieldTextEditingController, FocusNode fieldFocusNode, VoidCallback onFieldSubmitted) {
                            // _fieldSupportEditingController = fieldTextEditingController;
                            if (widget.isEditing && !_isSubmitting) {                              
                              _fieldSupportEditingController.text = widget.nest?.support ?? '';
                            }
                            return TextFormField(
                              controller: _fieldSupportEditingController,
                              focusNode: fieldFocusNode,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: InputDecoration(
                                labelText: '${S.of(context).nestSupport} *',
                                helperText: S.of(context).requiredField,
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return S.of(context).insertNestSupport;
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
                          controller: _heightAboveGroundController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: S.of(context).heightAboveGround,
                            border: OutlineInputBorder(),
                            suffixText: 'm',
                          ),
                          inputFormatters: [
                            CommaToDotTextInputFormatter(),
                            // Allow only numbers and decimal separator with 2 decimal places
                            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                        ),
                        const SizedBox(height: 16.0),
                        TextFormField(
                          controller: _maleController,
                          decoration: InputDecoration(
                            labelText: S.of(context).male,
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16.0),
                        TextFormField(
                          controller: _femaleController,
                          decoration: InputDecoration(
                            labelText: S.of(context).female,
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16.0),
                        TextFormField(
                          controller: _helpersController,
                          decoration: InputDecoration(
                            labelText: S.of(context).helpers,
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
    final nestProvider = Provider.of<NestProvider>(context, listen: false);

    if (_formKey.currentState!.validate()) {
      if (widget.isEditing) {
        final updatedNest = widget.nest!.copyWith(
          fieldNumber: _fieldNumberController.text,
          speciesName: _speciesNameController.text,
          localityName: _fieldLocalityEditingController.text,
          support: _fieldSupportEditingController.text,
          heightAboveGround: double.tryParse(_heightAboveGroundController.text),
          male: _maleController.text,
          female: _femaleController.text,
          helpers: _helpersController.text,
        );

        try {
          await nestProvider.updateNest(updatedNest);

          Navigator.pop(context);
        } catch (error) {
          if (kDebugMode) {
            print('Error saving nest: $error');
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error_outlined, color: Colors.red),
                  SizedBox(width: 8),
                  Text(S.current.errorSavingNest),
                ],
              ),
            ),
          );
        }
      } else {
        // Create Nest object with form data
        final newNest = Nest(
          fieldNumber: _fieldNumberController.text,
          speciesName: _speciesNameController.text,
          localityName: _fieldLocalityEditingController.text,
          longitude: _currentPosition?.longitude,
          latitude: _currentPosition?.latitude,
          support: _fieldSupportEditingController.text,
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
        } catch (error) {
          if (kDebugMode) {
            print('Error adding nest: $error');
          }
          if (error.toString().contains(S.of(context).errorNestAlreadyExists)) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.info_outlined, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(S.of(context).errorNestAlreadyExists),
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
                    Text(S.current.errorSavingNest),
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