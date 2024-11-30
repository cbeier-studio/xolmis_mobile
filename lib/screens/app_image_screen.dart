import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

import '../data/models/app_image.dart';
import '../providers/app_image_provider.dart';

import 'image_details_screen.dart';
import '../generated/l10n.dart';

class AppImageScreen extends StatefulWidget {
  final int? vegetationId;
  final int? eggId;
  final int? specimenId;
  final int? nestRevisionId;

  const AppImageScreen({
    Key? key,
    this.vegetationId,
    this.eggId,
    this.specimenId,
    this.nestRevisionId,
  }) : super(key: key);

  @override
  State<AppImageScreen> createState() => _AppImageScreenState();
}

class _AppImageScreenState extends State<AppImageScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  late AppImageProvider appImageProvider;

  @override
  void initState() {
    super.initState();
    appImageProvider = context.read<AppImageProvider>();
    _loadImages();
  }

  Future<void> _loadImages() async {
    if (widget.vegetationId != null) {
      await appImageProvider.fetchImagesForVegetation(widget.vegetationId!);
    } else if (widget.eggId != null) {
      await appImageProvider.fetchImagesForEgg(widget.eggId!);
    } else if (widget.specimenId != null) {
      await appImageProvider.fetchImagesForSpecimen(widget.specimenId!);
    } else if (widget.nestRevisionId != null) {
      await appImageProvider.fetchImagesForNestRevision(widget.nestRevisionId!);
    }
  }

  Future<void> _addImage(ImageSource source) async {
    final imagePicker = ImagePicker();
    final pickedFile = await imagePicker.pickImage(source: source);

    if (pickedFile != null) {
      final appImage = AppImage(
        imagePath: pickedFile.path,
        notes: _notesController.text,
      );

      final appImageProvider = Provider.of<AppImageProvider>(context, listen: false);
      if (widget.vegetationId != null) {
        await appImageProvider.addImageToVegetation(appImage, widget.vegetationId!);
      } else if (widget.eggId != null) {
        await appImageProvider.addImageToEgg(appImage, widget.eggId!);
      } else if (widget.specimenId != null) {
        await appImageProvider.addImageToSpecimen(appImage, widget.specimenId!);
      } else if (widget.nestRevisionId != null) {
        await appImageProvider.addImageToNestRevision(appImage, widget.nestRevisionId!);
      }

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).images(2)),
      ),
      body: Consumer<AppImageProvider>(
          builder: (context, appImageProvider, child) {
            final images = appImageProvider.images;
            if (images.isEmpty) {
              return Center(
                child: Text(S.of(context).noImagesFound),
              );
            } else {
              return LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final screenWidth = constraints.maxWidth;
                  final isLargeScreen = screenWidth > 600;

                  if (isLargeScreen) {
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
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final cameraStatus = await Permission.camera.request();
          late PermissionStatus photosStatus = PermissionStatus.denied;

          if (Platform.isAndroid) {
            final androidInfo = await DeviceInfoPlugin().androidInfo;
            if (androidInfo.version.sdkInt <= 32) {
              photosStatus = await Permission.storage.request();
            }  else {
              photosStatus = await Permission.photos.request();
            }
          }

          if (cameraStatus.isGranted && photosStatus.isGranted) {
            showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: Text(S.of(context).addImage),
                  content: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextFormField(
                            controller: _notesController,
                            maxLines: 3,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration(
                              labelText: S.of(context).notes,
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16.0),
                          Row(
                            children: [
                              OutlinedButton.icon(
                                onPressed: () => _addImage(ImageSource.gallery),
                                label: Text(S.of(context).gallery),
                                icon: const Icon(Icons.image_search_outlined),
                              ),
                              const SizedBox(width: 8.0),
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
                      },
                    ),
                  ],
                );
              },
            );
          } else if (cameraStatus.isDenied || photosStatus.isDenied) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(S.current.permissionDenied)),
            );
          } else if (cameraStatus.isPermanentlyDenied || photosStatus.isPermanentlyDenied) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(S.current.permissionDeniedPermanently)),
            );
            openAppSettings();
          }
        },
        child: const Icon(Icons.add_a_photo_outlined),
      ),
    );
  }

  void _showBottomSheet(BuildContext context, AppImage appImage) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return BottomSheet(
          onClosing: () {},
          builder: (BuildContext context) {
            return Container(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  ListTile(
                    leading: const Icon(Icons.share_outlined),
                    title: Text(S.of(context).shareImage),
                    onTap: () {
                      Share.shareXFiles([XFile(appImage.imagePath)], text: 'Compartilhando imagem');
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.edit_outlined),
                    title: Text(S.of(context).editImageNotes),
                    onTap: () {
                      Navigator.pop(context);
                      _showEditNotesDialog(context, appImage);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete_outlined, color: Colors.red,),
                    title: Text(S.of(context).deleteImage, style: TextStyle(color: Colors.red),),
                    onTap: () {
                      // Ask for user confirmation
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text(S.of(context).confirmDelete),
                            content: Text(S.of(context).confirmDeleteMessage(1, "female", S.of(context).images(1).toLowerCase())),
                            actions: <Widget>[
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop(false);
                                  Navigator.of(context).pop();
                                },
                                child: Text(S.of(context).cancel),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop(true);
                                  Navigator.of(context).pop();
                                  // Call the function to delete image
                                  appImageProvider.deleteImage(appImage.id!);
                                },
                                child: Text(S.of(context).delete),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  )
                  // )
                ],
              ),
            );
          },
        );
      },
    );
  }

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
                Navigator.of(context).pop();
                setState(() {});
              },
            ),
          ],
        );
      },
    );
  }

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
              title: Text(image.notes ?? '', overflow: TextOverflow.ellipsis,),
            ),
            child: ClipRRect(
              // borderRadius: BorderRadius.circular(0.0),
              child: Image.file(
                File(image.imagePath),
                fit: BoxFit.cover,
              ),
            ),
          ),
        );
      },
    );
  }
}

