import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/journal.dart';
import '../../providers/journal_provider.dart';
import '../../generated/l10n.dart';

class AddJournalScreen extends StatefulWidget {
  final FieldJournal? journalEntry;
  final bool isEditing;

  const AddJournalScreen({
    super.key,
    this.journalEntry,
    this.isEditing = false,
  });

  @override
  AddJournalScreenState createState() => AddJournalScreenState();
}

class AddJournalScreenState extends State<AddJournalScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _notesController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _notesController = TextEditingController();
    
    if (widget.isEditing) {
      _titleController.text = widget.journalEntry!.title;
      _notesController.text = widget.journalEntry!.notes ?? '';
    } 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(S.of(context).newJournalEntry),
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
                        TextFormField(
                          controller: _titleController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: InputDecoration(
                            labelText: '${S.of(context).title} *',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return S.of(context).insertTitle;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16.0),
                        
                        // >> ADD FLEATHER EDITOR HERE

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
    final journalProvider = Provider.of<FieldJournalProvider>(context, listen: false);
    setState(() {
      _isSubmitting = true;
    });

    if (_formKey.currentState!.validate()) {
      if (widget.isEditing) {
        final updatedEntry = widget.journalEntry!.copyWith(
          title: _titleController.text,
          notes: _notesController.text,
          lastModifiedDate: DateTime.now(),
        );

        try {
          await journalProvider.updateJournalEntry(updatedEntry);

          Navigator.pop(context);
        } catch (error) {
          if (kDebugMode) {
            print('Error saving field journal entry: $error');
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error_outlined, color: Colors.red),
                  SizedBox(width: 8),
                  Text(S.current.errorSavingJournalEntry),
                ],
              ),
            ),
          );
        }
      } else {
        // Create Nest object with form data
        final newEntry = FieldJournal(
          title: _titleController.text,
          notes: _notesController.text,
          creationDate: DateTime.now(),
          lastModifiedDate: DateTime.now(),
        );

        setState(() {
          _isSubmitting = false;
        });

        try {
          await journalProvider.addJournalEntry(newEntry);
          Navigator.pop(context);
        } catch (error) {
          if (kDebugMode) {
            print('Error adding field journal entry: $error');
          }
          
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.error_outlined, color: Colors.red),
                    SizedBox(width: 8),
                    Text(S.current.errorSavingJournalEntry),
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