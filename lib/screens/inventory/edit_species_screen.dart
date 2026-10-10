import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
  late final TextEditingController _reproductiveStatusController;
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
    _reproductiveStatusController = TextEditingController(text: _selectedReproductiveStatus?.code ?? '');
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
    _reproductiveStatusController.dispose();
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

  Widget _chipIcon(FaIconData icon, {Color? color}) {
    return FaIcon(icon, size: 18, color: color);
  }

  Widget _buildChipSection({required String label, required Widget child}) {
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

  Future<Set<T>?> _showSelectionBottomSheet<T extends Enum>({
    required String title,
    required List<T> options,
    required Set<T> initialSelection,
    required String Function(T value) labelBuilder,
    Widget Function(T value)? avatarBuilder,
  }) async {
    return showModalBottomSheet<Set<T>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder:
          (sheetContext) => _SelectionChipsBottomSheet<T>(
            title: title,
            options: options,
            initialSelection: initialSelection,
            labelBuilder: labelBuilder,
            avatarBuilder: avatarBuilder,
          ),
    );
  }

  Widget _buildSelectedOptionsField<T extends Enum>({
    required String label,
    required List<T> options,
    required Set<T> selectedValues,
    required String Function(T value) labelBuilder,
    required Future<void> Function() onEdit,
  }) {
    final selectedOptions = options.where(selectedValues.contains).toList();

    return _buildChipSection(
      label: label,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          color: Theme.of(context).colorScheme.surface,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child:
                  selectedOptions.isEmpty
                      ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          S.current.notSpecified,
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                      )
                      : Wrap(
                        spacing: _chipSpacing,
                        runSpacing: _chipRunSpacing,
                        children: [
                          for (final option in selectedOptions)
                            Chip(
                              label: Text(labelBuilder(option)),
                              backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
                              labelStyle: TextStyle(color: Theme.of(context).colorScheme.onTertiaryContainer),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            ),
                        ],
                      ),
            ),
            IconButton(
              onPressed: () {
                onEdit();
              },
              icon: const Icon(Icons.edit_outlined),
            ),
          ],
        ),
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
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      items: [
        DropdownMenuItem<T?>(value: null, child: Text(S.current.notSpecified)),
        ...options.map(
          (value) =>
              DropdownMenuItem<T?>(value: value, child: Text(labelBuilder(value), overflow: TextOverflow.ellipsis)),
        ),
      ],
      onChanged: onChanged,
    );
  }

  String _reproductiveStatusLabel(SpeciesReproductiveStatus value) {
    final details = speciesReproductiveStatusFriendlyNames[value] ?? value.code;
    return '${value.code} - $details';
  }

  List<_ReproductiveStatusGroup> _reproductiveStatusGroups() {
    const observed = [SpeciesReproductiveStatus.f];
    const possible = [SpeciesReproductiveStatus.h, SpeciesReproductiveStatus.s];
    const probable = [
      SpeciesReproductiveStatus.s7,
      SpeciesReproductiveStatus.m,
      SpeciesReproductiveStatus.p,
      SpeciesReproductiveStatus.t,
      SpeciesReproductiveStatus.c,
      SpeciesReproductiveStatus.n,
      SpeciesReproductiveStatus.a,
      SpeciesReproductiveStatus.b,
      SpeciesReproductiveStatus.pe,
    ];

    final confirmed = kSpeciesReproductiveStatusDisplayOrder
        .where((status) => !observed.contains(status) && !possible.contains(status) && !probable.contains(status))
        .toList(growable: false);

    return [
      _ReproductiveStatusGroup(title: S.current.speciesReproductiveGroupObserved, options: observed),
      _ReproductiveStatusGroup(title: S.current.speciesReproductiveGroupPossible, options: possible),
      _ReproductiveStatusGroup(title: S.current.speciesReproductiveGroupProbable, options: probable),
      _ReproductiveStatusGroup(title: S.current.speciesReproductiveGroupConfirmed, options: confirmed),
    ];
  }

  Future<SpeciesReproductiveStatus?> _showReproductiveStatusBottomSheet() async {
    return showModalBottomSheet<SpeciesReproductiveStatus?>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder:
          (sheetContext) => _ReproductiveStatusBottomSheet(
            selectedStatus: _selectedReproductiveStatus,
            labelBuilder: _reproductiveStatusLabel,
            groups: _reproductiveStatusGroups(),
          ),
    );
  }

  Widget _buildReproductiveStatusField() {
    return TextFormField(
      controller: _reproductiveStatusController,
      readOnly: true,
      decoration: InputDecoration(
        labelText: S.current.speciesReproductiveStatus,
        border: const OutlineInputBorder(),
        suffixIcon: _selectedReproductiveStatus != null
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  setState(() {
                    _selectedReproductiveStatus = null;
                    _reproductiveStatusController.text = '';
                  });
                },
              )
            : const Icon(Icons.arrow_drop_down),
      ),
      onTap: () async {
        final result = await _showReproductiveStatusBottomSheet();
        if (!mounted || result == _selectedReproductiveStatus) return;
        setState(() {
          _selectedReproductiveStatus = result;
          _reproductiveStatusController.text = _selectedReproductiveStatus?.code ?? '';
        });
      },
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
        detectionModes:
            _selectedDetectionModes.isEmpty
                ? null
                : SpeciesDetectionMode.values.where(_selectedDetectionModes.contains).toList(),
        reproductiveStatus: _selectedReproductiveStatus,
        sex: _selectedSex,
        activities:
            _selectedActivities.isEmpty ? null : SpeciesActivity.values.where(_selectedActivities.contains).toList(),
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
                        items: [
                          DropdownMenuItem<String>(value: null, child: Text(S.current.notSpecified)),
                          ...[
                            // Pontos Cardeais
                            'N', 'S', 'E', 'W',
                            // Pontos Colaterais (Intercardinais)
                            'NE', 'NW', 'SE', 'SW',
                            // Pontos Subcolaterais (Secundários)
                            // 'NNE', 'ENE', 'ESE', 'SSE', 'SSW', 'WSW', 'WNW', 'NNW',
                          ].map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(value: value, child: Text(value));
                          }),
                        ],
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
                    Expanded(child: _buildReproductiveStatusField()),
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
                  avatarBuilder:
                      (value) => switch (value) {
                        SpeciesDetectionMode.visual => _chipIcon(FontAwesomeIcons.solidEye),
                        SpeciesDetectionMode.song => _chipIcon(FontAwesomeIcons.music),
                        SpeciesDetectionMode.call => _chipIcon(FontAwesomeIcons.volumeHigh),
                        SpeciesDetectionMode.wingFlapping => _chipIcon(FontAwesomeIcons.dove),
                        SpeciesDetectionMode.drumming => _chipIcon(FontAwesomeIcons.drum),
                        SpeciesDetectionMode.capture => _chipIcon(FontAwesomeIcons.boxOpen),
                        SpeciesDetectionMode.remote => _chipIcon(FontAwesomeIcons.satelliteDish),
                        SpeciesDetectionMode.trackOrSign => _chipIcon(FontAwesomeIcons.feather),
                        SpeciesDetectionMode.other => _chipIcon(FontAwesomeIcons.ellipsis),
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

                _buildSelectedOptionsField<SpeciesHabitat>(
                  label: S.current.speciesHabitat,
                  options: SpeciesHabitat.values,
                  selectedValues: _selectedHabitats,
                  labelBuilder: (value) => speciesHabitatFriendlyNames[value] ?? value.name,
                  onEdit: () async {
                    final result = await _showSelectionBottomSheet<SpeciesHabitat>(
                      title: S.current.speciesHabitat,
                      options: SpeciesHabitat.values,
                      initialSelection: _selectedHabitats,
                      labelBuilder: (value) => speciesHabitatFriendlyNames[value] ?? value.name,
                    );
                    if (result == null || !mounted) return;
                    setState(() => _selectedHabitats = result);
                  },
                ),
                const SizedBox(height: 8),
                _buildSelectedOptionsField<SpeciesActivity>(
                  label: S.current.speciesActivity,
                  options: SpeciesActivity.values,
                  selectedValues: _selectedActivities,
                  labelBuilder: (value) => speciesActivityFriendlyNames[value] ?? value.name,
                  onEdit: () async {
                    final result = await _showSelectionBottomSheet<SpeciesActivity>(
                      title: S.current.speciesActivity,
                      options: SpeciesActivity.values,
                      initialSelection: _selectedActivities,
                      labelBuilder: (value) => speciesActivityFriendlyNames[value] ?? value.name,
                    );
                    if (result == null || !mounted) return;
                    setState(() => _selectedActivities = result);
                  },
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

class _SelectionChipsBottomSheet<T extends Enum> extends StatefulWidget {
  final String title;
  final List<T> options;
  final Set<T> initialSelection;
  final String Function(T value) labelBuilder;
  final Widget Function(T value)? avatarBuilder;

  const _SelectionChipsBottomSheet({
    required this.title,
    required this.options,
    required this.initialSelection,
    required this.labelBuilder,
    required this.avatarBuilder,
  });

  @override
  State<_SelectionChipsBottomSheet<T>> createState() => _SelectionChipsBottomSheetState<T>();
}

class _SelectionChipsBottomSheetState<T extends Enum> extends State<_SelectionChipsBottomSheet<T>> {
  late final Set<T> _selection = {...widget.initialSelection};

  @override
  Widget build(BuildContext context) {
    final selectedColor = Theme.of(context).colorScheme.primaryContainer;
    final unselectedColor = Theme.of(context).colorScheme.surface;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(widget.title, style: Theme.of(context).textTheme.titleLarge)),
                TextButton(onPressed: () => Navigator.of(context).pop(null), child: Text(S.current.cancel)),
                const SizedBox(width: 8),
                TextButton(onPressed: () => Navigator.of(context).pop(_selection), child: Text(S.current.save)),
              ],
            ),
            const SizedBox(height: 12),
            Flexible(
              fit: FlexFit.loose,
              child: SingleChildScrollView(
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
            ),
          ],
        ),
      ),
    );
  }
}

class _ReproductiveStatusBottomSheet extends StatelessWidget {
  final SpeciesReproductiveStatus? selectedStatus;
  final String Function(SpeciesReproductiveStatus value) labelBuilder;
  final List<_ReproductiveStatusGroup> groups;

  const _ReproductiveStatusBottomSheet({
    required this.selectedStatus,
    required this.labelBuilder,
    required this.groups,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(S.current.speciesReproductiveStatus, style: Theme.of(context).textTheme.titleLarge),
                ),
                TextButton(onPressed: () => Navigator.of(context).pop(null), child: Text(S.current.clearSelection)),
                IconButton(
                  tooltip: S.current.cancel,
                  onPressed: () => Navigator.of(context).pop(selectedStatus),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final group in groups) ...[
                      for (final option in group.options)
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => Navigator.of(context).pop(option),
                          child: Tooltip(
                            message: labelBuilder(option),
                            child: CircleAvatar(
                              radius: 24,
                              backgroundColor:
                                  selectedStatus == option ? colorScheme.primary : colorScheme.secondaryContainer,
                              foregroundColor:
                                  selectedStatus == option ? colorScheme.onPrimary : colorScheme.onSecondaryContainer,
                              child: Text(option.code),
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReproductiveStatusGroup {
  final String title;
  final List<SpeciesReproductiveStatus> options;

  const _ReproductiveStatusGroup({required this.title, required this.options});
}
