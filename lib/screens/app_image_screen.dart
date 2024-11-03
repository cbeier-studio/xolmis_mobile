import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import '../data/models/app_image.dart';
import '../providers/app_image_provider.dart';

import 'image_details_screen.dart';

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
        title: const Text('Imagens'),
      ),
      body: Consumer<AppImageProvider>(
        builder: (context, appImageProvider, child) {
          final images = appImageProvider.images;
          if (images.isEmpty) {
            return const Center(
              child: Text('Nenhuma imagem encontrada.'),
            );
          } else {
            return GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
              ),
              itemCount: images.length,
              itemBuilder: (context, index) {
                final image = images[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ImageDetailsScreen(imagePath: image.imagePath),
                      ),
                    );
                  },
                  onLongPress: () => _showBottomSheet(context, image),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.file(
                      File(image.imagePath),
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final cameraStatus = await Permission.camera.request();
          final photosStatus = await Permission.photos.request();

          if (cameraStatus.isGranted && photosStatus.isGranted) {
            showModalBottomSheet(
              context: context,
              builder: (context) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: _notesController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Notas',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16.0),
                        Row(
                          children: [
                            OutlinedButton.icon(
                                onPressed: () => _addImage(ImageSource.gallery),
                                label: const Text('Galeria'),
                                icon: const Icon(Icons.image_search_outlined)
                            ),
                            const SizedBox(width: 8.0),
                            OutlinedButton.icon(
                              onPressed: () => _addImage(ImageSource.camera),
                              label: const Text('Câmera'),
                              icon: const Icon(Icons.camera_alt_outlined),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          } else if (cameraStatus.isDenied || photosStatus.isDenied) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Permissão negada.')),
            );
          } else if (cameraStatus.isPermanentlyDenied || photosStatus.isPermanentlyDenied) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Permissão negada permanentemente.')),
            );
            openAppSettings();
          }
        },
        child: const Icon(Icons.add_outlined),
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
                    title: const Text('Compartilhar imagem'),
                    onTap: () {
                      Share.shareXFiles([XFile(appImage.imagePath)], text: 'Compartilhando imagem');
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete_outlined, color: Colors.red,),
                    title: const Text('Apagar imagem', style: TextStyle(color: Colors.red),),
                    onTap: () {
                      // Ask for user confirmation
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Confirmar exclusão'),
                            content: const Text('Tem certeza que deseja excluir esta imagem?'),
                            actions: <Widget>[
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop(false);
                                  Navigator.of(context).pop();
                                },
                                child: const Text('Cancelar'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop(true);
                                  Navigator.of(context).pop();
                                  // Call the function to delete image
                                  appImageProvider.deleteImage(appImage.id!);
                                },
                                child: const Text('Excluir'),
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
}