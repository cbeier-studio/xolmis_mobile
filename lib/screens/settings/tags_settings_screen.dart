import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/core_consts.dart';
import '../../data/models/predefined_tag.dart';
import '../../generated/l10n.dart';
import '../../providers/tag_provider.dart';

/// Screen for managing predefined and custom journal tags.
class TagsSettingsScreen extends StatefulWidget {
  const TagsSettingsScreen({super.key});

  @override
  State<TagsSettingsScreen> createState() => _TagsSettingsScreenState();
}

class _TagsSettingsScreenState extends State<TagsSettingsScreen> {
  final TextEditingController _newTagController = TextEditingController();
  bool _isAddingTag = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TagProvider>().fetchTagDefinitions();
    });
  }

  @override
  void dispose() {
    _newTagController.dispose();
    super.dispose();
  }

  Future<void> _addCustomTag() async {
    final tagName = _newTagController.text.trim();
    if (tagName.isEmpty) {
      return;
    }

    setState(() {
      _isAddingTag = true;
    });

    try {
      await context.read<TagProvider>().addCustomTag(tagName);
      _newTagController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          persist: true,
          showCloseIcon: true,
          backgroundColor: Theme.of(context).colorScheme.error,
          content: Text(S.current.errorSavingJournalEntry),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isAddingTag = false;
        });
      }
    }
  }

  Future<void> _showColorPicker(PredefinedTag tag) async {
    final colorIndex = await showDialog<int>(
      context: context,
      builder: (context) {
        int selectedIndex = tag.colorIndex;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(S.current.changeTagColor),
              content: SingleChildScrollView(
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: List.generate(kJournalTagColors.length, (index) {
                    final color = getTagColorByIndex(index);
                    final isSelected = index == selectedIndex;

                    return InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: () {
                        setDialogState(() {
                          selectedIndex = index;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Theme.of(context).colorScheme.onSurface : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow:
                              isSelected
                                  ? [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 8, spreadRadius: 1)]
                                  : null,
                        ),
                      ),
                    );
                  }),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(S.current.cancel)),
                FilledButton(onPressed: () => Navigator.of(context).pop(selectedIndex), child: Text(S.current.save)),
              ],
            );
          },
        );
      },
    );

    if (colorIndex == null || !mounted) return;

    await context.read<TagProvider>().updateTagColor(tagId: tag.id, colorIndex: colorIndex);
  }

  Future<void> _deleteCustomTag(PredefinedTag tag) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(S.current.confirmDelete),
          content: Text(S.of(context).confirmDeleteMessage(1, 'female', S.current.tags.toLowerCase())),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(S.current.cancel)),
            TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text(S.current.delete)),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    await context.read<TagProvider>().deleteCustomTag(tag.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.current.manageTags)),
      body: Consumer<TagProvider>(
        builder: (context, tagProvider, child) {
          final tags = tagProvider.tagDefinitions;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _newTagController,
                        textCapitalization: TextCapitalization.none,
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          labelText: S.current.addTag,
                          suffixIcon: _isAddingTag
                              ? const SizedBox(width: 26, height: 26, child: CircularProgressIndicator(strokeWidth: 2))
                              : IconButton(onPressed: _addCustomTag, icon: Icon(Icons.add))
                        ),
                        onSubmitted: (_) => _addCustomTag(),
                      ),
                    ),
                    // const SizedBox(width: 8),
                    // _isAddingTag
                    //     ? const SizedBox(width: 32, height: 32, child: CircularProgressIndicator(strokeWidth: 2))
                    //     : FilledButton.icon(
                    //       onPressed: _addCustomTag,
                    //       icon: const Icon(Icons.add),
                    //       label: Text(S.current.addButton),
                    //     ),
                  ],
                ),
              ),
              Expanded(
                child:
                    tags.isEmpty
                        ? Center(child: Text(S.current.noTagsFound))
                        : ListView.separated(
                          itemCount: tags.length,
                          separatorBuilder: (context, index) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final tag = tags[index];
                            final color = getTagColorByIndex(tag.colorIndex);
                            return ListTile(
                              leading: Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                              ),
                              title: Text(tag.name),
                              // subtitle: Text(tag.isCustom ? S.current.customTag : S.current.predefinedTag),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: S.current.changeTagColor,
                                    icon: const Icon(Icons.palette_outlined),
                                    onPressed: () => _showColorPicker(tag),
                                  ),
                                  if (tag.isCustom)
                                    IconButton(
                                      tooltip: S.current.delete,
                                      icon: Icon(Icons.delete_outlined, color: Theme.of(context).colorScheme.error),
                                      onPressed: () => _deleteCustomTag(tag),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
              ),
            ],
          );
        },
      ),
    );
  }
}
