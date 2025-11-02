import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/models/inventory.dart';
import '../../generated/l10n.dart';

class EditSpeciesScreen extends StatefulWidget {
  final Species species;

  const EditSpeciesScreen({super.key, required this.species});

  @override
  State<EditSpeciesScreen> createState() => _EditSpeciesScreenState();
}

class _EditSpeciesScreenState extends State<EditSpeciesScreen> {
  late final TextEditingController _countController;
  late final TextEditingController _distanceController;
  late final TextEditingController _flightHeightController;
  // late final TextEditingController _flightDirectionController;
  late final TextEditingController _notesController;
  late bool _isOutOfInventory;
  String? _selectedFlightDirection;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Inicializa os controladores com os dados da espécie recebida
    _countController = TextEditingController(text: widget.species.count.toString());
    _distanceController = TextEditingController(text: widget.species.distance?.toString());
    _flightHeightController = TextEditingController(text: widget.species.flightHeight?.toString());
    // _flightDirectionController = TextEditingController(text: widget.species.flightDirection);
    _notesController = TextEditingController(text: widget.species.notes);
    _isOutOfInventory = widget.species.isOutOfInventory;
    _selectedFlightDirection = widget.species.flightDirection;
  }

  @override
  void dispose() {
    // Libera os recursos dos controladores
    _countController.dispose();
    _distanceController.dispose();
    _flightHeightController.dispose();
    // _flightDirectionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _saveForm() {
    // Valida e salva o formulário
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Cria uma cópia da espécie original com os dados atualizados do formulário
      final updatedSpecies = widget.species.copyWith(
        count: int.tryParse(_countController.text) ?? widget.species.count,
        distance: double.tryParse(_distanceController.text),
        flightHeight: double.tryParse(_flightHeightController.text),
        flightDirection: _selectedFlightDirection,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        isOutOfInventory: _isOutOfInventory,
      );

      // final speciesProvider = Provider.of<SpeciesProvider>(context, listen: false);
      // await speciesProvider.editSpecies(context, widget.inventory.id, updatedSpecies);

      // Retorna para a tela anterior com o objeto 'Species' atualizado
      Navigator.of(context).pop(updatedSpecies);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.species.name),
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
                              icon: Icon(Icons.remove_outlined)),
                          suffixIcon: IconButton(
                              onPressed: () {
                                int count = int.tryParse(_countController.text) ?? 0;
                                setState(() {
                                  count++;
                                  _countController.text = count.toString();
                                });
                              },
                              icon: Icon(Icons.add_outlined)),
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
                        // hint: Text(S.current.selectADirection),
                        isExpanded: true,
                        items: [
                          // Pontos Cardeais
                          'N', 'S', 'E', 'W',
                          // Pontos Colaterais (Intercardinais)
                          'NE', 'NW', 'SE', 'SW',
                          // Pontos Subcolaterais (Secundários)
                          // 'NNE', 'ENE', 'ESE', 'SSE', 'SSW', 'WSW', 'WNW', 'NNW',
                        ].map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
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
                  decoration: InputDecoration(
                    labelText: S.current.notes,
                    border: OutlineInputBorder(),
                  ),
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
