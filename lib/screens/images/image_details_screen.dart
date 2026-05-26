import 'dart:io';

import 'package:flutter/material.dart';

import '../../generated/l10n.dart';

/// Displays a single image file with zoom and pan support.
class ImageDetailsScreen extends StatelessWidget {
  final String imagePath;

  /// Creates an image details screen for the file at [imagePath].
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