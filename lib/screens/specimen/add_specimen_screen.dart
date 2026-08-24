import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/specimen.dart';
import '../../providers/specimen_provider.dart';
import '../../core/core_consts.dart';
import '../../utils/utils.dart';
import '../../generated/l10n.dart';

/// Screen used to create or edit a specimen record.
class AddSpecimenScreen extends StatefulWidget {
  final Specimen? specimen;
  final bool isEditing;

  /// Creates a specimen form screen.
  const AddSpecimenScreen({
    super.key,
    this.specimen,
    this.isEditing = false,
  });

  /// Creates the mutable state for [AddSpecimenScreen].
  @override
  AddSpecimenScreenState createState() => AddSpecimenScreenState();
}

/// State implementation for [AddSpecimenScreen].
class AddSpecimenScreenState extends State<AddSpecimenScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fieldNumberController;
  late TextEditingController _speciesNameController;
  late TextEditingController _localityNameController;
  late TextEditingController _notesController;
  SpecimenType _selectedType = SpecimenType.spcFeathers;
  bool _isSubmitting = false;
  Position? _currentPosition;
  String _observerAcronym = '';
  List<String> _recentLocalities = const [];

  @override
  void initState() {
    super.initState();
    _fieldNumberController = TextEditingController();
    _speciesNameController = TextEditingController();
    _localityNameController = TextEditingController(text: widget.specimen?.locality ?? '');
    _notesController = TextEditingController();
    _loadObserverAcronym();
    _loadRecentLocalities();

    if (widget.isEditing) {
      _selectedType = widget.specimen!.type;
      _fieldNumberController.text = widget.specimen!.fieldNumber;
      _speciesNameController.text = widget.specimen!.speciesName ?? '';
      _localityNameController.text = widget.specimen!.locality ?? '';
      _notesController.text = widget.specimen!.notes ?? '';
    } else {
      _nextFieldNumber();
      _getCurrentLocation();
    }
  }

  /// Loads the observer acronym used to generate default specimen numbers.
  Future<void> _loadObserverAcronym() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _observerAcronym = prefs.getString('observerAcronym') ?? '';
    });
  }

  /// Generates the next available field number for a new specimen.
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

  /// Retrieves the current coordinates to prefill a new specimen location.
  Future<void> _getCurrentLocation() async {
    Position? position = await getPosition(context);
    if (position != null) {
      setState(() {
        _currentPosition = position;
      });
    } else {
      // Mostrar campos de latitude e longitude para preenchimento manual
      // ...
    }
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
                          initialValue: _selectedType,
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
                          isFullScreen: MediaQuery.of(context).size.width < 600,
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
                        if (controller.text.isEmpty) {
                          return [];
                        } else {
                          return List<String>.from(allSpeciesNames)
                              .where((species) => speciesMatchesQuery(
                                  species, controller.text))
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
                      },
                    ),
                        const SizedBox(height: 16.0),
                        Autocomplete<String>(
                          initialValue: widget.isEditing
                              ? TextEditingValue(text: widget.specimen!.locality ?? '')
                              : TextEditingValue.empty,
                          optionsBuilder: (TextEditingValue textEditingValue) async {
                            return await _getLocalitySuggestions(textEditingValue.text);
                          },
                          onSelected: (String selection) {
                            _localityNameController.text = selection;
                            _saveRecentLocality(selection);
                          },
                          fieldViewBuilder: (
                              BuildContext context,
                              TextEditingController fieldTextEditingController,
                              FocusNode fieldFocusNode,
                              VoidCallback onFieldSubmitted,
                              ) {
                            return TextFormField(
                              controller: fieldTextEditingController,
                              focusNode: fieldFocusNode,
                              textCapitalization: TextCapitalization.none,
                              decoration: InputDecoration(
                                labelText: '${S.of(context).locality} *',
                                border: const OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return S.of(context).insertLocality;
                                }
                                return null;
                              },
                              onChanged: (value) {
                                _localityNameController.text = value;
                              },
                              onFieldSubmitted: (String value) {
                                _localityNameController.text = value;
                                if (value.trim().isNotEmpty) {
                                  _saveRecentLocality(value);
                                }
                                onFieldSubmitted();
                              },
                            );
                          },
                          optionsViewBuilder: (
                              BuildContext context,
                              AutocompleteOnSelected<String> onSelected,
                              Iterable<String> options,
                              ) {
                            return Align(
                              alignment: Alignment.topLeft,
                              child: Material(
                                elevation: 4.0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
                                child: SizedBox(
                                  width: MediaQuery.of(context).size.width * 0.9,
                                  child: ListView.builder(
                                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                                    shrinkWrap: true,
                                    itemCount: options.length,
                                    itemBuilder: (BuildContext context, int index) {
                                      final String option = options.elementAt(index);
                                      return ListTile(
                                        title: Text(option),
                                        onTap: () {
                                          onSelected(option);
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ),
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
                        child: CircularProgressIndicator(strokeWidth: 2, year2023: false,),
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

  /// Loads recent localities used in inventory creation.
  Future<void> _loadRecentLocalities() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(kRecentSpecimenLocalitiesPreferenceKey) ?? const [];

    if (!mounted) {
      return;
    }

    setState(() {
      _recentLocalities = saved.where((item) => item.trim().isNotEmpty).take(3).toList();
    });
  }

  /// Stores a locality at the top of the recent list, keeping only the last three entries.
  Future<void> _saveRecentLocality(String locality) async {
    final normalized = locality.trim();
    if (normalized.isEmpty) {
      return;
    }

    final updated = [
      normalized,
      ..._recentLocalities.where((item) => item.toLowerCase() != normalized.toLowerCase()),
    ].take(3).toList();

    if (mounted) {
      setState(() {
        _recentLocalities = updated;
      });
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(kRecentSpecimenLocalitiesPreferenceKey, updated);
  }

  /// Returns locality suggestions with recent entries pinned to the top.
  Future<List<String>> _getLocalitySuggestions(String queryText) async {
    final query = removeDiacritics(queryText.trim());

    try {
      final localityOptions = await Provider.of<SpecimenProvider>(context, listen: false).getDistinctLocalities();
      final normalizedOptionsByKey = <String, String>{};

      for (final option in localityOptions) {
        final normalized = option.trim();
        final key = removeDiacritics(normalized);
        if (normalized.isEmpty) {
          continue;
        }

        if (!normalizedOptionsByKey.containsKey(key)) {
          normalizedOptionsByKey[key] = normalized;
        }
      }

      final normalizedOptions = normalizedOptionsByKey.values.toList();

      final filteredRecent = _recentLocalities
          .where((item) => removeDiacritics(item).contains(query))
          .toList();
      final filteredOptions = normalizedOptions
          .where((item) => removeDiacritics(item).contains(query))
          .toList();

      final merged = <String>[];
      final mergedIndexByKey = <String, int>{};

      for (final item in filteredRecent) {
        final key = removeDiacritics(item);
        if (!mergedIndexByKey.containsKey(key)) {
          mergedIndexByKey[key] = merged.length;
          merged.add(item);
        }
      }

      for (final item in filteredOptions) {
        final key = removeDiacritics(item);
        final existingIndex = mergedIndexByKey[key];
        if (existingIndex == null) {
          mergedIndexByKey[key] = merged.length;
          merged.add(item);
        }
      }

      return merged;
    } catch (e) {
      debugPrint('Error fetching locality options: $e');
      return _recentLocalities.where((item) => removeDiacritics(item).contains(query)).toList();
    }
  }

  /// Validates the form and saves the specimen through the provider layer.
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
          locality: _localityNameController.text,
          notes: _notesController.text,
          type: _selectedType,
          observer: (widget.specimen?.observer?.trim().isNotEmpty ?? false)
              ? widget.specimen!.observer
              : (_observerAcronym.isEmpty ? null : _observerAcronym),
        );

        try {
          await specimenProvider.updateSpecimen(updatedSpecimen);

          Navigator.pop(context);
        } catch (error) {
          debugPrint('Error saving specimen: $error');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              persist: true,
              showCloseIcon: true,
              backgroundColor: Theme.of(context).colorScheme.error,
              content: Text(S.current.errorSavingSpecimen),
            ),
          );
        }
      } else {
        // Create Specimen object with form data
        final newSpecimen = Specimen(
          fieldNumber: _fieldNumberController.text,
          speciesName: _speciesNameController.text,
          locality: _localityNameController.text,
          longitude: _currentPosition?.longitude,
          latitude: _currentPosition?.latitude,
          notes: _notesController.text,
          type: _selectedType,
          sampleTime: DateTime.now(),
          observer: _observerAcronym.isEmpty ? null : _observerAcronym,
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
                backgroundColor: Colors.amber,
                content: Text(S.current.errorSpecimenAlreadyExists),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                persist: true,
              showCloseIcon: true,
                backgroundColor: Theme.of(context).colorScheme.error,
                content: Text(S.current.errorSavingSpecimen),
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