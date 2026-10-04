import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
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
  late final TextEditingController _startTimeController;
  late final TextEditingController _endTimeController;
  late final TextEditingController _startLatitudeController;
  late final TextEditingController _startLongitudeController;
  late final TextEditingController _endLatitudeController;
  late final TextEditingController _endLongitudeController;
  DateTime? _startTime;
  DateTime? _endTime;
  late bool _isDiscarded;
  late final InventoryType _initialType;
  InventoryType _selectedType = InventoryType.invFreeQualitative;
  List<String> _recentLocalities = const [];

  final _formKey = GlobalKey<FormState>();
  late final inventoryProvider = Provider.of<InventoryProvider>(
      context, listen: false);

  bool get _hasStartTimeChanged {
    final original = widget.inventory.startTime;
    final updated = _startTime;
    if (original == null && updated == null) {
      return false;
    }
    if (original == null || updated == null) {
      return true;
    }
    return !original.isAtSameMomentAs(updated);
  }

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

    _startTime = widget.inventory.startTime;
    _startTimeController = TextEditingController(
      text: _startTime != null ? DateFormat('dd/MM/yyyy HH:mm').format(_startTime!) : '',
    );

    _endTime = widget.inventory.endTime;
    _endTimeController = TextEditingController(
      text: _endTime != null ? DateFormat('dd/MM/yyyy HH:mm').format(_endTime!) : '',
    );

    _startLatitudeController = TextEditingController(
      text: widget.inventory.startLatitude != null && widget.inventory.startLatitude != 0
          ? widget.inventory.startLatitude.toString()
          : '',
    );
    _startLongitudeController = TextEditingController(
      text: widget.inventory.startLongitude != null && widget.inventory.startLongitude != 0
          ? widget.inventory.startLongitude.toString()
          : '',
    );
    _endLatitudeController = TextEditingController(
      text: widget.inventory.endLatitude != null && widget.inventory.endLatitude != 0
          ? widget.inventory.endLatitude.toString()
          : '',
    );
    _endLongitudeController = TextEditingController(
      text: widget.inventory.endLongitude != null && widget.inventory.endLongitude != 0
          ? widget.inventory.endLongitude.toString()
          : '',
    );

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
    _startTimeController.dispose();
    _endTimeController.dispose();
    _startLatitudeController.dispose();
    _startLongitudeController.dispose();
    _endLatitudeController.dispose();
    _endLongitudeController.dispose();
    super.dispose();
  }

  /// Opens date and time pickers to update the inventory start time.
  Future<void> _selectStartTime(BuildContext context) async {
    final current = _startTime ?? DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate == null || !mounted || !context.mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (pickedTime == null || !mounted) return;

    final newDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
    setState(() {
      _startTime = newDateTime;
      _startTimeController.text = DateFormat('dd/MM/yyyy HH:mm').format(newDateTime);
    });
  }

  /// Opens date and time pickers to update the inventory end time.
  Future<void> _selectEndTime(BuildContext context) async {
    final current = _endTime ?? _startTime ?? DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate == null || !mounted || !context.mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (pickedTime == null || !mounted) return;

    final newDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
    setState(() {
      _endTime = newDateTime;
      _endTimeController.text = DateFormat('dd/MM/yyyy HH:mm').format(newDateTime);
    });
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

      List<Species> speciesToPersist = widget.inventory.speciesList;
      if (_hasStartTimeChanged &&
          widget.inventory.startTime != null &&
          _startTime != null) {
        await inventoryProvider.speciesProvider.loadSpeciesForInventory(widget.inventory.id);
        final loadedSpeciesFromProvider = inventoryProvider
            .speciesProvider
            .getSpeciesForInventory(widget.inventory.id);

        List<Species> sourceSpecies = loadedSpeciesFromProvider.isNotEmpty
            ? loadedSpeciesFromProvider
            : widget.inventory.speciesList;
        if (sourceSpecies.isEmpty) {
          await inventoryProvider.loadInventoryDetails(widget.inventory.id);
          sourceSpecies = inventoryProvider.getInventoryById(widget.inventory.id)?.speciesList ?? const [];
        }

        final hasSpeciesWithSampleTime = sourceSpecies.any((species) => species.sampleTime != null);
        if (hasSpeciesWithSampleTime) {
          final shouldShiftSpeciesTimes = await _askToShiftSpeciesTimes();
          if (shouldShiftSpeciesTimes == null || !mounted) {
            return;
          }

          if (shouldShiftSpeciesTimes) {
            speciesToPersist = _shiftSpeciesSampleTimes(
              sourceSpecies,
              widget.inventory.startTime!,
              _startTime!,
            );
            await _persistSpeciesTimeUpdates(speciesToPersist);
          } else {
            speciesToPersist = sourceSpecies;
          }
        }
      }

      final startLatText = _startLatitudeController.text.trim();
      final startLonText = _startLongitudeController.text.trim();
      final endLatText = _endLatitudeController.text.trim();
      final endLonText = _endLongitudeController.text.trim();

      final double? startLat = startLatText.isNotEmpty ? double.tryParse(startLatText) : null;
      final double? startLon = startLonText.isNotEmpty ? double.tryParse(startLonText) : null;
      final double? endLat = endLatText.isNotEmpty ? double.tryParse(endLatText) : null;
      final double? endLon = endLonText.isNotEmpty ? double.tryParse(endLonText) : null;

      // Create a copy of the original inventory with the updated data from the form
      final updatedInventory = Inventory(
        id: _idController.text,
        type: _selectedType,
        duration: int.tryParse(_durationController.text) ?? widget.inventory.duration,
        maxSpecies: int.tryParse(_maxSpeciesController.text) ?? widget.inventory.maxSpecies,
        isPaused: widget.inventory.isPaused,
        isFinished: widget.inventory.isFinished,
        elapsedTime: widget.inventory.elapsedTime,
        startTime: _startTime,
        endTime: _endTime,
        startLongitude: startLon,
        startLatitude: startLat,
        endLongitude: endLon,
        endLatitude: endLat,
        localityName: _localityNameController.text,
        totalObservers: int.tryParse(_totalObserversController.text) ?? widget.inventory.totalObservers,
        observer: _observerController.text.toUpperCase(),
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        isDiscarded: _isDiscarded,
        speciesList: speciesToPersist,
        speciesCount: widget.inventory.speciesCount,
        speciesWithinCount: widget.inventory.speciesWithinCount,
        speciesOutOfInventoryCount: widget.inventory.speciesOutOfInventoryCount,
        vegetationList: widget.inventory.vegetationList,
        weatherList: widget.inventory.weatherList,
        currentInterval: widget.inventory.currentInterval,
        intervalsWithoutNewSpecies: widget.inventory.intervalsWithoutNewSpecies,
        currentIntervalSpeciesCount: widget.inventory.currentIntervalSpeciesCount,
        totalPausedTimeInSeconds: widget.inventory.totalPausedTimeInSeconds,
        pauseStartTime: widget.inventory.pauseStartTime,
      );

      await _saveRecentLocality(_localityNameController.text);

      if (!mounted) return;
      // Return to the previous screen with the updated inventory
      Navigator.of(context).pop(updatedInventory);
    }
  }

  /// Asks whether species record times should be shifted after a start time edit.
  Future<bool?> _askToShiftSpeciesTimes() {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(S.current.startTimeChangeWarningTitle),
        content: Text(S.current.startTimeChangeWarningMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: Text(S.current.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(S.current.keepSpeciesTimes),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(S.current.updateSpeciesTimes),
          ),
        ],
      ),
    );
  }

  /// Shifts species sample times preserving each record's offset from original start time.
  List<Species> _shiftSpeciesSampleTimes(
    List<Species> speciesList,
    DateTime originalStart,
    DateTime newStart,
  ) {
    return speciesList.map((species) {
      final sampleTime = species.sampleTime;
      if (sampleTime == null) {
        return species;
      }

      final relativeOffset = sampleTime.difference(originalStart);
      final shiftedSampleTime = newStart.add(relativeOffset);
      return species.copyWith(sampleTime: shiftedSampleTime);
    }).toList();
  }

  /// Persists shifted species times in storage and provider cache.
  Future<void> _persistSpeciesTimeUpdates(List<Species> updatedSpecies) async {
    final speciesProvider = inventoryProvider.speciesProvider;
    for (final species in updatedSpecies) {
      if (species.id == null) {
        continue;
      }
      await speciesProvider.updateSpecies(widget.inventory.id, species);
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
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: '${S.of(context).inventoryType} *',
                    border: OutlineInputBorder(),
                  ),
                  items: InventoryType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(
                        inventoryTypeFriendlyNames[type]!,
                        overflow: TextOverflow.ellipsis,
                      ),
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
                const SizedBox(height: 8.0),
                // Start & End Time
                TextFormField(
                        controller: _startTimeController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: S.of(context).startTime,
                          border: const OutlineInputBorder(),
                          suffixIcon: const Icon(Icons.calendar_today),
                        ),
                        onTap: () => _selectStartTime(context),
                      ),
                    const SizedBox(height: 8.0),
            TextFormField(
                        controller: _endTimeController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: S.of(context).endTime,
                          border: const OutlineInputBorder(),
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_endTimeController.text.isNotEmpty)
                                IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    setState(() {
                                      _endTime = null;
                                      _endTimeController.clear();
                                    });
                                  },
                                ),
                              const Icon(Icons.calendar_today),
                              const SizedBox(width: 8),
                            ],
                          ),
                        ),
                        onTap: () => _selectEndTime(context),
                      ),
                const SizedBox(height: 8.0),
                // Start Coordinates
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _startLongitudeController,
                        keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                        decoration: InputDecoration(
                          labelText: '${S.of(context).longitude} (${S.of(context).start})',
                          border: const OutlineInputBorder(),
                        ),
                        inputFormatters: [
                          CommaToDotTextInputFormatter(),
                        ],
                        validator: (value) {
                          if (value != null && value.trim().isNotEmpty) {
                            final lon = double.tryParse(value.trim());
                            if (lon == null || lon < -180 || lon > 180) {
                              return S.of(context).invalidLongitude;
                            }
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: TextFormField(
                        controller: _startLatitudeController,
                        keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                        decoration: InputDecoration(
                          labelText: '${S.of(context).latitude} (${S.of(context).start})',
                          border: const OutlineInputBorder(),
                        ),
                        inputFormatters: [
                          CommaToDotTextInputFormatter(),
                        ],
                        validator: (value) {
                          if (value != null && value.trim().isNotEmpty) {
                            final lat = double.tryParse(value.trim());
                            if (lat == null || lat < -90 || lat > 90) {
                              return S.of(context).invalidLatitude;
                            }
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8.0),
                // End Coordinates
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _endLongitudeController,
                        keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                        decoration: InputDecoration(
                          labelText: '${S.of(context).longitude} (${S.of(context).end})',
                          border: const OutlineInputBorder(),
                        ),
                        inputFormatters: [
                          CommaToDotTextInputFormatter(),
                        ],
                        validator: (value) {
                          if (value != null && value.trim().isNotEmpty) {
                            final lon = double.tryParse(value.trim());
                            if (lon == null || lon < -180 || lon > 180) {
                              return S.of(context).invalidLongitude;
                            }
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: TextFormField(
                        controller: _endLatitudeController,
                        keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                        decoration: InputDecoration(
                          labelText: '${S.of(context).latitude} (${S.of(context).end})',
                          border: const OutlineInputBorder(),
                        ),
                        inputFormatters: [
                          CommaToDotTextInputFormatter(),
                        ],
                        validator: (value) {
                          if (value != null && value.trim().isNotEmpty) {
                            final lat = double.tryParse(value.trim());
                            if (lat == null || lat < -90 || lat > 90) {
                              return S.of(context).invalidLatitude;
                            }
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
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
                          if ((value != null && value.isNotEmpty) && int.tryParse(value)! > 0 && int.tryParse(value)! < 5) {
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