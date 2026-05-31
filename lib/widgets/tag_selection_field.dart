import 'dart:math';
import 'package:flutter/material.dart';

import '../core/core_consts.dart';
import '../data/models/predefined_tag.dart';
import '../data/models/tag.dart';
import '../generated/l10n.dart';

/// A widget for selecting and managing tags with autocomplete and chip display.
///
/// Displays selected tags as removable chips and provides autocomplete suggestions
/// when typing. Known tags reuse their persisted color; brand new custom tags get a
/// random color from the palette.
class TagSelectionField extends StatefulWidget {
  /// Initial list of tags to display.
  final List<JournalTag> initialTags;

  /// Predefined tag suggestions for autocomplete.
  final List<String> predefinedTags;

  /// All available tag names from the system for suggestions.
  final List<String> allTagNames;

  /// All known tag definitions with their persisted colors.
  final List<PredefinedTag> tagDefinitions;

  /// Callback when tags are updated.
  final ValueChanged<List<JournalTag>> onTagsChanged;

  /// Optional label for the input field.
  final String? label;

  /// Optional hint text for the input field.
  final String? hint;

  /// Optional decorations for the input field.
  final InputDecoration? decoration;

  const TagSelectionField({
    super.key,
    required this.initialTags,
    required this.predefinedTags,
    required this.allTagNames,
    required this.tagDefinitions,
    required this.onTagsChanged,
    this.label,
    this.hint,
    this.decoration,
  });

  @override
  State<TagSelectionField> createState() => TagSelectionFieldState();
}

class TagSelectionFieldState extends State<TagSelectionField> {
  late List<JournalTag> selectedTags;
  late TextEditingController _textController;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    selectedTags = List.from(widget.initialTags);
    _textController = TextEditingController();
    _focusNode = FocusNode();
  }

  /// Commits the current input text as a tag if the field is not empty.
  void commitPendingTag() {
    final pendingTag = _textController.text.trim();
    if (pendingTag.isNotEmpty) {
      _addTag(pendingTag);
    }
  }

  String _normalizeForMatching(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('é', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ç', 'c');
  }

  bool _isSameTag(String left, String right) {
    return _normalizeForMatching(left) == _normalizeForMatching(right);
  }

  PredefinedTag? _findTagDefinition(String tagName) {
    for (final definition in widget.tagDefinitions) {
      if (_isSameTag(definition.name, tagName)) {
        return definition;
      }
    }
    return null;
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _addTag(String tagName) {
    final cleanedTagName = tagName.trim();
    if (cleanedTagName.isEmpty) return;

    // Check if tag already exists
    if (selectedTags.any((t) => _isSameTag(t.name, cleanedTagName))) {
      return;
    }

    final existingDefinition = _findTagDefinition(cleanedTagName);
    final isCustom = existingDefinition?.isCustom ?? !widget.predefinedTags.any((t) => _isSameTag(t, cleanedTagName));
    final colorIndex = existingDefinition?.colorIndex ?? Random().nextInt(kJournalTagColors.length);

    final newTag = JournalTag(
      journalId: 0, // Will be set when saving
      name: cleanedTagName,
      colorIndex: colorIndex,
      isCustom: isCustom,
    );

    setState(() {
      selectedTags.add(newTag);
      _textController.clear();
    });

    widget.onTagsChanged(selectedTags);
  }

  Iterable<String> _suggestionsFor(String rawInput) {
    final input = _normalizeForMatching(rawInput);
    if (input.isEmpty) {
      return const [];
    }

    final suggestions = <String>{};

    for (final tag in widget.predefinedTags) {
      if (_normalizeForMatching(tag).contains(input) && !selectedTags.any((t) => _isSameTag(t.name, tag))) {
        suggestions.add(tag);
      }
    }

    for (final tag in widget.allTagNames) {
      if (_normalizeForMatching(tag).contains(input) && !selectedTags.any((t) => _isSameTag(t.name, tag))) {
        suggestions.add(tag);
      }
    }

    final list = suggestions.toList()..sort((a, b) => _normalizeForMatching(a).compareTo(_normalizeForMatching(b)));
    return list;
  }

  void _removeTag(int index) {
    setState(() {
      selectedTags.removeAt(index);
    });
    widget.onTagsChanged(selectedTags);
  }

  @override
  Widget build(BuildContext context) {
    final inputDecoration =
        widget.decoration ??
        InputDecoration(
          labelText: widget.label ?? S.current.tags,
          hintText: widget.hint ?? S.current.addTag,
          border: OutlineInputBorder(),
          isDense: true,
          contentPadding: EdgeInsets.all(12),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tag chips
        if (selectedTags.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(bottom: 4),
            child: Wrap(
              spacing: 4,
              runSpacing: 2,
              children: List.generate(selectedTags.length, (index) {
                final tag = selectedTags[index];
                final color = getTagColorByIndex(tag.colorIndex);

                return Chip(
                  label: Text(tag.name, style: TextStyle(fontSize: 12)),
                  backgroundColor: color.withValues(alpha: 0.2),
                  labelStyle: TextStyle(color: color, fontWeight: FontWeight.w500),
                  labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                  deleteIcon: Icon(Icons.close, size: 14, color: color),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  onDeleted: () => _removeTag(index),
                );
              }),
            ),
          ),
        // Input field with Flutter's standard autocomplete suggestions.
        Autocomplete<String>(
          textEditingController: _textController,
          focusNode: _focusNode,
          displayStringForOption: (option) => option,
          optionsBuilder: (TextEditingValue textEditingValue) {
            return _suggestionsFor(textEditingValue.text);
          },
          onSelected: _addTag,
          fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
            return TextFormField(
              controller: textEditingController,
              focusNode: focusNode,
              decoration: inputDecoration.copyWith(
                suffixIcon: IconButton(icon: const Icon(Icons.add), tooltip: S.current.addTag, onPressed: commitPendingTag),
              ),
              textCapitalization: TextCapitalization.none,
              onFieldSubmitted: (value) {
                commitPendingTag();
              },
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            final optionsList = options.toList();
            if (optionsList.isEmpty) {
              return const SizedBox.shrink();
            }

            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 8,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 220),
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: optionsList.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final suggestion = optionsList[index];
                      return ListTile(title: Text(suggestion), dense: true, onTap: () => onSelected(suggestion));
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
