import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
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
  late final TextEditingController _notesController;
  late final TextEditingController _totalObserversController;
  late final TextEditingController _observerController;
  late bool _isDiscarded;
  late TextEditingController fieldLocalityEditingController;
  late final InventoryType _initialType;
  InventoryType _selectedType = InventoryType.invFreeQualitative;

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
    _totalObserversController = TextEditingController(text: widget.inventory.totalObservers.toString());
    _observerController = TextEditingController(text: widget.inventory.observer);
    _isDiscarded = widget.inventory.isDiscarded;
  }

  @override
  void dispose() {
    // Libera os recursos dos controladores
    _idController.dispose();
    _localityNameController.dispose();
    _notesController.dispose();
    _totalObserversController.dispose();
    _observerController.dispose();
    super.dispose();
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
        localityName: fieldLocalityEditingController.text,
        totalObservers: int.tryParse(_totalObserversController.text),
        observer: _observerController.text.toUpperCase(),
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        isDiscarded: _isDiscarded,
      );

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
                  optionsBuilder:
                      (TextEditingValue textEditingValue) async {
                    if (textEditingValue.text.isEmpty) {
                      return const Iterable<String>.empty();
                    }

                    try {
                      final localityOptions = await Provider.of<InventoryProvider>(context, listen: false).getDistinctLocalities();
                      final query = removeDiacritics(textEditingValue.text);
                      return localityOptions.where((String option) {
                        return removeDiacritics(option).contains(query);
                      });
                    } catch (e) {
                      debugPrint('Error fetching locality options: $e');
                      return const Iterable<String>.empty();
                    }
                  },
                  onSelected: (String selection) {
                    _localityNameController.text = selection;
                    fieldLocalityEditingController.text = selection;
                  },
                  fieldViewBuilder: (BuildContext context,
                      TextEditingController fieldTextEditingController,
                      FocusNode fieldFocusNode,
                      VoidCallback onFieldSubmitted) {
                    fieldLocalityEditingController = fieldTextEditingController;
                    fieldLocalityEditingController.text = widget.inventory.localityName ?? '';
                    return TextFormField(
                      controller: fieldLocalityEditingController,
                      focusNode: fieldFocusNode,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: '${S.of(context).locality} *',
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
}