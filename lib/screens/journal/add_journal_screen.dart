import 'dart:convert';
import 'dart:io';

import 'package:fleather/fleather.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/journal.dart';
import '../../data/models/predefined_tag.dart';
import '../../data/models/tag.dart';
import '../../data/daos/tag_dao.dart';
import '../../data/database/database_helper.dart';
import '../../providers/journal_provider.dart';
import '../../generated/l10n.dart';
import '../../utils/utils.dart';
import '../../widgets/tag_selection_field.dart';

/// Screen used to create or edit a field journal entry.
class AddJournalScreen extends StatefulWidget {
  final FieldJournal? journalEntry;
  final bool isEditing;
  final bool isEmbedded;

  /// Creates a journal form screen.
  const AddJournalScreen({super.key, this.journalEntry, this.isEditing = false, this.isEmbedded = false});

  /// Creates the mutable state for [AddJournalScreen].
  @override
  AddJournalScreenState createState() => AddJournalScreenState();
}

/// State implementation for [AddJournalScreen].
class AddJournalScreenState extends State<AddJournalScreen> {
  final _formKey = GlobalKey<FormState>();
  final FocusNode _focusNode = FocusNode();
  final GlobalKey<EditorState> _editorKey = GlobalKey();
  final GlobalKey<TagSelectionFieldState> _tagSelectionKey = GlobalKey<TagSelectionFieldState>();
  late TextEditingController _titleController;
  late FleatherController _notesController;
  bool _isSubmitting = false;
  bool _editorHasFocus = false;
  String _observerAbbrev = '';
  late TagDao _tagDao;
  List<PredefinedTag> _tagDefinitions = [];
  List<String> _predefinedTags = [];
  List<String> _allTagNames = [];
  late List<JournalTag> _selectedTags = [];

  @override
  void initState() {
    super.initState();
    _tagDao = TagDao(DatabaseHelper.instance);
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
    _loadObserverAbbreviation();
    _loadTagData();
    _focusNode.addListener(_onEditorFocusChange);
  }

  void _onEditorFocusChange() {
    setState(() {
      _editorHasFocus = _focusNode.hasFocus;
    });
  }

  void _loadTagData() async {
    try {
      final definitions = await _tagDao.getAllTagDefinitions();
      final predefined = await _tagDao.getPredefinedTags();
      final allNames = await _tagDao.getAllTagNames();
      final sortedDefinitions = definitions.toList()..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      final sortedPredefined = predefined.toSet().toList()..sort();
      final sortedAllNames = allNames.toSet().toList()..sort();

      setState(() {
        _tagDefinitions = sortedDefinitions;
        _predefinedTags = sortedPredefined;
        _allTagNames = sortedAllNames;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error loading tag data: $e');
      }
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onEditorFocusChange);
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _loadObserverAbbreviation() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _observerAbbrev = prefs.getString('observer_abbreviation') ?? '';
    });
  }

  /// Builds the top action area used by the embedded layout variant.
  Widget _buildTopArea(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Title + actions row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.isEditing ? S.current.editJournalEntry : S.current.newJournalEntry,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_location_alt_outlined),
                tooltip: S.of(context).addCoordinates,
                onPressed: () async {
                  Position? position = await getPosition(context);
                  if (position != null) {
                    final selection = _notesController.selection;
                    final positionText = '${position.longitude}; ${position.latitude}';
                    _notesController.replaceText(
                      selection.baseOffset,
                      0,
                      positionText,
                      selection: TextSelection.collapsed(offset: selection.baseOffset + positionText.length),
                    );
                  }
                },
              ),
              MenuAnchor(
                builder: (context, controller, child) {
                  return IconButton(
                    icon: const Icon(Icons.add_a_photo_outlined),
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
                          EmbeddableObject(
                            'image',
                            inline: false,
                            data: {'source_type': kIsWeb ? 'url' : 'file', 'source': savedImage.path},
                          ),
                        );
                        _notesController.replaceText(
                          selection.baseOffset + 1,
                          0,
                          '\n',
                          selection: TextSelection.collapsed(offset: selection.baseOffset + 2),
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
                          EmbeddableObject(
                            'image',
                            inline: false,
                            data: {'source_type': kIsWeb ? 'url' : 'file', 'source': image.path},
                          ),
                        );
                        _notesController.replaceText(
                          selection.baseOffset + 1,
                          0,
                          '\n',
                          selection: TextSelection.collapsed(offset: selection.baseOffset + 2),
                        );
                      }
                    },
                    child: Text(S.current.gallery),
                  ),
                ],
              ),
              _isSubmitting
                  ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, year2023: false),
                  )
                  : FilledButton(onPressed: _submitForm, child: Text(S.of(context).save)),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // If embedded, return widget without Scaffold/AppBar
    if (widget.isEmbedded) {
      return SafeArea(
        child: Column(
          children: [
            _buildTopArea(context),
            Expanded(
              child: Column(
                children: [
                  Form(
                    key: _formKey,
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          AnimatedSize(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 200),
                              opacity: _editorHasFocus ? 0.0 : 1.0,
                              child: _editorHasFocus
                                  ? const SizedBox.shrink()
                                  : Column(
                                      children: [
                                        TextFormField(
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
                                        const SizedBox(height: 16),
                                      ],
                                    ),
                            ),
                          ),
                          TagSelectionField(
                            key: _tagSelectionKey,
                            initialTags: widget.isEditing ? widget.journalEntry!.tags : [],
                            predefinedTags: _predefinedTags,
                            allTagNames: _allTagNames,
                            tagDefinitions: _tagDefinitions,
                            onTagsChanged: (tags) {
                              setState(() {
                                _selectedTags = tags;
                              });
                              if (widget.isEditing) {
                                widget.journalEntry!.tags = tags;
                              }
                            },
                            label: S.of(context).tags,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: FleatherEditor(
                      controller: _notesController,
                      focusNode: _focusNode,
                      editorKey: _editorKey,

                      padding: EdgeInsets.only(left: 16, right: 16, bottom: MediaQuery.of(context).padding.bottom),
                      onLaunchUrl: _launchUrl,
                      maxContentWidth: 800,
                      embedBuilder: _embedBuilder,
                      spellCheckConfiguration: SpellCheckConfiguration(
                        spellCheckService: DefaultSpellCheckService(),
                        misspelledSelectionColor: Colors.red,
                        misspelledTextStyle: DefaultTextStyle.of(context).style,
                      ),
                    ),
                  ),
                  FleatherToolbar.basic(controller: _notesController, editorKey: _editorKey),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? S.current.editJournalEntry : S.of(context).newJournalEntry),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_location_alt_outlined),
            tooltip: S.of(context).addCoordinates,
            onPressed: () async {
              Position? position = await getPosition(context);
              if (position != null) {
                final selection = _notesController.selection;
                final positionText = '${position.longitude}; ${position.latitude}';
                _notesController.replaceText(
                  selection.baseOffset,
                  0,
                  positionText,
                  selection: TextSelection.collapsed(offset: selection.baseOffset + positionText.length),
                );
              }
            },
          ),
          MenuAnchor(
            builder: (context, controller, child) {
              return IconButton(
                icon: const Icon(Icons.add_a_photo_outlined),
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
                      EmbeddableObject(
                        'image',
                        inline: false,
                        data: {'source_type': kIsWeb ? 'url' : 'file', 'source': savedImage.path},
                      ),
                    );
                    _notesController.replaceText(
                      selection.baseOffset + 1,
                      0,
                      '\n',
                      selection: TextSelection.collapsed(offset: selection.baseOffset + 2),
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
                      EmbeddableObject(
                        'image',
                        inline: false,
                        data: {'source_type': kIsWeb ? 'url' : 'file', 'source': image.path},
                      ),
                    );
                    _notesController.replaceText(
                      selection.baseOffset + 1,
                      0,
                      '\n',
                      selection: TextSelection.collapsed(offset: selection.baseOffset + 2),
                    );
                  }
                },
                child: Text(S.current.gallery),
              ),
            ],
          ),
          _isSubmitting
              ? const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2, year2023: false),
          )
              : TextButton(onPressed: _submitForm, child: Text(S.of(context).save)),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: FleatherEditor(
              controller: _notesController,
              focusNode: _focusNode,
              editorKey: _editorKey,

              padding: EdgeInsets.only(left: 16, right: 16, bottom: MediaQuery.of(context).padding.bottom),
              onLaunchUrl: _launchUrl,
              maxContentWidth: 800,
              embedBuilder: _embedBuilder,
              spellCheckConfiguration: SpellCheckConfiguration(
                spellCheckService: DefaultSpellCheckService(),
                misspelledSelectionColor: Colors.red,
                misspelledTextStyle: DefaultTextStyle.of(context).style,
              ),
            ),
          ),
          FleatherToolbar.basic(controller: _notesController, editorKey: _editorKey),
          Form(
            key: _formKey,
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                children: [
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: _editorHasFocus ? 0.0 : 1.0,
                      child: _editorHasFocus
                          ? const SizedBox.shrink()
                          : Column(
                              children: [
                                TextFormField(
                                  controller: _titleController,
                                  textCapitalization: TextCapitalization.sentences,
                                  decoration: InputDecoration(
                                    labelText: '${S.of(context).title} (${S.of(context).optional})',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
                    ),
                  ),
                  TagSelectionField(
                    key: _tagSelectionKey,
                    initialTags: widget.isEditing ? widget.journalEntry!.tags : [],
                    predefinedTags: _predefinedTags,
                    allTagNames: _allTagNames,
                    tagDefinitions: _tagDefinitions,
                    onTagsChanged: (tags) {
                      setState(() {
                        _selectedTags = tags;
                      });
                      if (widget.isEditing) {
                        widget.journalEntry!.tags = tags;
                      }
                    },
                    label: S.of(context).tags,
                  ),
                ],
              ),
            ),
          ),
          // SafeArea(
          //   child: Container(
          //     padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
          //     width: double.infinity,
          //     child: Align(
          //       alignment: Alignment.centerRight,
          //       child:
          //           _isSubmitting
          //               ? const SizedBox(
          //                 width: 24,
          //                 height: 24,
          //                 child: CircularProgressIndicator(strokeWidth: 2, year2023: false),
          //               )
          //               : FilledButton(onPressed: _submitForm, child: Text(S.of(context).save)),
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }

  /// Builds embedded content for custom editor nodes such as images.
  Widget _embedBuilder(BuildContext context, EmbedNode node) {
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
            decoration: BoxDecoration(image: DecorationImage(image: image, fit: BoxFit.cover)),
          ),
        );
      }
    }

    return defaultFleatherEmbedBuilder(context, node);
  }

  /// Launches a URL inserted inside the journal editor.
  void _launchUrl(String? url) async {
    if (url == null) return;
    final uri = Uri.parse(url);
    final canLaunch = await canLaunchUrl(uri);
    if (canLaunch) {
      await launchUrl(uri);
    }
  }

  /// Validates and saves the journal entry using the provider layer.
  void _submitForm() async {
    // Preserve a typed tag even when the user taps save without submitting the field.
    _tagSelectionKey.currentState?.commitPendingTag();

    final journalProvider = Provider.of<FieldJournalProvider>(context, listen: false);
    final notesDeltaJson = jsonEncode(_notesController.document.toDelta().toList());
    final notesPlainText = plainTextFromDelta(notesDeltaJson).trim();

    setState(() {
      _isSubmitting = true;
    });

    if (notesPlainText.isEmpty) {
      setState(() {
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          persist: false,
          showCloseIcon: true,
          backgroundColor: Theme.of(context).colorScheme.error,
          content: Text(S.current.fieldCannotBeEmpty),
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      if (widget.isEditing) {
        final updatedEntry = widget.journalEntry!.copyWith(
          title: _titleController.text,
          notes: notesDeltaJson,
          lastModifiedDate: DateTime.now(),
        );

        try {
          await journalProvider.updateJournalEntry(updatedEntry);

          if (!widget.isEmbedded) {
            Navigator.pop(context);
          }
        } catch (error) {
          if (kDebugMode) {
            print('Error saving field journal entry: $error');
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              persist: true,
              showCloseIcon: true,
              backgroundColor: Theme.of(context).colorScheme.error,
              content: Text(S.current.errorSavingJournalEntry),
            ),
          );
        }
      } else {
        // Create FieldJournal object with form data
        final newEntry = FieldJournal(
          title: _titleController.text,
          notes: notesDeltaJson,
          observer: _observerAbbrev,
          creationDate: DateTime.now(),
          lastModifiedDate: DateTime.now(),
          tags: _selectedTags,
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
              persist: true,
              showCloseIcon: true,
              backgroundColor: Theme.of(context).colorScheme.error,
              content: Text(S.current.errorSavingJournalEntry),
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
