import 'dart:convert';
import 'dart:io';

import 'package:fleather/fleather.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

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
  final FocusNode _focusNode = FocusNode();
  final GlobalKey<EditorState> _editorKey = GlobalKey();
  late TextEditingController _titleController;
  late FleatherController _notesController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();

    if (widget.isEditing) {
      _titleController.text = widget.journalEntry!.title;
      dynamic notesJson;
      try {
        notesJson = jsonDecode(widget.journalEntry!.notes!);
        final doc = ParchmentDocument.fromJson(notesJson);
        _notesController = FleatherController(document: doc);
      } catch (e) {
        notesJson = [];
        _notesController = FleatherController();
      }
    } else {
      _notesController = FleatherController();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).newJournalEntry),
        actions: [
          MenuAnchor(
            builder: (context, controller, child) {
              return IconButton(
                icon: Icon(Icons.add_a_photo_outlined),
                tooltip: S.of(context).addImage,
                onPressed: () {
                  if (controller.isOpen) {
                    controller.close();
                  } else {
                    controller.open();
                  }
                },
              );
            },
            menuChildren: [
              MenuItemButton(
                onPressed: () async {
                  final picker = ImagePicker();
                  final pickedFile = await picker.pickImage(source: ImageSource.camera);
                  if (pickedFile != null) {
                    // Save the image to the app's documents directory
                    final directory = await getApplicationDocumentsDirectory();
                    final fileName = path.basename(pickedFile.path);
                    final savedImage = await File(pickedFile.path).copy('${directory.path}/$fileName');
      
                    final selection = _notesController.selection;
                    _notesController.replaceText(
                      selection.baseOffset,
                      selection.extentOffset - selection.baseOffset,
                      EmbeddableObject('image', inline: false, data: {
                        'source_type': kIsWeb ? 'url' : 'file',
                        'source': savedImage.path,
                      }),
                    );
                    _notesController.replaceText(
                      selection.baseOffset + 1,
                      0,
                      '\n',
                      selection: TextSelection.collapsed(
                          offset: selection.baseOffset + 2),
                    );
                  }
                },
                child: Text(S.current.camera),
              ),
              MenuItemButton(
                onPressed: () async {
                  final picker = ImagePicker();
                  final image = await picker.pickImage(source: ImageSource.gallery);
                  if (image != null) {
                    final selection = _notesController.selection;
                    _notesController.replaceText(
                      selection.baseOffset,
                      selection.extentOffset - selection.baseOffset,
                      EmbeddableObject('image', inline: false, data: {
                        'source_type': kIsWeb ? 'url' : 'file',
                        'source': image.path,
                      }),
                    );
                    _notesController.replaceText(
                      selection.baseOffset + 1,
                      0,
                      '\n',
                      selection: TextSelection.collapsed(
                          offset: selection.baseOffset + 2),
                    );
                  }
                },
                child: Text(S.current.gallery),
              ),
            ],
          ),
        ],
      ),
        body: Column(
            children: [
              Form(
                key: _formKey,
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: TextFormField(
                          controller: _titleController,
                          textCapitalization: TextCapitalization.sentences,
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
                ),
              ),
                        // const SizedBox(height: 16.0),
                Expanded(
                  child: FleatherEditor(
                    controller: _notesController,
                    focusNode: _focusNode,
                    editorKey: _editorKey,
                    
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      bottom: MediaQuery.of(context).padding.bottom,
                    ),
                    onLaunchUrl: _launchUrl,
                    maxContentWidth: 800,
                    embedBuilder: _embedBuilder,
                    spellCheckConfiguration: SpellCheckConfiguration(
                        spellCheckService: DefaultSpellCheckService(),
                        misspelledSelectionColor: Colors.red,
                        misspelledTextStyle:
                            DefaultTextStyle.of(context).style),
                  ),
                ),
                FleatherToolbar.basic(
                    controller: _notesController, editorKey: _editorKey),
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
            ],   
                  ),
    );
  }

  Widget _embedBuilder(BuildContext context, EmbedNode node) {
    if (node.value.type == 'icon') {
      final data = node.value.data;
      // Icons.rocket_launch_outlined
      return Icon(
        IconData(int.parse(data['codePoint']), fontFamily: data['fontFamily']),
        color: Color(int.parse(data['color'])),
        size: 18,
      );
    }

    if (node.value.type == 'image') {
      final sourceType = node.value.data['source_type'];
      ImageProvider? image;
      if (sourceType == 'assets') {
        image = AssetImage(node.value.data['source']);
      } else if (sourceType == 'file') {
        image = FileImage(File(node.value.data['source']));
      } else if (sourceType == 'url') {
        image = NetworkImage(node.value.data['source']);
      }
      if (image != null) {
        return Padding(
          // Caret takes 2 pixels, hence not symmetric padding values.
          padding: const EdgeInsets.only(left: 4, right: 2, top: 2, bottom: 2),
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              image: DecorationImage(image: image, fit: BoxFit.cover),
            ),
          ),
        );
      }
    }

    return defaultFleatherEmbedBuilder(context, node);
  }

  void _launchUrl(String? url) async {
    if (url == null) return;
    final uri = Uri.parse(url);
    final canLaunch = await canLaunchUrl(uri);
    if (canLaunch) {
      await launchUrl(uri);
    }
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
          notes: jsonEncode(_notesController.document.toDelta().toList()),
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
          notes: jsonEncode(_notesController.document.toDelta().toList()),
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