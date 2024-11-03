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
      body: Center(
        child: Image.file(File(imagePath)),
      ),
    );
  }
}