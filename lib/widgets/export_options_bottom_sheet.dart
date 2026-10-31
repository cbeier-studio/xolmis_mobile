import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/core_consts.dart';
import '../generated/l10n.dart';

/// Supported file formats for exporting data records.
enum ExportFormat {
  csv,
  excel,
  json,
  kml,
  txt,
  markdown,
  word,
  pdf,
}

/// Convenience extension providing labels, extensions, icons, and MIME types for [ExportFormat].
extension ExportFormatExtension on ExportFormat {
  String get label {
    switch (this) {
      case ExportFormat.csv:
        return 'CSV';
      case ExportFormat.excel:
        return 'Excel';
      case ExportFormat.json:
        return 'JSON';
      case ExportFormat.kml:
        return 'KML';
      case ExportFormat.txt:
        return 'Plain Text';
      case ExportFormat.markdown:
        return 'Markdown';
      case ExportFormat.word:
        return 'Word';
      case ExportFormat.pdf:
        return 'PDF';
    }
  }

  String get fileExtension {
    switch (this) {
      case ExportFormat.csv:
        return '.csv';
      case ExportFormat.excel:
        return '.xlsx';
      case ExportFormat.json:
        return '.json';
      case ExportFormat.kml:
        return '.kml';
      case ExportFormat.txt:
        return '.txt';
      case ExportFormat.markdown:
        return '.md';
      case ExportFormat.word:
        return '.docx';
      case ExportFormat.pdf:
        return '.pdf';
    }
  }

  String get mimeType {
    switch (this) {
      case ExportFormat.csv:
        return 'text/csv';
      case ExportFormat.excel:
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case ExportFormat.json:
        return 'application/json';
      case ExportFormat.kml:
        return 'application/vnd.google-earth.kml+xml';
      case ExportFormat.txt:
        return 'text/plain';
      case ExportFormat.markdown:
        return 'text/markdown';
      case ExportFormat.word:
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case ExportFormat.pdf:
        return 'application/pdf';
    }
  }

  IconData get icon {
    switch (this) {
      case ExportFormat.csv:
        return Icons.description_outlined;
      case ExportFormat.excel:
        return Icons.table_view_outlined;
      case ExportFormat.json:
        return Icons.code_outlined;
      case ExportFormat.kml:
        return Icons.map_outlined;
      case ExportFormat.txt:
        return Icons.text_snippet_outlined;
      case ExportFormat.markdown:
        return Icons.article_outlined;
      case ExportFormat.word:
        return Icons.description_outlined;
      case ExportFormat.pdf:
        return Icons.picture_as_pdf_outlined;
    }
  }
}

/// Loads previously selected export formats from [SharedPreferences].
Future<Set<ExportFormat>> loadExportSelectedFormats() async {
  final prefs = await SharedPreferences.getInstance();
  final list = prefs.getStringList(kExportSelectedFormatsPreferenceKey);
  if (list == null || list.isEmpty) {
    return {
      ExportFormat.csv,
      ExportFormat.excel,
      ExportFormat.json,
      ExportFormat.kml,
    };
  }
  final formats = <ExportFormat>{};
  for (final name in list) {
    for (final format in ExportFormat.values) {
      if (format.name == name) {
        formats.add(format);
      }
    }
  }
  return formats.isEmpty
      ? {
        ExportFormat.csv,
        ExportFormat.excel,
        ExportFormat.json,
        ExportFormat.kml,
      }
      : formats;
}

/// Persists selected export formats to [SharedPreferences].
Future<void> saveExportSelectedFormats(
  Set<ExportFormat> formats, {
  List<ExportFormat>? contextFormats,
}) async {
  final prefs = await SharedPreferences.getInstance();
  Set<ExportFormat> finalSet = Set.from(formats);

  if (contextFormats != null && contextFormats.isNotEmpty) {
    final existingList = prefs.getStringList(kExportSelectedFormatsPreferenceKey) ?? [];
    final existingFormats = <ExportFormat>{};
    for (final name in existingList) {
      for (final format in ExportFormat.values) {
        if (format.name == name) {
          existingFormats.add(format);
        }
      }
    }
    final nonContextFormats = existingFormats.difference(contextFormats.toSet());
    finalSet = nonContextFormats.union(formats);
  }

  await prefs.setStringList(
    kExportSelectedFormatsPreferenceKey,
    finalSet.map((f) => f.name).toList(),
  );
}

/// Result returned by the export options dialog or bottom sheet.
class ExportOptionsResult {
  /// The user-defined file name prefix.
  final String prefix;

  /// The set of chosen file formats.
  final Set<ExportFormat> formats;

  const ExportOptionsResult({
    required this.prefix,
    required this.formats,
  });
}

/// Shows the export options UI as a modal bottom sheet on mobile or a dialog on larger screens.
Future<ExportOptionsResult?> showExportOptionsBottomSheet({
  required BuildContext context,
  required String defaultPrefix,
  String? title,
  String? subtitle,
  Set<ExportFormat>? initialFormats,
  List<ExportFormat> availableFormats = const [
    ExportFormat.csv,
    ExportFormat.excel,
    ExportFormat.json,
    ExportFormat.kml,
  ],
}) async {
  final isLargeScreen = MediaQuery.sizeOf(context).width >= 600;

  if (isLargeScreen) {
    return showDialog<ExportOptionsResult>(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: _ExportOptionsContent(
              defaultPrefix: defaultPrefix,
              title: title,
              subtitle: subtitle,
              initialFormats: initialFormats,
              availableFormats: availableFormats,
              isDialog: true,
            ),
          ),
        );
      },
    );
  }

  return showModalBottomSheet<ExportOptionsResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: _ExportOptionsContent(
          defaultPrefix: defaultPrefix,
          title: title,
          subtitle: subtitle,
          initialFormats: initialFormats,
          availableFormats: availableFormats,
          isDialog: false,
        ),
      );
    },
  );
}

/// Internal content widget containing the export settings form.
class _ExportOptionsContent extends StatefulWidget {
  final String defaultPrefix;
  final String? title;
  final String? subtitle;
  final Set<ExportFormat>? initialFormats;
  final List<ExportFormat> availableFormats;
  final bool isDialog;

  const _ExportOptionsContent({
    required this.defaultPrefix,
    this.title,
    this.subtitle,
    this.initialFormats,
    required this.availableFormats,
    required this.isDialog,
  });

  @override
  State<_ExportOptionsContent> createState() => _ExportOptionsContentState();
}

class _ExportOptionsContentState extends State<_ExportOptionsContent> {
  late final TextEditingController _prefixController;
  final Set<ExportFormat> _selectedFormats = {};
  bool _isLoadingFormats = true;
  String _sampleTimestamp = '';

  @override
  void initState() {
    super.initState();
    _prefixController = TextEditingController(text: widget.defaultPrefix);
    _sampleTimestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    _initFormats();
  }

  Future<void> _initFormats() async {
    if (widget.initialFormats != null) {
      _selectedFormats.addAll(widget.initialFormats!);
      if (mounted) {
        setState(() {
          _isLoadingFormats = false;
        });
      }
    } else {
      final savedFormats = await loadExportSelectedFormats();
      if (mounted) {
        setState(() {
          final matching = savedFormats.where((f) => widget.availableFormats.contains(f)).toSet();
          final hasModuleSpecificSavedFormat = matching.any((f) => f != ExportFormat.json);

          if (matching.isEmpty || !hasModuleSpecificSavedFormat) {
            _selectedFormats.addAll(widget.availableFormats);
          } else {
            _selectedFormats.addAll(matching);
          }
          _isLoadingFormats = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _prefixController.dispose();
    super.dispose();
  }

  void _toggleFormat(ExportFormat format, bool selected) {
    setState(() {
      if (selected) {
        _selectedFormats.add(format);
      } else {
        _selectedFormats.remove(format);
      }
    });
    saveExportSelectedFormats(_selectedFormats, contextFormats: widget.availableFormats);
  }

  void _onExportPressed() {
    final prefix = _prefixController.text.trim();
    if (prefix.isEmpty || _selectedFormats.isEmpty) return;

    saveExportSelectedFormats(_selectedFormats, contextFormats: widget.availableFormats);
    Navigator.of(context).pop(
      ExportOptionsResult(
        prefix: prefix,
        formats: Set.from(_selectedFormats),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prefixText = _prefixController.text.trim();
    final isPrefixValid = prefixText.isNotEmpty;
    final isFormatValid = _selectedFormats.isNotEmpty;
    final canExport = isPrefixValid && isFormatValid && !_isLoadingFormats;

    final displayPrefix = isPrefixValid ? prefixText : widget.defaultPrefix;
    final previewExtensions = _selectedFormats.isEmpty
        ? '.[format]'
        : _selectedFormats.map((f) => f.fileExtension).join(', ');

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20.0, 12.0, 20.0, 20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!widget.isDialog)
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12.0),
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          // Title & Subtitle Header
          Row(
            children: [
              // Icon(Icons.share_outlined, color: theme.colorScheme.primary),
              // const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.title ?? S.of(context).exportOptions,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (widget.subtitle != null && widget.subtitle!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              widget.subtitle!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),

          // Section 1: General settings (extensible)
          Text(
            S.of(context).generalSettings,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _prefixController,
            decoration: InputDecoration(
              labelText: S.of(context).fileNamePrefix,
              hintText: widget.defaultPrefix,
              prefixIcon: const Icon(Icons.edit_note_outlined),
              suffixIcon: _prefixController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        setState(() {
                          _prefixController.clear();
                        });
                      },
                    )
                  : null,
              helperText: S.of(context).fileNamePrefixHelper,
              errorText: isPrefixValid ? null : S.of(context).fileNamePrefixRequired,
              border: const OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {});
            },
          ),
          const SizedBox(height: 10),

          // File name preview card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withOpacity(0.6),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.visibility_outlined,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${displayPrefix}_$_sampleTimestamp$previewExtensions',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontFamily: 'monospace',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Section 2: Export formats
          Text(
            S.of(context).exportFormats,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),

          if (_isLoadingFormats)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(12.0),
                child: CircularProgressIndicator(year2023: false),
              ),
            )
          else
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: widget.availableFormats.map((format) {
                final isSelected = _selectedFormats.contains(format);
                return FilterChip(
                  // avatar: Icon(
                  //   format.icon,
                  //   size: 18,
                  //   color: isSelected
                  //       ? theme.colorScheme.onSecondaryContainer
                  //       : theme.colorScheme.onSurfaceVariant,
                  // ),
                  label: Text(format.label),
                  selected: isSelected,
                  onSelected: (selected) {
                    _toggleFormat(format, selected);
                  },
                );
              }).toList(),
            ),

          if (!isFormatValid && !_isLoadingFormats) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.error_outline,
                  size: 16,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    S.of(context).selectAtLeastOneFormat,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],

          // Container for future format-specific and general settings
          // Developers can add format-specific options below when needed.
          const SizedBox(height: 24),

          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(S.of(context).cancel),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                icon: const Icon(Icons.share_outlined, size: 18),
                label: Text(S.of(context).export),
                onPressed: canExport ? _onExportPressed : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
