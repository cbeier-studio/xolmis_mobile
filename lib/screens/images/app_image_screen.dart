import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

import '../../data/models/app_image.dart';
import '../../providers/app_image_provider.dart';

import 'image_details_screen.dart';
import '../../utils/utils.dart';
import '../../generated/l10n.dart';

enum ImageParentType { vegetation, egg, specimen, nestRevision }

class AppImageScreen extends StatefulWidget {
  final int? vegetationId;
  final int? eggId;
  final int? specimenId;
  final int? nestRevisionId;
  final bool isEmbedded;

  const AppImageScreen({
    super.key,
    this.vegetationId,
    this.eggId,
    this.specimenId,
    this.nestRevisionId,
    this.isEmbedded = false,
  });

  @override
  State<AppImageScreen> createState() => _AppImageScreenState();
}

class _AppImageScreenState extends State<AppImageScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  late AppImageProvider appImageProvider;
  int? _activeParentId;
  ImageParentType? _activeParentType;

  @override
  void initState() {
    super.initState();
    appImageProvider = context.read<AppImageProvider>();
    _determineActiveParent();
    _loadImages();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _determineActiveParent() {
    if (widget.vegetationId != null) {
      _activeParentId = widget.vegetationId;
      _activeParentType = ImageParentType.vegetation;
    } else if (widget.eggId != null) {
      _activeParentId = widget.eggId;
      _activeParentType = ImageParentType.egg;
    } else if (widget.specimenId != null) {
      _activeParentId = widget.specimenId;
      _activeParentType = ImageParentType.specimen;
    } else if (widget.nestRevisionId != null) {
      _activeParentId = widget.nestRevisionId;
      _activeParentType = ImageParentType.nestRevision;
    } else {
      debugPrint("AppImageScreen initialized without a parent ID.");
    }
  }

  // Load images from the database
  Future<void> _loadImages() async {
    if (_activeParentId == null || _activeParentType == null) return;

    switch (_activeParentType!) {
      case ImageParentType.vegetation:
        await appImageProvider.fetchImagesForVegetation(_activeParentId!);
        break;
      case ImageParentType.egg:
        await appImageProvider.fetchImagesForEgg(_activeParentId!);
        break;
      case ImageParentType.specimen:
        await appImageProvider.fetchImagesForSpecimen(_activeParentId!);
        break;
      case ImageParentType.nestRevision:
        await appImageProvider.fetchImagesForNestRevision(_activeParentId!);
        break;
    }
  }

  // Add an image to the database
  Future<void> _addImage(ImageSource source) async {
    final imagePicker = ImagePicker();
    // Get the image from camera or gallery
    final pickedFile = await imagePicker.pickImage(source: source);

    if (pickedFile != null) {
      // Save the image to the app's documents directory
      final directory = await getApplicationDocumentsDirectory();
      // Generate a unique filename
      final String originalFileName = path.basename(pickedFile.path);
      final String extension = path.extension(originalFileName);
      final String newFileNameBase = DateTime.now().millisecondsSinceEpoch.toString();
      final String newFileName = '$newFileNameBase$extension';
      final String newPath = path.join(directory.path, newFileName);

      final savedImage = await File(pickedFile.path).copy(newPath);

      // Create an AppImage object and save it to the database
      final appImage = AppImage(
        imagePath: savedImage.path,
        notes: _notesController.text,
      );

      // final appImageProvider = Provider.of<AppImageProvider>(context, listen: false);
      if (widget.vegetationId != null) {
        await appImageProvider.addImageToVegetation(appImage, widget.vegetationId!);
      } else if (widget.eggId != null) {
        await appImageProvider.addImageToEgg(appImage, widget.eggId!);
      } else if (widget.specimenId != null) {
        await appImageProvider.addImageToSpecimen(appImage, widget.specimenId!);
      } else if (widget.nestRevisionId != null) {
        await appImageProvider.addImageToNestRevision(appImage, widget.nestRevisionId!);
      }

      if (!mounted) return;
      Navigator.pop(context); // Close the dialog
      _notesController.clear(); // Clear notes after successful add
    }
  }

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
                child: Text(S.of(context).images(2),
                    style: Theme.of(context).textTheme.titleLarge),
              ),
              IconButton(
                onPressed: () async {
                  // Request permission to access the camera and photos
          final permissionsGranted = await _requestPermissions();
          if (!mounted) return;

          if (permissionsGranted) {
            _notesController.clear(); // Clear notes before showing dialog
            _showAddImageDialog();
          }
                }, 
                icon: Icon(Theme.of(context).brightness == Brightness.light ? Icons.add_a_photo_outlined : Icons.add_a_photo),
              ),
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
              child: Consumer<AppImageProvider>(
          builder: (context, appImageProvider, child) {
            final images = appImageProvider.images;
            if (images.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image_outlined,
                      size: 48,
                      color: Theme.of(context).colorScheme.surfaceDim,
                    ),
                    const SizedBox(height: 8),
                    Text(S.of(context).noImagesFound),
                  ],
                ),
              );
            } else {
              return LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final screenWidth = constraints.maxWidth;
                  final isLargeScreen = screenWidth > 600;

                  if (isLargeScreen) {
                    // If the screen is large, show a constrained box
                    return Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 840),
                        child: SingleChildScrollView(
                          child: _buildGridView(images),
                        ),
                      ),
                    );
                  } else {
                    return _buildGridView(images);
                  }
                },
              );
            }
          }
        ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).images(2)),
      ),
      body: SafeArea(
        child: Consumer<AppImageProvider>(
          builder: (context, appImageProvider, child) {
            final images = appImageProvider.images;
            if (images.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image_outlined,
                      size: 48,
                      color: Theme.of(context).colorScheme.surfaceDim,
                    ),
                    const SizedBox(height: 8),
                    Text(S.of(context).noImagesFound),
                    const SizedBox(height: 8),
                    ActionChip(
                      label: Text(S.of(context).addImage),
                      avatar: const Icon(Icons.add_outlined),
                      onPressed: () {
                        _showAddImageDialog();
                      },
                    ),
                  ],
                ),
              );
            } else {
              return LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final screenWidth = constraints.maxWidth;
                  final isLargeScreen = screenWidth > 600;

                  if (isLargeScreen) {
                    // If the screen is large, show a constrained box
                    return Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 840),
                        child: SingleChildScrollView(
                          child: _buildGridView(images),
                        ),
                      ),
                    );
                  } else {
                    return _buildGridView(images);
                  }
                },
              );
            }
          }
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Request permission to access the camera and photos
          final permissionsGranted = await _requestPermissions();
          if (!mounted) return;

          if (permissionsGranted) {
            _notesController.clear(); // Clear notes before showing dialog
            _showAddImageDialog();
          }
        },
        child: const Icon(Icons.add_a_photo_outlined),
      ),
    );
  }

  Future<bool> _requestPermissions() async {
    final cameraStatus = await Permission.camera.request();
    PermissionStatus photosStatus;

    if (!mounted) return false;

    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (!mounted) return false;
      if (androidInfo.version.sdkInt <= 32) { // Target Android 12 and lower
        photosStatus = await Permission.storage.request();
      } else { // Target Android 13 and higher
        photosStatus = await Permission.photos.request();
      }
    } else { // For iOS and other platforms
      photosStatus = await Permission.photos.request();
    }

    if (!mounted) return false;

    if (cameraStatus.isGranted && photosStatus.isGranted) {
      return true;
    } else {
      if (cameraStatus.isPermanentlyDenied || photosStatus.isPermanentlyDenied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Theme.of(context).colorScheme.error,
              content: Text(S.current.permissionDeniedPermanently)
          ),
        );
        openAppSettings();
      } else if (cameraStatus.isDenied || photosStatus.isDenied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Theme.of(context).colorScheme.error,
              content: Text(S.current.permissionDenied)
          ),
        );
      }
      return false;
    }
  }

  void _showAddImageDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(S.of(context).addImage),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey, // _formKey can be used if validation is needed
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _notesController,
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: S.of(context).notes,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _addImage(ImageSource.gallery),
                        label: Text(S.of(context).gallery),
                        icon: const Icon(Icons.image_search_outlined),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _addImage(ImageSource.camera),
                        label: Text(S.of(context).camera),
                        icon: const Icon(Icons.camera_alt_outlined),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(S.of(context).cancel),
              onPressed: () {
                Navigator.of(context).pop();
                _notesController.clear(); // Clear on cancel
              },
            ),
          ],
        );
      },
    );
  }

  void _showBottomSheet(BuildContext context, AppImage appImage) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: BottomSheet(
          onClosing: () {},
          builder: (BuildContext context) {
            return Container(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  GridView.count(
                    crossAxisCount: 4,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: <Widget>[
                      buildGridMenuItem(
                          context, Icons.edit_outlined, S.current.edit, () {
                        Navigator.of(context).pop();
                        _showEditNotesDialog(context, appImage);
                      }),
                      buildGridMenuItem(
                          context, Icons.share_outlined, S.current.export, () {
                        Navigator.of(context).pop();
                        SharePlus.instance.share(
                          ShareParams(files: [XFile(appImage.imagePath)], text: 'Compartilhando imagem'),
                        );
                      }),
                      buildGridMenuItem(context, Icons.delete_outlined,
                          S.of(context).delete, () async {
                            Navigator.of(context).pop();
                            // Ask for user confirmation
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog.adaptive(
                                  title: Text(S.of(context).confirmDelete),
                                  content: Text(S.of(context).confirmDeleteMessage(1, "female", S.of(context).images(1).toLowerCase())),
                                  actions: <Widget>[
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop(false);
                                        // Navigator.of(context).pop();
                                      },
                                      child: Text(S.of(context).cancel),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop(true);
                                        // Navigator.of(context).pop();
                                        // Call the function to delete image
                                        if (appImage.id != null) appImageProvider.deleteImage(appImage.id!);
                                      },
                                      child: Text(S.of(context).delete),
                                    ),
                                  ],
                                );
                              },
                            );
                          }, color: Theme.of(context).colorScheme.error),
                    ],
                  ),
                ],
              ),
            );
          },
          ),
        );
      },
    );
  }

  // Show a dialog to edit the notes of an image
  void _showEditNotesDialog(BuildContext context, AppImage appImage) {
    final notesController = TextEditingController(text: appImage.notes);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(S.of(context).editNotes),
          content: TextField(
            controller: notesController,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: S.of(context).notes,
              border: OutlineInputBorder(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(S.of(context).cancel),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text(S.of(context).save),
              onPressed: () async {
                appImage.notes = notesController.text;
                final updatedImage = AppImage(
                  id: appImage.id,
                  imagePath: appImage.imagePath,
                  notes: notesController.text,
                  vegetationId: appImage.vegetationId,
                  specimenId: appImage.specimenId,
                  nestRevisionId: appImage.nestRevisionId,
                  eggId: appImage.eggId,
                );
                await appImageProvider.updateImage(updatedImage);
                if (!mounted) return;
                Navigator.of(context).pop();
                // setState(() {});
              },
            ),
          ],
        );
      },
    );
  }

  // Build a GridView with the images
  Widget _buildGridView(List<AppImage> images) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 250,
        mainAxisSpacing: 8.0,
        crossAxisSpacing: 8.0,
      ),
      padding: const EdgeInsets.all(8.0),
      shrinkWrap: true,
      itemCount: images.length,
      itemBuilder: (context, index) {
        final image = images[index];
        return GestureDetector(
          onLongPress: () => _showBottomSheet(context, image),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ImageDetailsScreen(imagePath: image.imagePath),
              ),
            );
          },
          child: GridTile(
            footer: GridTileBar(
              backgroundColor: Colors.black45,
              title: Text(
                image.notes ?? '',
                overflow: TextOverflow.ellipsis,
              ),
              trailing: IconButton(
                      icon: Icon(Icons.edit_outlined),
                      onPressed: () {
                        _showEditNotesDialog(context, image);
                      }),
            ),
            child: 
                ClipRRect(
                  clipBehavior: Clip.hardEdge,
                  // borderRadius: BorderRadius.circular(0.0),
                  child: image.imagePath.isNotEmpty ? Image.file(
                    File(image.imagePath),
                    fit: BoxFit.cover,
                  ) : const Center(
                    child: Text('No Image'),
                  ),
                ),
          ),
            
        );
      },
    );
  }
}

