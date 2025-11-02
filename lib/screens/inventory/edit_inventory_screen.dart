import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../data/models/inventory.dart';
import '../../generated/l10n.dart';
import '../../providers/inventory_provider.dart';

class EditInventoryScreen extends StatefulWidget {
  final Inventory inventory;

  const EditInventoryScreen({super.key, required this.inventory});

  @override
  State<EditInventoryScreen> createState() => _EditInventoryScreenState();
}

class _EditInventoryScreenState extends State<EditInventoryScreen> {
  late final TextEditingController _localityNameController;
  late final TextEditingController _notesController;
  late final TextEditingController _totalObserversController;
  late bool _isDiscarded;
  late TextEditingController fieldLocalityEditingController;

  final _formKey = GlobalKey<FormState>();
  late final inventoryProvider = Provider.of<InventoryProvider>(
      context, listen: false);

  @override
  void initState() {
    super.initState();
    // Inicializa os controladores com os dados da espécie recebida
    _localityNameController = TextEditingController(text: widget.inventory.localityName);
    _notesController = TextEditingController(text: widget.inventory.notes);
    _totalObserversController = TextEditingController(text: widget.inventory.totalObservers.toString());
    _isDiscarded = widget.inventory.isDiscarded;
  }

  @override
  void dispose() {
    // Libera os recursos dos controladores
    _localityNameController.dispose();
    _notesController.dispose();
    _totalObserversController.dispose();
    super.dispose();
  }

  void _saveForm() {
    // Valida e salva o formulário
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Cria uma cópia da espécie original com os dados atualizados do formulário
      final updatedInventory = widget.inventory.copyWith(
        localityName: fieldLocalityEditingController.text,
        totalObservers: int.tryParse(_totalObserversController.text),
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        isDiscarded: _isDiscarded,
      );

      // final speciesProvider = Provider.of<SpeciesProvider>(context, listen: false);
      // await speciesProvider.editSpecies(context, widget.inventory.id, updatedSpecies);

      // Retorna para a tela anterior com o objeto 'Species' atualizado
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
                Autocomplete<String>(
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
                        // helperText: S.of(context).requiredField,
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
                SwitchListTile.adaptive(
                  title: Text(S.current.discardedInventory),
                  value: _isDiscarded,
                  onChanged: (bool value) {
                    setState(() {
                      _isDiscarded = value;
                    });
                  },
                ),
                SizedBox(height: 8),
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
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}