import 'dart:io';

import 'package:material_ui/material_ui.dart';

import '../../generated/l10n.dart';
import '../../utils/utils.dart';

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
      body: FutureBuilder<String>(
        future: resolveImagePath(imagePath),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final resolvedPath = snapshot.data!;
          return InteractiveViewer(
            minScale: 0.5,
            maxScale: 5.0,
            child: Center(
              child: Image.file(
                File(resolvedPath),
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      Icons.error,
                      color: Theme.of(context).colorScheme.error,
                      size: 24,
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
