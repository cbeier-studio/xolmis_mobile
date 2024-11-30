import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/nest.dart';
import '../../providers/nest_revision_provider.dart';
import '../../generated/l10n.dart';

class AddNestRevisionScreen extends StatefulWidget {
  final Nest nest;

  const AddNestRevisionScreen({super.key, required this.nest});

  @override
  _AddNestRevisionScreenState createState() => _AddNestRevisionScreenState();
}

class _AddNestRevisionScreenState extends State<AddNestRevisionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _eggsHostController = TextEditingController();
  final _nestlingsHostController = TextEditingController();
  final _eggsParasiteController = TextEditingController();
  final _nestlingsParasiteController = TextEditingController();
  NestStatusType _selectedNestStatus = NestStatusType.nstActive;
  NestStageType _selectedNestStage = NestStageType.stgUnknown;
  final _notesController = TextEditingController();
  bool _hasPhilornisLarvae = false;
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(S.of(context).nestRevision),
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
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(S.of(context).host),
                        ),
                        const SizedBox(height: 8.0),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _eggsHostController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: S.of(context).egg(2),
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8.0),
                            Expanded(
                              child: TextFormField(
                                controller: _nestlingsHostController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: S.of(context).nestling(2),
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8.0),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(S.of(context).nidoparasite),
                        ),
                        const SizedBox(height: 8.0),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _eggsParasiteController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: S.of(context).egg(2),
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8.0),
                            Expanded(
                              child: TextFormField(
                                controller: _nestlingsParasiteController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: S.of(context).nestling(2),
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20.0),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<NestStatusType>(
                                  value: _selectedNestStatus,
                                  decoration: InputDecoration(
                                    labelText: '${S.of(context).nestStatus} *',
                                    helperText: S.of(context).requiredField,
                                    border: OutlineInputBorder(),
                                  ),
                                  items: NestStatusType.values.map((nestStatus) {
                                    return DropdownMenuItem(
                                      value: nestStatus,
                                      child: Text(nestStatusTypeFriendlyNames[nestStatus]!),
                                    );
                                  }).toList(),
                                  onChanged: (NestStatusType? newValue) {
                                    setState(() {
                                      _selectedNestStatus = newValue!;
                                    });
                                  }
                              ),
                            ),
                            const SizedBox(width: 8.0),
                            Expanded(
                              child: DropdownButtonFormField<NestStageType>(
                                  value: _selectedNestStage,
                                  decoration: InputDecoration(
                                    labelText: '${S.of(context).nestPhase} *',
                                    helperText: S.of(context).requiredField,
                                    border: OutlineInputBorder(),
                                  ),
                                  items: NestStageType.values.map((nestStage) {
                                    return DropdownMenuItem(
                                      value: nestStage,
                                      child: Text(nestStageTypeFriendlyNames[nestStage]!),
                                    );
                                  }).toList(),
                                  onChanged: (NestStageType? newValue) {
                                    setState(() {
                                      _selectedNestStage = newValue!;
                                    });
                                  }
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8.0),
                        CheckboxListTile(
                          title: Text(S.of(context).philornisLarvaePresent),
                          value: _hasPhilornisLarvae,
                          onChanged: (bool? value) {
                            setState(() {
                              _hasPhilornisLarvae = value!;
                            });
                          },
                        ),
                        const SizedBox(height: 8.0),
                        TextFormField(
                          controller: _notesController,
                          maxLines: 3,
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
                        child: CircularProgressIndicator(strokeWidth: 2),
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

  void _submitForm() async {
    final revisionProvider = Provider.of<NestRevisionProvider>(context, listen: false);

    if (_formKey.currentState!.validate()) {
      // Create Nest object with form data
      final newRevision = NestRevision(
        eggsHost: int.tryParse(_eggsHostController.text),
        nestlingsHost: int.tryParse(_nestlingsHostController.text),
        eggsParasite: int.tryParse(_eggsParasiteController.text),
        nestlingsParasite: int.tryParse(_nestlingsParasiteController.text),
        nestStatus: _selectedNestStatus,
        nestStage: _selectedNestStage,
        notes: _notesController.text,
        sampleTime: DateTime.now(),
        hasPhilornisLarvae: _hasPhilornisLarvae,
      );

      setState(() {
        _isSubmitting = false;
      });

      try {
        await revisionProvider.addNestRevision(context, widget.nest.id!, newRevision);
        Navigator.pop(context);
        // ScaffoldMessenger.of(context).showSnackBar(
        //   const SnackBar(content: Row(
        //     children: [
        //       Icon(Icons.check_circle_outlined, color: Colors.green),
        //       SizedBox(width: 8),
        //       Text('Revisão de ninho adicionada!'),
        //     ],
        //   ),
        //   ),
        // );
      } catch (error) {
        if (kDebugMode) {
          print('Error adding nest revision: $error');
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Row(
            children: [
              Icon(Icons.error_outlined, color: Colors.red),
              SizedBox(width: 8),
              Text(S.current.errorSavingRevision),
            ],
          ),
          ),
        );
      }
    } else {
      setState(() {
        _isSubmitting = false;
      });
    }
  }
}