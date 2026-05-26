import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/models/inventory.dart';
import '../../generated/l10n.dart';
import '../../utils/utils.dart';

/// Screen used to edit a species record inside an inventory.
class EditSpeciesScreen extends StatefulWidget {
  final Species species;
  final bool allowDuplicatedSpeciesNames;
  final Set<String> existingSpeciesNames;

  const EditSpeciesScreen({
    super.key,
    required this.species,
    this.allowDuplicatedSpeciesNames = true,
    this.existingSpeciesNames = const <String>{},
  });

  @override
  State<EditSpeciesScreen> createState() => _EditSpeciesScreenState();
}

/// Manages editable species fields and autocomplete interactions.
class _EditSpeciesScreenState extends State<EditSpeciesScreen> {
  late final SearchController _nameController;
  late final TextEditingController _countController;
  late final TextEditingController _distanceController;
  late final TextEditingController _flightHeightController;
  late final TextEditingController _notesController;
  late bool _isOutOfInventory;
  String? _selectedFlightDirection;
  bool _wasNameSearchOpen = false;
  bool _selectedNameFromSearch = false;
  String? _nameBeforeSearch;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Inicializa os controladores com os dados da espécie recebida
    _nameController = SearchController()..text = widget.species.name;
    _nameController.addListener(_handleNameSearchState);
    _countController = TextEditingController(text: widget.species.count.toString());
    _distanceController = TextEditingController(text: widget.species.distance?.toString());
    _flightHeightController = TextEditingController(text: widget.species.flightHeight?.toString());
    _notesController = TextEditingController(text: widget.species.notes);
    _isOutOfInventory = widget.species.isOutOfInventory;
    _selectedFlightDirection = widget.species.flightDirection;
  }

  @override
  void dispose() {
    // Libera os recursos dos controladores
    _nameController.removeListener(_handleNameSearchState);
    _nameController.dispose();
    _countController.dispose();
    _distanceController.dispose();
    _flightHeightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// Restores the previous name when search closes without a selection.
  void _handleNameSearchState() {
    final isOpen = _nameController.isOpen;

    if (_wasNameSearchOpen && !isOpen) {
      final shouldRestoreName = !_selectedNameFromSearch && _nameBeforeSearch != null && _nameBeforeSearch!.isNotEmpty;

      _wasNameSearchOpen = isOpen;

      if (shouldRestoreName) {
        _nameController.text = _nameBeforeSearch!;
      }

      _selectedNameFromSearch = false;
      _nameBeforeSearch = null;

      if (mounted) {
        setState(() {});
      }
      return;
    }

    _wasNameSearchOpen = isOpen;
  }

  /// Opens the species search overlay and stores the previous value.
  void _openSpeciesNameSearch(SearchController controller) {
    if (controller.isOpen) {
      return;
    }

    _nameBeforeSearch = controller.text.trim().isNotEmpty ? controller.text.trim() : widget.species.name;
    _selectedNameFromSearch = false;
    controller.text = '';
    controller.openView();
  }

  /// Checks whether the typed name already exists in the same inventory.
  bool _hasDuplicatedName(String name) {
    if (widget.allowDuplicatedSpeciesNames) {
      return false;
    }

    return widget.existingSpeciesNames.contains(name.trim());
  }

  void _showNameValidationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _saveForm() {
    final speciesName = _nameController.text.trim();

    if (speciesName.isEmpty) {
      _showNameValidationError(S.current.requiredField);
      return;
    }

    if (_hasDuplicatedName(speciesName)) {
      _showNameValidationError(S.current.errorSpeciesAlreadyExists);
      return;
    }

    // Valida e salva o formulário
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Cria uma cópia da espécie original com os dados atualizados do formulário
      final updatedSpecies = widget.species.copyWith(
        name: speciesName,
        count: int.tryParse(_countController.text) ?? widget.species.count,
        distance: double.tryParse(_distanceController.text),
        flightHeight: double.tryParse(_flightHeightController.text),
        flightDirection: _selectedFlightDirection,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        isOutOfInventory: _isOutOfInventory,
      );

      // Retorna para a tela anterior com o objeto 'Species' atualizado
      Navigator.of(context).pop(updatedSpecies);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_nameController.text.trim().isEmpty ? widget.species.name : _nameController.text),
        actions: [TextButton(onPressed: _saveForm, child: Text(S.current.save))],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SearchAnchor(
                  searchController: _nameController,
                  isFullScreen: MediaQuery.of(context).size.width < 600,
                  builder: (context, controller) {
                    return TextFormField(
                      controller: controller,
                      textCapitalization: TextCapitalization.sentences,
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: InputDecoration(
                        filled: true,
                        labelText: S.current.speciesName,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.search_outlined),
                      ),
                      onChanged: (value) {
                        if (!controller.isOpen) {
                          controller.openView();
                        }
                        setState(() {});
                      },
                      onTap: () {
                        _openSpeciesNameSearch(controller);
                      },
                      validator: (value) {
                        final name = value?.trim() ?? '';
                        if (name.isEmpty) {
                          return S.current.requiredField;
                        }
                        if (_hasDuplicatedName(name)) {
                          return S.current.errorSpeciesAlreadyExists;
                        }
                        return null;
                      },
                    );
                  },
                  suggestionsBuilder: (context, controller) {
                    if (controller.text.trim().isEmpty) {
                      return const Iterable<Widget>.empty();
                    }

                    return List<String>.from(allSpeciesNames)
                        .where((species) => speciesMatchesQuery(species, controller.text.toLowerCase()))
                        .map(
                          (species) => ListTile(
                            title: Text(species),
                            onTap: () {
                              _selectedNameFromSearch = true;
                              controller.closeView(species);
                              setState(() {});
                            },
                          ),
                        );
                  },
                  viewOnClose: () {
                    if (!_selectedNameFromSearch && _nameBeforeSearch != null && _nameBeforeSearch!.isNotEmpty) {
                      _nameController.text = _nameBeforeSearch!;
                      setState(() {});
                    }
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _countController,
                        decoration: InputDecoration(
                          labelText: S.current.count,
                          border: OutlineInputBorder(),
                          prefixIcon: IconButton(
                            onPressed: () {
                              int count = int.tryParse(_countController.text) ?? 0;
                              if (count > 0) {
                                setState(() {
                                  count--;
                                  _countController.text = count.toString();
                                });
                              }
                            },
                            icon: Icon(Icons.remove_outlined),
                          ),
                          suffixIcon: IconButton(
                            onPressed: () {
                              int count = int.tryParse(_countController.text) ?? 0;
                              setState(() {
                                count++;
                                _countController.text = count.toString();
                              });
                            },
                            icon: Icon(Icons.add_outlined),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        textAlign: TextAlign.center,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return S.current.insertCount;
                          }
                          if (int.tryParse(value) == null) {
                            return S.current.insertValidNumber;
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _distanceController,
                        decoration: InputDecoration(
                          labelText: S.current.distance,
                          suffixText: 'm',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _flightHeightController,
                        decoration: InputDecoration(
                          labelText: S.current.flightHeight,
                          suffixText: 'm',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedFlightDirection,
                        decoration: InputDecoration(
                          labelText: S.current.flightDirection,
                          border: const OutlineInputBorder(),
                        ),
                        isExpanded: true,
                        items:
                            [
                              // Pontos Cardeais
                              'N', 'S', 'E', 'W',
                              // Pontos Colaterais (Intercardinais)
                              'NE', 'NW', 'SE', 'SW',
                              // Pontos Subcolaterais (Secundários)
                              // 'NNE', 'ENE', 'ESE', 'SSE', 'SSW', 'WSW', 'WNW', 'NNW',
                            ].map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(value: value, child: Text(value));
                            }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedFlightDirection = newValue;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // --- Campo Notes ---
                TextFormField(
                  controller: _notesController,
                  decoration: InputDecoration(labelText: S.current.notes, border: OutlineInputBorder()),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                // --- Campo Is Out Of Inventory ---
                SwitchListTile.adaptive(
                  title: Text(S.current.outOfSample),
                  value: _isOutOfInventory,
                  onChanged: (bool value) {
                    setState(() {
                      _isOutOfInventory = value;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
