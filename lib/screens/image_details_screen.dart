import 'dart:io';

import 'package:flutter/material.dart';

class ImageDetailsScreen extends StatelessWidget {
  final String imagePath;

  const ImageDetailsScreen({Key? key, required this.imagePath}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes da Imagem'),
      ),
      body: InteractiveViewer(
        minScale: 0.5,
        maxScale: 5.0,
        child: Center(
          child:  Image.file(File(imagePath)),
        ),
      ),
    );
  }
}