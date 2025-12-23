import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/inventory_provider.dart';
import '../../data/models/inventory.dart';
import '../../core/core_consts.dart';
import '../../utils/utils.dart';
import '../../generated/l10n.dart';

class AddInventoryScreen extends StatefulWidget {
  final String? initialInventoryId;
  final InventoryType? initialInventoryType;
  final String? initialLocalityName;
  final int? initialMaxSpecies;

  const AddInventoryScreen({super.key, this.initialInventoryId, this.initialInventoryType, this.initialLocalityName, this.initialMaxSpecies});

  @override
  AddInventoryScreenState createState() => AddInventoryScreenState();
}

class AddInventoryScreenState extends State<AddInventoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _idController = TextEditingController();
  final _durationController = TextEditingController();
  final _maxSpeciesController = TextEditingController();
  final _totalObserversController = TextEditingController();
  late TextEditingController _localityNameController;
  late TextEditingController _fieldLocalityEditingController;
  InventoryType _selectedType = InventoryType.invFreeQualitative;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _idController.text = widget.initialInventoryId ?? '';
    _selectedType = widget.initialInventoryType ?? _selectedType;
    _maxSpeciesController.text = widget.initialMaxSpecies?.toString() ?? '';
    _totalObserversController.text = '1';
    _localityNameController = TextEditingController();
    _localityNameController.text = widget.initialLocalityName ?? '';
    _fieldLocalityEditingController = TextEditingController();
    _fieldLocalityEditingController.text = widget.initialLocalityName ?? '';
  }

  @override
  void dispose() {
    _idController.dispose();
    _durationController.dispose();
    _maxSpeciesController.dispose();
    _totalObserversController.dispose();
    _localityNameController.dispose();
    _fieldLocalityEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).newInventory),
      ),
      body: Column(
        children: [
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView( // Prevent keyboard overflow
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Inventory type
                    DropdownButtonFormField<InventoryType>(
                      initialValue: _selectedType,
                      decoration: InputDecoration(
                        labelText: '${S.of(context).inventoryType} *',
                        // helperText: S.of(context).requiredField,
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
                    const SizedBox(height: 16.0),
                    // Inventory ID
                    TextFormField(
                      controller: _idController,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: '${S.of(context).inventoryId} *',
                        helperText: S.of(context).requiredField,
                        border: const OutlineInputBorder(),
                        // Button to generate ID
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.auto_mode_outlined),
                          onPressed: () async {
                            final inventoryProvider = Provider.of<InventoryProvider>(context, listen: false);
                            final result = await showDialog<String>(
                              context: context,
                              builder: (BuildContext context) {
                                String acronym = '';
                                return AlertDialog(
                                  title: Text(S.of(context).generateId),
                                  content: TextField(
                                    maxLength: 10,
                                    textCapitalization: TextCapitalization.words,
                                    autofocus: true,
                                    decoration: InputDecoration(
                                      labelText: S.of(context).siteAbbreviation,
                                      border: OutlineInputBorder(),
                                      helperText: S.of(context).optional,
                                    ),
                                    onChanged: (value) {
                                      setState(() {
                                        acronym = value;
                                      });
                                    },
                                  ),
                                  actions: <Widget>[
                                    TextButton(
                                      child: Text(S.of(context).cancel),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                    TextButton(
                                      child: Text(S.of(context).ok),
                                      onPressed: () {
                                        Navigator.of(context).pop(acronym);
                                      },
                                    ),
                                  ],
                                );
                              },
                            );

                            if (result != null && result.isNotEmpty) {
                              // Concatenate the inventory ID in the specified format
                              final prefs = await SharedPreferences.getInstance();
                              final observerAcronym = prefs.getString('observerAcronym') ?? '';
                              final now = DateTime.now();
                              final year = now.year.toString();
                              final month = now.month.toString().padLeft(2, '0');
                              final day = now.day.toString().padLeft(2, '0');
                              final inventoryTypeLetter = getInventoryTypeLetter(_selectedType);
                              final sequentialNumber = await inventoryProvider.getNextSequentialNumber(result, observerAcronym, now.year, now.month, now.day, inventoryTypeLetter);

                              final inventoryId = '$result-$observerAcronym-$year$month$day-${inventoryTypeLetter ?? ''}${sequentialNumber.toString().padLeft(2, '0')}';

                              _idController.text = inventoryId;
                            }
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return S.of(context).insertInventoryId;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16.0),
                    Autocomplete<String>(
                      initialValue: widget.initialLocalityName != null
                          ? TextEditingValue(text: widget.initialLocalityName!)
                          : TextEditingValue.empty,
                      optionsBuilder:
                          (TextEditingValue textEditingValue) async {
                        if (textEditingValue.text.isEmpty) {
                          return const Iterable<String>.empty();
                        }

                        try {
                          final localityOptions = await Provider.of<InventoryProvider>(context, listen: false).getDistinctLocalities();
                          return localityOptions.where((String option) {
                            return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                          });
                        } catch (e) {
                          debugPrint('Error fetching locality options: $e');
                          return const Iterable<String>.empty();
                        }
                      },
                      onSelected: (String selection) {
                        _localityNameController.text = selection;
                        _fieldLocalityEditingController.text = selection;
                      },
                      fieldViewBuilder: (BuildContext context,
                          TextEditingController fieldTextEditingController,
                          FocusNode fieldFocusNode,
                          VoidCallback onFieldSubmitted) {
                        return TextFormField(
                          controller: fieldTextEditingController,
                          focusNode: fieldFocusNode,
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            labelText: '${S.of(context).locality} *',
                            // helperText: S.of(context).requiredField,
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return S.of(context).insertLocality;
                            }
                            return null;
                          },
                          onChanged: (value) {
                            _localityNameController.text = value;
                          },
                          onFieldSubmitted: (String value) {
                            _localityNameController.text = value;
                            onFieldSubmitted();
                          },
                        );
                      },
                      optionsViewBuilder: (BuildContext context,
                          AutocompleteOnSelected<String> onSelected,
                          Iterable<String> options) {
                        return Align(
                          alignment: Alignment.topLeft,
                          child: Material(
                            elevation: 4.0, // Add this line for shadow
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width * 0.9,
                              child: ListView.builder(
                                padding: EdgeInsets.all(8.0),
                                itemCount: options.length,
                                itemBuilder: (BuildContext context, int index) {
                                  final String option = options.elementAt(index);
                                  return GestureDetector(
                                    onTap: () {
                                      onSelected(option);
                                    },
                                    child: ListTile(
                                      title: Text(option),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 16.0,),
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
                              suffixText: 'min', //S.of(context).minutes(2),
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
                    SizedBox(height: 16.0,),
                    Row(
                      children: [
                        Expanded(
                          // Total of observers
                          child: TextFormField(
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
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: SizedBox(width: 8.0,),
                        ),
                      ],
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
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    year2023: false,),
                )
                    : FilledButton(
                  onPressed: _submitForm,
                  child: Text(S.of(context).startInventory),
                ),
              )
            ),
          ),
        ],
      ),
    );
  }

  // Load default values from settings
  Future<void> _updateFormFields(InventoryType newValue) async {
    final prefs = await SharedPreferences.getInstance();
    final maxSpeciesMackinnon = prefs.getInt('maxSpeciesMackinnon') ?? 10;
    final pointCountsDuration = prefs.getInt('pointCountsDuration') ?? 8;
    final cumulativeTimeDuration = prefs.getInt('cumulativeTimeDuration') ?? 45;
    final intervalsDuration = prefs.getInt('intervalsDuration') ?? 10;

    setState(() {
      _selectedType = newValue;
      if (newValue == InventoryType.invTimedQualitative) {
        _durationController.text = cumulativeTimeDuration.toString();
        _maxSpeciesController.text = '';
      } else if (newValue == InventoryType.invIntervalQualitative) {
        _durationController.text = intervalsDuration.toString();
        _maxSpeciesController.text = '';
      } else if (newValue == InventoryType.invMackinnonList) {
        _maxSpeciesController.text = maxSpeciesMackinnon.toString();
        _durationController.text = '';
      } else if (newValue == InventoryType.invPointCount ||
          newValue == InventoryType.invPointDetection) {
        _durationController.text = pointCountsDuration.toString();
        _maxSpeciesController.text = '';
      } else {
        _durationController.text = '';
        _maxSpeciesController.text = '';
      }
    });
  }

  // Handle form submission
  void _submitForm() async {
    setState(() {
      _isSubmitting = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final observerAbbrev = prefs.getString('observerAcronym') ?? '';
    if (_formKey.currentState!.validate()) {
      final newInventory = Inventory(
        id: _idController.text,
        type: _selectedType,
        localityName: _localityNameController.text,
        duration: int.tryParse(_durationController.text) ?? 0,
        maxSpecies: int.tryParse(_maxSpeciesController.text) ?? 0,
        totalObservers: int.tryParse(_totalObserversController.text) ?? 1,
        observer: observerAbbrev,
        speciesList: [],
        vegetationList: [],
        weatherList: [],
      );

      // Check if the ID already exists in the database
      final inventoryProvider = Provider.of<InventoryProvider>(context, listen: false);
      final idExists = await inventoryProvider.inventoryIdExists(newInventory.id);
      
      if (idExists) {
        setState(() {
          _isSubmitting = false;
        });
        // ID already exists, show a SnackBar
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.info_outlined, color: Colors.blue),
                  SizedBox(width: 8),
                  Text(S.of(context).inventoryIdAlreadyExists),
                ],
              ),
            ),
          );
        }
        return; // Prevent adding inventory
      }

      // ID do not exist, insert inventory
      final success = await inventoryProvider.addInventory(context, newInventory);

      setState(() {
        _isSubmitting = false;
      });

      if (success) {
        if (mounted) {
          Navigator.pop(context); // Return to the previous screen
        }
      } else {
        // Handle insertion error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              persist: true,
              showCloseIcon: true,
              content: Row(
                children: [
                  Icon(Icons.error_outlined, color: Colors.red),
                  SizedBox(width: 8),
                  Text(S.of(context).errorInsertingInventory),
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