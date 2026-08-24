import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/core_consts.dart';
import '../../data/models/inventory.dart';
import '../../generated/l10n.dart';
import '../../providers/inventory_provider.dart';
import '../../utils/utils.dart';

/// Screen used to edit metadata of an existing inventory.
class EditInventoryScreen extends StatefulWidget {
  final Inventory inventory;

  const EditInventoryScreen({super.key, required this.inventory});

  @override
  State<EditInventoryScreen> createState() => _EditInventoryScreenState();
}

/// State for editing inventory fields and returning an updated model.
class _EditInventoryScreenState extends State<EditInventoryScreen> {
  late final TextEditingController _idController;
  late final TextEditingController _localityNameController;
  late final TextEditingController _durationController;
  late final TextEditingController _maxSpeciesController;
  late final TextEditingController _notesController;
  late final TextEditingController _totalObserversController;
  late final TextEditingController _observerController;
  late bool _isDiscarded;
  late final InventoryType _initialType;
  InventoryType _selectedType = InventoryType.invFreeQualitative;
  List<String> _recentLocalities = const [];

  final _formKey = GlobalKey<FormState>();
  late final inventoryProvider = Provider.of<InventoryProvider>(
      context, listen: false);

  @override
  void initState() {
    super.initState();
    // Inicializa os controladores com os dados da espécie recebida
    _idController = TextEditingController(text: widget.inventory.id);
    _selectedType = widget.inventory.type;
    _initialType = widget.inventory.type;
    _localityNameController = TextEditingController(text: widget.inventory.localityName);
    _notesController = TextEditingController(text: widget.inventory.notes);
    _durationController = TextEditingController(text: widget.inventory.duration.toString());
    _maxSpeciesController = TextEditingController(text: widget.inventory.maxSpecies.toString());
    _totalObserversController = TextEditingController(text: widget.inventory.totalObservers.toString());
    _observerController = TextEditingController(text: widget.inventory.observer);
    _isDiscarded = widget.inventory.isDiscarded;
    _loadRecentLocalities();
  }

  @override
  void dispose() {
    // Libera os recursos dos controladores
    _idController.dispose();
    _localityNameController.dispose();
    _notesController.dispose();
    _durationController.dispose();
    _maxSpeciesController.dispose();
    _totalObserversController.dispose();
    _observerController.dispose();
    super.dispose();
  }

  // Load default values from settings
  Future<void> _updateFormFields(InventoryType newValue) async {
    final prefs = await SharedPreferences.getInstance();
    final maxSpeciesMackinnon = prefs.getInt('maxSpeciesMackinnon') ?? 10;
    final pointCountsDuration = prefs.getInt('pointCountsDuration') ?? 8;
    final cumulativeTimeDuration = prefs.getInt('cumulativeTimeDuration') ?? 45;
    final intervalsDuration = prefs.getInt('intervalsDuration') ?? 10;

    setState(() {
      if (newValue == InventoryType.invTimedQualitative) {
        if (widget.inventory.duration == 0) {
          _durationController.text = cumulativeTimeDuration.toString();
        }
        _maxSpeciesController.text = '';
      } else if (newValue == InventoryType.invIntervalQualitative) {
        if (widget.inventory.duration == 0) {
          _durationController.text = intervalsDuration.toString();
        }
        _maxSpeciesController.text = '';
      } else if (newValue == InventoryType.invMackinnonList) {
        if (widget.inventory.maxSpecies == 0) {
          _maxSpeciesController.text = maxSpeciesMackinnon.toString();
        }
        _durationController.text = '';
      } else if (newValue == InventoryType.invPointCount ||
          newValue == InventoryType.invPointDetection) {
        if (widget.inventory.duration == 0) {
          _durationController.text = pointCountsDuration.toString();
        }
        _maxSpeciesController.text = '';
      } else {
        _durationController.text = '';
        _maxSpeciesController.text = '';
      }
    });
  }

  /// Validates the form and pops with the updated inventory.
  Future<void> _saveForm() async {
    // Validate and save form
    if (_selectedType != _initialType) {
      // Show warning dialog when inventory type is changed
      final shouldContinue = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => AlertDialog(
          title: Text(S.current.inventoryTypeChangeWarningTitle),
          content: Text(
            S.current.inventoryTypeChangeWarningMessage(
              inventoryTypeFriendlyNames[_initialType]!,
              inventoryTypeFriendlyNames[_selectedType]!,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(S.current.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(S.current.continueAction),
            ),
          ],
        ),
      ) ?? false;

      // If user cancelled the type change, revert the selection
      if (!shouldContinue) {
        setState(() {
          _selectedType = _initialType;
        });
        return;
      }
    }

    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Create a copy of the original inventory with the updated data from the form
      final updatedInventory = widget.inventory.copyWith(
        id: _idController.text,
        type: _selectedType,
        localityName: _localityNameController.text,
        duration: int.tryParse(_durationController.text),
        maxSpecies: int.tryParse(_maxSpeciesController.text),
        totalObservers: int.tryParse(_totalObserversController.text),
        observer: _observerController.text.toUpperCase(),
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        isDiscarded: _isDiscarded,
      );

      await _saveRecentLocality(_localityNameController.text);

      // Return to the previous screen with the updated inventory
      Navigator.of(context).pop(updatedInventory);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.inventory.id),
        actions: [
          TextButton(
            onPressed: _saveForm,
            child: Text(S.current.save,),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _idController,
                  decoration: InputDecoration(
                    labelText: S.of(context).inventoryId,
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return S.current.insertInventoryId;
                    }
                    return null;
                  },
                ),
                SizedBox(height: 8),
                // Inventory type
                DropdownButtonFormField<InventoryType>(
                  initialValue: _selectedType,
                  decoration: InputDecoration(
                    labelText: '${S.of(context).inventoryType} *',
                    border: OutlineInputBorder(),
                  ),
                  items: InventoryType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(inventoryTypeFriendlyNames[type]!),
                    );
                  }).toList(),
                  onChanged: (InventoryType? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedType = newValue;
                      });
                      _updateFormFields(newValue);
                    }
                  },
                  validator: (value) {
                    if (value == null || value.index < 0) {
                      return S.of(context).selectInventoryType;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8.0),
                // Locality
                Autocomplete<String>(
                  initialValue: widget.inventory.localityName != null
                      ? TextEditingValue(text: widget.inventory.localityName!)
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
                SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      // Inventory duration
                      child: TextFormField(
                        controller: _durationController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: InputDecoration(
                          labelText: S.of(context).duration,
                          border: OutlineInputBorder(),
                          suffixText: 'min',
                          prefixIcon: IconButton(
                              onPressed: () {
                                int count = int.tryParse(_durationController.text) ?? 1;
                                if (count > 1) {
                                  setState(() {
                                    count--;
                                    _durationController.text = count.toString();
                                  });
                                }
                              },
                              icon: Icon(Icons.remove_outlined)),
                          suffixIcon: IconButton(
                              onPressed: () {
                                int count = int.tryParse(_durationController.text) ?? 1;
                                setState(() {
                                  count++;
                                  _durationController.text = count.toString();
                                });
                              },
                              icon: Icon(Icons.add_outlined)),
                        ),
                        validator: (value) {
                          if ((_selectedType == InventoryType.invTimedQualitative ||
                              _selectedType == InventoryType.invIntervalQualitative ||
                              _selectedType == InventoryType.invPointCount ||
                              _selectedType == InventoryType.invPointDetection) &&
                              (value == null || value.isEmpty)) {
                            return S.of(context).insertDuration;
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    Expanded(
                      // Inventory max of species
                      child: TextFormField(
                        controller: _maxSpeciesController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: InputDecoration(
                          labelText: S.of(context).maxSpecies,
                          border: OutlineInputBorder(),
                          suffixText: 'spp.',
                          prefixIcon: IconButton(
                              onPressed: () {
                                int count = int.tryParse(_maxSpeciesController.text) ?? 10;
                                if (count > 5) {
                                  setState(() {
                                    count--;
                                    _maxSpeciesController.text = count.toString();
                                  });
                                }
                              },
                              icon: Icon(Icons.remove_outlined)),
                          suffixIcon: IconButton(
                              onPressed: () {
                                int count = int.tryParse(_maxSpeciesController.text) ?? 10;
                                setState(() {
                                  count++;
                                  _maxSpeciesController.text = count.toString();
                                });
                              },
                              icon: Icon(Icons.add_outlined)),
                        ),
                        validator: (value) {
                          if ((_selectedType == InventoryType.invMackinnonList) && (value == null || value.isEmpty)) {
                            return S.of(context).insertMaxSpecies;
                          }
                          if ((value != null && value.isNotEmpty) && int.tryParse(value)! < 5) {
                            return S.of(context).mustBeBiggerThanFive;
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(children: [
                  // Total observers
                  Expanded(
                    child:
                TextFormField(
                  controller: _totalObserversController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    labelText: S.of(context).totalOfObservers,
                    border: OutlineInputBorder(),
                    prefixIcon: IconButton(
                        onPressed: () {
                          int count = int.tryParse(_totalObserversController.text) ?? 1;
                          if (count > 1) {
                            setState(() {
                              count--;
                              _totalObserversController.text = count.toString();
                            });
                          }
                        },
                        icon: Icon(Icons.remove_outlined)),
                    suffixIcon: IconButton(
                        onPressed: () {
                          int count = int.tryParse(_totalObserversController.text) ?? 1;
                          setState(() {
                            count++;
                            _totalObserversController.text = count.toString();
                          });
                        },
                        icon: Icon(Icons.add_outlined)),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return S.current.insertCount;
                    }
                    if (int.tryParse(value) == null || int.tryParse(value)! < 1) {
                      return S.current.insertValidNumber;
                    }
                    return null;
                  },
                ),
                  ),
                  const SizedBox(width: 8),
                  // Observer
                  Expanded(
                    child: TextFormField(
                      controller: _observerController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        labelText: S.of(context).observer,
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return S.current.insertObserver;
                        }
                        return null;
                      },
                    ),
                  ),
                ],
                ),
                SizedBox(height: 8),
                // Notes
                TextFormField(
                  controller: _notesController,
                  textCapitalization: TextCapitalization.sentences,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: S.of(context).notes,
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 8),
                // Discarded
                SwitchListTile.adaptive(
                  title: Text(S.current.discardedInventory),
                  value: _isDiscarded,
                  onChanged: (bool value) {
                    setState(() {
                      _isDiscarded = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Loads recent localities used in inventory creation.
  Future<void> _loadRecentLocalities() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(kRecentInventoryLocalitiesPreferenceKey) ?? const [];

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
    await prefs.setStringList(kRecentInventoryLocalitiesPreferenceKey, updated);
  }

  /// Returns locality suggestions with recent entries pinned to the top.
  Future<List<String>> _getLocalitySuggestions(String queryText) async {
    final query = removeDiacritics(queryText.trim());

    try {
      final localityOptions = await Provider.of<InventoryProvider>(context, listen: false).getDistinctLocalities();
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
}