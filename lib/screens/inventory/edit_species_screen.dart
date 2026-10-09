import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import '../../core/core_consts.dart';
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
  static const double _chipSpacing = 4;
  static const double _chipRunSpacing = 4;

  late final SearchController _nameController;
  late final TextEditingController _countController;
  late final TextEditingController _distanceController;
  late final TextEditingController _flightHeightController;
  late final TextEditingController _notesController;
  late bool _isOutOfInventory;
  late bool _isDoubtful;
  String? _selectedFlightDirection;
  late Set<SpeciesHabitat> _selectedHabitats;
  late Set<SpeciesDetectionMode> _selectedDetectionModes;
  SpeciesReproductiveStatus? _selectedReproductiveStatus;
  SpeciesSex? _selectedSex;
  late Set<SpeciesActivity> _selectedActivities;
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
    _isDoubtful = widget.species.isDoubtful;
    _selectedFlightDirection = widget.species.flightDirection;
    _selectedHabitats = widget.species.habitats?.toSet() ?? <SpeciesHabitat>{};
    _selectedDetectionModes = widget.species.detectionModes?.toSet() ?? <SpeciesDetectionMode>{};
    _selectedReproductiveStatus = widget.species.reproductiveStatus;
    _selectedSex = widget.species.sex;
    _selectedActivities = widget.species.activities?.toSet() ?? <SpeciesActivity>{};
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

    final trimmedName = name.trim();

    // Se o nome não mudou em relação ao original, não é considerado duplicidade (é o próprio registro)
    if (trimmedName.toLowerCase() == widget.species.name.trim().toLowerCase()) {
      return false;
    }

    // Verifica se o nome existe no conjunto de nomes existentes (ignorando case)
    return widget.existingSpeciesNames.any(
      (existingName) => existingName.trim().toLowerCase() == trimmedName.toLowerCase(),
    );
  }

  void _showNameValidationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _chipIcon(IconData icon, {Color? color}) {
    return Icon(icon, size: 18, color: color);
  }

  String _selectionSummary(String label, int count) {
    if (count == 0) {
      return '$label: ${S.current.notSpecified}';
    }
    return count == 1 ? '$label: 1 ${S.current.selectedSpecies.toLowerCase()}' : '$label: $count ${S.current.selectedSpecies.toLowerCase()}';
  }

  Widget _buildChipSection({
    required String label,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }

  Future<Set<T>?> _showSelectionDialog<T extends Enum>({
    required String title,
    required List<T> options,
    required Set<T> initialSelection,
    required String Function(T value) labelBuilder,
    Widget Function(T value)? avatarBuilder,
  }) async {
    return showDialog<Set<T>>(
      context: context,
      builder: (dialogContext) => _SelectionChipsDialog<T>(
        title: title,
        options: options,
        initialSelection: initialSelection,
        labelBuilder: labelBuilder,
        avatarBuilder: avatarBuilder,
      ),
    );
  }

  Widget _buildMultiSelectChipSection<T extends Enum>({
    required String label,
    required List<T> options,
    required Set<T> selectedValues,
    required String Function(T value) labelBuilder,
    Widget Function(T value)? avatarBuilder,
    required void Function(T value, bool selected) onChanged,
  }) {
    return _buildChipSection(
      label: label,
      child: Wrap(
        spacing: _chipSpacing,
        runSpacing: _chipRunSpacing,
        children: [
          for (final option in options)
            FilterChip(
              avatar: avatarBuilder?.call(option),
              label: Text(labelBuilder(option)),
              showCheckmark: false,
              selected: selectedValues.contains(option),
              labelPadding: const EdgeInsets.symmetric(horizontal: 2),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              onSelected: (selected) => onChanged(option, selected),
            ),
        ],
      ),
    );
  }

  Widget _buildDropdownSection<T extends Enum>({
    required String label,
    required List<T> options,
    required T? selectedValue,
    required String Function(T value) labelBuilder,
    required void Function(T? value) onChanged,
  }) {
    return DropdownButtonFormField<T?>(
      initialValue: selectedValue,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: [
        DropdownMenuItem<T?>(
          value: null,
          child: Text(S.current.notSpecified),
        ),
        ...options.map(
          (value) => DropdownMenuItem<T?>(
            value: value,
            child: Text(labelBuilder(value)),
          ),
        ),
      ],
      onChanged: onChanged,
    );
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

      // Cria um novo objeto Species com os dados atualizados para garantir que campos
      // nulos (como distância ou notas limpas) sejam corretamente aplicados.
      final updatedSpecies = Species(
        id: widget.species.id,
        inventoryId: widget.species.inventoryId,
        name: speciesName,
        count: int.tryParse(_countController.text) ?? widget.species.count,
        distance: double.tryParse(_distanceController.text),
        flightHeight: double.tryParse(_flightHeightController.text),
        flightDirection: _selectedFlightDirection,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        isOutOfInventory: _isOutOfInventory,
        isDoubtful: _isDoubtful,
        sampleTime: widget.species.sampleTime,
        habitats: _selectedHabitats.isEmpty ? null : SpeciesHabitat.values.where(_selectedHabitats.contains).toList(),
        detectionModes: _selectedDetectionModes.isEmpty ? null : SpeciesDetectionMode.values.where(_selectedDetectionModes.contains).toList(),
        reproductiveStatus: _selectedReproductiveStatus,
        sex: _selectedSex,
        activities: _selectedActivities.isEmpty ? null : SpeciesActivity.values.where(_selectedActivities.contains).toList(),
        pois: widget.species.pois,
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
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdownSection<SpeciesReproductiveStatus>(
                        label: S.current.speciesReproductiveStatus,
                        options: SpeciesReproductiveStatus.values,
                        selectedValue: _selectedReproductiveStatus,
                        labelBuilder: (value) => speciesReproductiveStatusFriendlyNames[value] ?? value.name,
                        onChanged: (value) {
                          setState(() {
                            _selectedReproductiveStatus = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildDropdownSection<SpeciesSex>(
                        label: S.current.speciesSex,
                        options: SpeciesSex.values,
                        selectedValue: _selectedSex,
                        labelBuilder: (value) => speciesSexFriendlyNames[value] ?? value.name,
                        onChanged: (value) {
                          setState(() {
                            _selectedSex = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                _buildMultiSelectChipSection<SpeciesDetectionMode>(
                  label: S.current.speciesDetectionMode,
                  options: SpeciesDetectionMode.values,
                  selectedValues: _selectedDetectionModes,
                  labelBuilder: (value) => speciesDetectionModeFriendlyNames[value] ?? value.name,
                  avatarBuilder: (value) => switch (value) {
                    SpeciesDetectionMode.visual => _chipIcon(Icons.visibility_outlined),
                    SpeciesDetectionMode.auditory => _chipIcon(Icons.hearing_outlined),
                    SpeciesDetectionMode.capture => _chipIcon(Icons.grid_4x4_outlined),
                    SpeciesDetectionMode.nest => _chipIcon(Icons.egg_outlined),
                    SpeciesDetectionMode.cameraTrap => _chipIcon(Icons.photo_camera_outlined),
                    SpeciesDetectionMode.telemetry => _chipIcon(Icons.sensors_outlined),
                    SpeciesDetectionMode.trackOrSign => _chipIcon(Icons.pets_outlined),
                    SpeciesDetectionMode.dead => _chipIcon(Icons.crisis_alert_outlined),
                    SpeciesDetectionMode.other => _chipIcon(Icons.more_horiz),
                  },
                  onChanged: (value, selected) {
                    setState(() {
                      if (selected) {
                        _selectedDetectionModes.add(value);
                      } else {
                        _selectedDetectionModes.remove(value);
                      }
                    });
                  },
                ),
                const SizedBox(height: 12),

                // _buildDropdownSection<SpeciesReproductiveStatus>(
                //   label: S.current.speciesReproductiveStatus,
                //   options: SpeciesReproductiveStatus.values,
                //   selectedValue: _selectedReproductiveStatus,
                //   labelBuilder: (value) => speciesReproductiveStatusFriendlyNames[value] ?? value.name,
                //   onChanged: (value) {
                //     setState(() {
                //       _selectedReproductiveStatus = value;
                //     });
                //   },
                // ),
                // const SizedBox(height: 12),
                //
                // _buildDropdownSection<SpeciesSex>(
                //   label: S.current.speciesSex,
                //   options: SpeciesSex.values,
                //   selectedValue: _selectedSex,
                //   labelBuilder: (value) => speciesSexFriendlyNames[value] ?? value.name,
                //   onChanged: (value) {
                //     setState(() {
                //       _selectedSex = value;
                //     });
                //   },
                // ),
                // const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(S.current.speciesHabitat),
                            if (_selectedHabitats.isNotEmpty) ...[
                              const SizedBox(width: 4),
                              Badge(
                                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                textColor: Theme.of(context).colorScheme.onPrimaryContainer,
                                label: Text('${_selectedHabitats.length}'),
                              ),
                            ],
                          ],
                        ),
                        onPressed: () async {
                          final result = await _showSelectionDialog<SpeciesHabitat>(
                            title: S.current.speciesHabitat,
                            options: SpeciesHabitat.values,
                            initialSelection: _selectedHabitats,
                            labelBuilder: (value) => speciesHabitatFriendlyNames[value] ?? value.name,
                          );
                          if (result == null || !mounted) return;
                          setState(() => _selectedHabitats = result);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(S.current.speciesActivity),
                            if (_selectedActivities.isNotEmpty) ...[
                              const SizedBox(width: 4),
                              Badge(
                                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                textColor: Theme.of(context).colorScheme.onPrimaryContainer,
                                label: Text('${_selectedActivities.length}')
                              ),
                            ],
                          ],
                        ),
                        onPressed: () async {
                          final result = await _showSelectionDialog<SpeciesActivity>(
                            title: S.current.speciesActivity,
                            options: SpeciesActivity.values,
                            initialSelection: _selectedActivities,
                            labelBuilder: (value) => speciesActivityFriendlyNames[value] ?? value.name,
                            // avatarBuilder: (value) => switch (value) {
                            //   SpeciesActivity.flying => _chipIcon(Icons.flight_outlined),
                            //   SpeciesActivity.foraging => _chipIcon(Icons.search_outlined),
                            //   SpeciesActivity.perching => _chipIcon(Icons.nest_cam_wired_stand_outlined),
                            //   SpeciesActivity.singing => _chipIcon(Icons.music_note_outlined),
                            //   SpeciesActivity.calling => _chipIcon(Icons.record_voice_over_outlined),
                            //   SpeciesActivity.nesting => _chipIcon(Icons.home_outlined),
                            //   SpeciesActivity.feedingYoung => _chipIcon(Icons.child_care_outlined),
                            //   SpeciesActivity.resting => _chipIcon(Icons.bedtime_outlined),
                            //   SpeciesActivity.bathing => _chipIcon(Icons.water_drop_outlined),
                            //   SpeciesActivity.moving => _chipIcon(Icons.directions_walk_outlined),
                            //   SpeciesActivity.displaying => _chipIcon(Icons.flutter_dash_outlined),
                            //   SpeciesActivity.aggressive => _chipIcon(Icons.warning_amber_outlined),
                            //   SpeciesActivity.roosting => _chipIcon(Icons.nightlight_outlined),
                            //   SpeciesActivity.other => _chipIcon(Icons.more_horiz),
                            // },
                          );
                          if (result == null || !mounted) return;
                          setState(() => _selectedActivities = result);
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
                SwitchListTile.adaptive(
                  title: Text(S.current.doubtfulRecord),
                  value: _isDoubtful,
                  onChanged: (bool value) {
                    setState(() {
                      _isDoubtful = value;
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

class _SelectionChipsDialog<T extends Enum> extends StatefulWidget {
  final String title;
  final List<T> options;
  final Set<T> initialSelection;
  final String Function(T value) labelBuilder;
  final Widget Function(T value)? avatarBuilder;

  const _SelectionChipsDialog({
    required this.title,
    required this.options,
    required this.initialSelection,
    required this.labelBuilder,
    required this.avatarBuilder,
  });

  @override
  State<_SelectionChipsDialog<T>> createState() => _SelectionChipsDialogState<T>();
}

class _SelectionChipsDialogState<T extends Enum> extends State<_SelectionChipsDialog<T>> {
  late final Set<T> _selection = {...widget.initialSelection};

  @override
  Widget build(BuildContext context) {
    final selectedColor = Theme.of(context).colorScheme.primaryContainer;
    final unselectedColor = Theme.of(context).colorScheme.surface;

    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final option in widget.options)
              FilterChip(
                avatar: widget.avatarBuilder?.call(option),
                label: Text(widget.labelBuilder(option)),
                showCheckmark: true,
                selectedColor: selectedColor,
                backgroundColor: unselectedColor,
                checkmarkColor: Theme.of(context).colorScheme.onPrimaryContainer,
                side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                selected: _selection.contains(option),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selection.add(option);
                    } else {
                      _selection.remove(option);
                    }
                  });
                },
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text(S.current.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_selection),
          child: Text(S.current.save),
        ),
      ],
    );
  }
}

