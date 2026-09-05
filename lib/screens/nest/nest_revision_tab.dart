import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data/models/nest.dart';
import '../../data/models/app_image.dart';
import '../../providers/nest_revision_provider.dart';
import '../../providers/app_image_provider.dart';

import '../images/app_image_screen.dart';
import '../../core/core_consts.dart';
import '../../utils/utils.dart';
import '../../generated/l10n.dart';

import 'add_revision_screen.dart';

/// Tab that lists revision visits for a nest.
class NestRevisionsTab extends StatefulWidget {
  final Nest nest;

  const NestRevisionsTab({super.key, required this.nest});

  @override
  State<NestRevisionsTab> createState() => _NestRevisionsTabState();
}

/// Handles revision list interactions and CRUD flows.
class _NestRevisionsTabState extends State<NestRevisionsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return _buildNestRevisionList();
  }

  /// Deletes a revision after confirmation.
  Future<void> _deleteNestRevision(NestRevision revision) async {
    final confirmed = await _showDeleteConfirmationDialog(context);
    if (confirmed) {
      Provider.of<NestRevisionProvider>(
        context,
        listen: false,
      ).removeNestRevision(context, widget.nest.id!, revision.id!);
    }
  }

  Future<bool> _showDeleteConfirmationDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(S.of(context).confirmDelete),
              content: Text(
                S.of(context).confirmDeleteMessage(
                      1,
                      "female",
                      S.of(context).revision(1).toLowerCase(),
                    ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(S.of(context).cancel),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(S.of(context).delete),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  /// Opens the add-revision form and refreshes list on success.
  void _showAddRevisionScreen(BuildContext context) {
    final revisionProvider = Provider.of<NestRevisionProvider>(context, listen: false);
    if (MediaQuery.sizeOf(context).width > 600) {
      showDialog(
        context: context,
        builder: (context) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: AddNestRevisionScreen(nest: widget.nest),
            ),
          );
        },
      ).then((newRevision) {
        // Reload the nest revision list
        if (newRevision != null) {
          revisionProvider.getRevisionForNest(widget.nest.id!);
        }
      });
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AddNestRevisionScreen(nest: widget.nest),
        ),
      ).then((newRevision) {
        // Reload the nest revision list
        if (newRevision != null) {
          revisionProvider.getRevisionForNest(widget.nest.id!);
        }
      });
    }
  }

  Widget _buildNestRevisionList() {
    return Column(
      children: [
        Expanded(
          child: Consumer<NestRevisionProvider>(
            builder: (context, nestRevisionProvider, child) {
              final revisionList = nestRevisionProvider.getRevisionForNest(
                widget.nest.id!,
              );

              if (revisionList.isEmpty) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(8.0, 16.0, 8.0, 16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.beenhere_outlined,
                          size: 48,
                          color: Theme.of(context).colorScheme.surfaceDim,
                        ),
                        const SizedBox(height: 8),
                        Text(S.of(context).noRevisionsFound),
                        const SizedBox(height: 8),
                        ActionChip(
                          label: Text(S.of(context).newRevision),
                          avatar: const Icon(Icons.add_outlined),
                          onPressed: () {
                            _showAddRevisionScreen(context);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              } else {
                return RefreshIndicator(
                  onRefresh: () async {
                    await nestRevisionProvider.loadRevisionForNest(
                      widget.nest.id ?? 0,
                    );
                  },
                  child: _buildListView(revisionList),
                );
              }
            },
          ),
        ),
      ],
    );
  }

  void _showBottomSheet(BuildContext context, NestRevision revision) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bottomSheetContext) {
        return SafeArea(
          child: BottomSheet(
          onClosing: () {},
          builder: (BuildContext innerContext) {
            return Container(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      DateFormat('dd/MM/yyyy HH:mm',).format(revision.sampleTime!),
                      style: TextTheme.of(innerContext).bodyLarge,
                    ),
                  ),
                  const Divider(),
                  GridView.count(
                    crossAxisCount: MediaQuery.sizeOf(innerContext).width < 600 ? 4 : 5,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: <Widget>[
                      buildGridMenuItem(
                          innerContext, Icons.edit_outlined, S.current.edit, () {
                        Navigator.of(innerContext).pop();
                        _showEditRevisionScreen(context, revision);
                      }),
                      buildGridMenuItem(innerContext, Icons.delete_outlined,
                          S.of(innerContext).delete, () async {
                            Navigator.of(innerContext).pop();
                            await _deleteNestRevision(revision);
                          }, color: Theme.of(innerContext).colorScheme.error),
                    ],
                  ),
                ],
              ),
              ),
            );
          },
          ),
        );
      },
    );
  }

  void _showEditRevisionScreen(BuildContext context, NestRevision revision) {
    final revisionProvider = Provider.of<NestRevisionProvider>(context, listen: false);
    if (MediaQuery.sizeOf(context).width > 600) {
      showDialog(
        context: context,
        builder: (context) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: AddNestRevisionScreen(
                nest: widget.nest,
                nestRevision: revision,
                isEditing: true,
              ),
            ),
          );
        },
      ).then((result) {
        if (result != null) {
          revisionProvider.getRevisionForNest(widget.nest.id!);
        }
      });
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddNestRevisionScreen(
            nest: widget.nest,
            nestRevision: revision,
            isEditing: true,
          ),
        ),
      ).then((result) {
        if (result != null) {
          revisionProvider.getRevisionForNest(widget.nest.id!);
        }
      });
    }
  }

  Widget _buildListView(List<NestRevision> revisionList) {
    return ListView.separated(
      separatorBuilder: (context, index) => Divider(),
      shrinkWrap: true,
      itemCount: revisionList.length,
      itemBuilder: (context, index) {
        final nestRevision = revisionList[index];
        return RevisionListItem(
          nestRevision: nestRevision,
          onLongPress: () => _showBottomSheet(context, nestRevision),
        );
      },
    );
  }
}

/// Grid card representation of a nest revision.
class NestRevisionGridItem extends StatelessWidget {
  const NestRevisionGridItem({super.key, required this.revision});

  final NestRevision revision;

  @override
  Widget build(BuildContext context) {
    return Card.filled(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(0.0, 16.0, 16.0, 16.0),
              child: NestRevisionThumbnail(revisionId: revision.id ?? 0),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat(
                    'dd/MM/yyyy HH:mm',
                  ).format(revision.sampleTime!),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${nestStatusTypeFriendlyNames[revision.nestStatus]}: ${nestStageTypeFriendlyNames[revision.nestStage]}',
                ),
                Text(
                  '${S.of(context).host}: ${revision.eggsHost ?? 0} ${S.of(context).egg(revision.eggsHost ?? 0)}, ${revision.nestlingsHost ?? 0} ${S.of(context).nestling(revision.nestlingsHost ?? 0).toLowerCase()}',
                ),
                Text(
                  '${S.of(context).nidoparasite}: ${revision.eggsParasite ?? 0} ${S.of(context).egg(revision.eggsParasite ?? 0)}, ${revision.nestlingsParasite ?? 0} ${S.of(context).nestling(revision.nestlingsParasite ?? 0).toLowerCase()}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// List tile representation of a nest revision.
class RevisionListItem extends StatelessWidget {
  final NestRevision nestRevision;
  final VoidCallback onLongPress;

  const RevisionListItem({
    super.key,
    required this.nestRevision,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: NestRevisionThumbnail(revisionId: nestRevision.id ?? 0),
      title: Text(
        DateFormat(
          'dd/MM/yyyy HH:mm',
        ).format(nestRevision.sampleTime!),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${nestStatusTypeFriendlyNames[nestRevision.nestStatus]}: ${nestStageTypeFriendlyNames[nestRevision.nestStage]}',
            style: TextStyle(
              color:
                  nestRevision.nestStatus == NestStatusType.nstActive
                      ? Colors.blue
                      : nestRevision.nestStatus ==
                              NestStatusType.nstInactive
                          ? Colors.red
                          : null,
            ),
          ),
          Text(
            '${S.of(context).host}: ${nestRevision.eggsHost ?? 0} ${S.of(context).egg(nestRevision.eggsHost ?? 0).toLowerCase()}, ${nestRevision.nestlingsHost ?? 0} ${S.of(context).nestling(nestRevision.nestlingsHost ?? 0).toLowerCase()}',
          ),
          Text(
            '${S.of(context).nidoparasite}: ${nestRevision.eggsParasite ?? 0} ${S.of(context).egg(nestRevision.eggsParasite ?? 0).toLowerCase()}, ${nestRevision.nestlingsParasite ?? 0} ${S.of(context).nestling(nestRevision.nestlingsParasite ?? 0).toLowerCase()}',
          ),
        ],
      ),
      onLongPress: onLongPress,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) =>
                    AppImageScreen(nestRevisionId: nestRevision.id),
          ),
        );
      },
    );
  }
}

/// A widget that displays a thumbnail for a nest revision, handling loading,
/// error, and empty states reactively.
class NestRevisionThumbnail extends StatefulWidget {
  final int revisionId;

  const NestRevisionThumbnail({super.key, required this.revisionId});

  @override
  State<NestRevisionThumbnail> createState() => _NestRevisionThumbnailState();
}

class _NestRevisionThumbnailState extends State<NestRevisionThumbnail> {
  List<AppImage>? _images;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    Provider.of<AppImageProvider>(context);
    _fetchImages();
  }

  @override
  void didUpdateWidget(NestRevisionThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.revisionId != widget.revisionId) {
      _fetchImages();
    }
  }

  Future<void> _fetchImages() async {
    try {
      final provider = Provider.of<AppImageProvider>(context, listen: false);
      final images = await provider.fetchImagesForNestRevision(widget.revisionId, notify: false);
      if (mounted) {
        setState(() {
          _images = images;
          _isLoading = false;
          _hasError = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && (_images == null || _images!.isEmpty)) {
      return const SizedBox(
        width: 50,
        height: 50,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, year2023: false),
          ),
        ),
      );
    }

    if (_hasError) {
      return _buildPlaceholder(context, Icons.error_outline, isError: true);
    }

    if (_images != null && _images!.isNotEmpty) {
      final imagePath = _images!.first.imagePath;
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.file(
          File(imagePath),
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _buildPlaceholder(context, Icons.error, isError: true),
        ),
      );
    }

    return _buildPlaceholder(context, Icons.image_not_supported_outlined);
  }

  Widget _buildPlaceholder(BuildContext context, IconData icon, {bool isError = false}) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(
        icon,
        color: isError ? Theme.of(context).colorScheme.error : Colors.grey.shade500,
        size: 24,
      ),
    );
  }
}
