import 'package:flutter/material.dart';

import '../generated/l10n.dart';

/// Encapsulates the result returned by the filter selection bottom sheet.
class FilterSelectionResult<T> {
  final T? selectedItem;
  final bool cleared;

  /// Creates a result that contains a selected item.
  const FilterSelectionResult.selected(this.selectedItem) : cleared = false;

  /// Creates a result that indicates the selection was cleared.
  const FilterSelectionResult.cleared() : selectedItem = null, cleared = true;
}

/// Shows a searchable bottom sheet for choosing one item from [items].
///
/// The returned [FilterSelectionResult] either contains the selected item or
/// indicates that the current selection should be cleared.
Future<FilterSelectionResult<T>?> showFilterSelectionBottomSheet<T>({
  required BuildContext context,
  required String title,
  required List<T> items,
  required String Function(T item) itemLabel,
  bool Function(T item, String query, String label)? matchesQuery,
  String? clearActionLabel,
  String? emptyStateLabel,
  bool showSearch = true,
  bool showClearAction = true,
}) {
  return showModalBottomSheet<FilterSelectionResult<T>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) {
      return _FilterSelectionBottomSheetContent<T>(
        title: title,
        items: items,
        itemLabel: itemLabel,
        matchesQuery: matchesQuery,
        showSearch: showSearch,
        showClearAction: showClearAction,
        clearActionLabel: clearActionLabel,
        emptyStateLabel: emptyStateLabel,
      );
    },
  );
}

/// Internal content widget used by [showFilterSelectionBottomSheet].
class _FilterSelectionBottomSheetContent<T> extends StatefulWidget {
  final String title;
  final List<T> items;
  final String Function(T item) itemLabel;
  final bool Function(T item, String query, String label)? matchesQuery;
  final bool showSearch;
  final bool showClearAction;
  final String? clearActionLabel;
  final String? emptyStateLabel;

  const _FilterSelectionBottomSheetContent({
    required this.title,
    required this.items,
    required this.itemLabel,
    this.matchesQuery,
    required this.showSearch,
    required this.showClearAction,
    this.clearActionLabel,
    this.emptyStateLabel,
  });

  @override
  State<_FilterSelectionBottomSheetContent<T>> createState() =>
      _FilterSelectionBottomSheetContentState<T>();
}

class _FilterSelectionBottomSheetContentState<T>
    extends State<_FilterSelectionBottomSheetContent<T>> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchQuery.trim().toLowerCase();
    final filteredItems =
        widget.showSearch && query.isNotEmpty
            ? widget.items.where((item) {
              final label = widget.itemLabel(item);
              if (widget.matchesQuery != null) {
                return widget.matchesQuery!(item, query, label);
              }
              return label.toLowerCase().contains(query);
            }).toList()
            : widget.items;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  if (widget.showClearAction)
                    TextButton(
                      onPressed: () {
                        Navigator.of(
                          context,
                        ).pop(FilterSelectionResult<T>.cleared());
                      },
                      child: Text(widget.clearActionLabel ?? S.current.clearSearch),
                    ),
                ],
              ),
              if (widget.showSearch) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search_outlined),
                    hintText:
                        MaterialLocalizations.of(context).searchFieldLabel,
                    isDense: true,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Expanded(
                child:
                    filteredItems.isEmpty
                        ? Center(
                          child: Text(
                            widget.emptyStateLabel ?? S.current.noResults,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        )
                        : ListView.builder(
                          controller: scrollController,
                          itemCount: filteredItems.length,
                          itemBuilder: (context, index) {
                            final item = filteredItems[index];
                            return ListTile(
                              dense: true,
                              title: Text(widget.itemLabel(item)),
                              onTap: () {
                                Navigator.of(
                                  context,
                                ).pop(FilterSelectionResult<T>.selected(item));
                              },
                            );
                          },
                        ),
              ),
            ],
          ),
        );
      },
    );
  }
}
