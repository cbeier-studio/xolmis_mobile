import 'dart:io';

import 'package:flutter/material.dart';

import '../../generated/l10n.dart';

class ImageDetailsScreen extends StatelessWidget {
  final String imagePath;

  const ImageDetailsScreen({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).imageDetails),
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