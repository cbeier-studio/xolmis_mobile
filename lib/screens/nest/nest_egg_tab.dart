import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data/models/nest.dart';
import '../../data/models/app_image.dart';
import '../../providers/egg_provider.dart';
import '../../providers/app_image_provider.dart';

import '../images/app_image_screen.dart';
import '../../utils/utils.dart';
import '../../generated/l10n.dart';

import 'add_egg_screen.dart';

/// Tab that lists eggs associated with a nest.
class EggsTab extends StatefulWidget {
  final Nest nest;

  const EggsTab({super.key, required this.nest});

  @override
  State<EggsTab> createState() => _EggsTabState();
}

/// Handles egg list interactions and CRUD actions.
class _EggsTabState extends State<EggsTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return _buildEggList();
  }

  /// Deletes an egg after confirmation.
  Future<void> _deleteEgg(Egg egg) async {
    final confirmed = await _showDeleteConfirmationDialog(context);
    if (confirmed) {
      Provider.of<EggProvider>(
        context,
        listen: false,
      ).removeEgg(widget.nest.id!, egg.id!);
    }
  }

  Future<bool> _showDeleteConfirmationDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(S.of(context).confirmDelete),
              content: Text(
                S.of(context).confirmDeleteMessage(1, "male", S.of(context).egg(1)),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(S.of(context).cancel),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(
                      S.of(context).delete,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  /// Opens the add-egg form with the next generated field suffix.
  Future<void> _showAddEggScreen(BuildContext context) async {
    final eggProvider = Provider.of<EggProvider>(context, listen: false);
    int nextNumber = await eggProvider.getNextSequentialNumber(widget.nest.fieldNumber!);
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
                child: AddEggScreen(
                  nest: widget.nest,
                  initialFieldNumber: '${widget.nest.fieldNumber}-${nextNumber.toString().padLeft(2, '0')}',
                  initialSpeciesName: widget.nest.speciesName,)
            ),
          );
        },
      ).then((newEgg) {
        // Reload the egg list
        if (newEgg != null) {
          eggProvider.getEggForNest(widget.nest.id!);
        }
      });
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AddEggScreen(
          nest: widget.nest,
          initialFieldNumber: '${widget.nest.fieldNumber}-${nextNumber.toString().padLeft(2, '0')}',
          initialSpeciesName: widget.nest.speciesName,)
        ),
      ).then((newEgg) {
        // Reload the egg list
        if (newEgg != null) {
          eggProvider.getEggForNest(widget.nest.id!);
        }
      });
    }
  }

  Widget _buildEggList() {
    return Column(
      children: [
        Expanded(
          child: Consumer<EggProvider>(
            builder: (context, eggProvider, child) {
              final eggList = eggProvider.getEggForNest(widget.nest.id!);
              if (eggList.isEmpty) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(8.0, 16.0, 8.0, 16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.egg_outlined,
                          size: 48,
                          color: Theme.of(context).colorScheme.surfaceDim,
                        ),
                        const SizedBox(height: 8),
                        Text(S.of(context).noEggsFound),
                        const SizedBox(height: 8),
                        ActionChip(
                          label: Text(S.of(context).newEgg),
                          avatar: const Icon(Icons.add_outlined),
                          onPressed: () {
                            _showAddEggScreen(context);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              } else {
                return RefreshIndicator(
                  onRefresh: () async {
                    await eggProvider.loadEggForNest(widget.nest.id ?? 0);
                  },
                  child: _buildListView(eggList),
                );
              }
            },
          ),
        ),
      ],
    );
  }

  void _showBottomSheet(BuildContext context, Egg egg) {
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
                    child: Text(egg.fieldNumber!, style: TextTheme.of(innerContext).bodyLarge,),
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
                        _showEditEggScreen(context, egg);
                      }),
                      buildGridMenuItem(innerContext, Icons.delete_outlined,
                          S.of(innerContext).delete, () async {
                            Navigator.of(innerContext).pop();
                            await _deleteEgg(egg);
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

  void _showEditEggScreen(BuildContext context, Egg egg) {
    final eggProvider = Provider.of<EggProvider>(context, listen: false);
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
              child: AddEggScreen(
                nest: widget.nest,
                egg: egg,
                isEditing: true,
              ),
            ),
          );
        },
      ).then((result) {
        if (result != null) {
          eggProvider.getEggForNest(widget.nest.id!);
        }
      });
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddEggScreen(
            nest: widget.nest,
            egg: egg,
            isEditing: true,
          ),
        ),
      ).then((result) {
        if (result != null) {
          eggProvider.getEggForNest(widget.nest.id!);
        }
      });
    }
  }

  Widget _buildListView(List<Egg> eggList) {
    return ListView.separated(
      separatorBuilder: (context, index) => Divider(),
      shrinkWrap: true,
      itemCount: eggList.length,
      itemBuilder: (context, index) {
        final egg = eggList[index];
        return EggListItem(
          egg: egg,
          onLongPress: () => _showBottomSheet(context, egg),
        );
      },
    );
  }
}

/// Grid card representation of an egg record.
class EggGridItem extends StatelessWidget {
  const EggGridItem({super.key, required this.egg});

  final Egg egg;

  @override
  Widget build(BuildContext context) {
    return Card.filled(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(0.0, 16.0, 16.0, 16.0),
              child: EggThumbnail(eggId: egg.id ?? 0),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  egg.fieldNumber!,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  egg.speciesName!,
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
                Text(DateFormat('dd/MM/yyyy HH:mm').format(egg.sampleTime!)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// List tile representation of an egg record.
class EggListItem extends StatelessWidget {
  final Egg egg;
  final VoidCallback onLongPress;

  const EggListItem({super.key, required this.egg, required this.onLongPress});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: EggThumbnail(eggId: egg.id ?? 0),
      title: Text('${egg.fieldNumber}'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            egg.speciesName!,
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color:
                  allSpeciesNames.contains(egg.speciesName) ? null : Colors.red,
            ),
          ),
          Text(
            DateFormat('dd/MM/yyyy HH:mm').format(egg.sampleTime!),
          ),
        ],
      ),
      onLongPress: onLongPress,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AppImageScreen(eggId: egg.id)),
        );
      },
    );
  }
}

/// A widget that displays a thumbnail for an egg, handling loading,
/// error, and empty states reactively.
class EggThumbnail extends StatefulWidget {
  final int eggId;

  const EggThumbnail({super.key, required this.eggId});

  @override
  State<EggThumbnail> createState() => _EggThumbnailState();
}

class _EggThumbnailState extends State<EggThumbnail> {
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
  void didUpdateWidget(EggThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.eggId != widget.eggId) {
      _fetchImages();
    }
  }

  Future<void> _fetchImages() async {
    try {
      final provider = Provider.of<AppImageProvider>(context, listen: false);
      final images = await provider.fetchImagesForEgg(widget.eggId, notify: false);
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
