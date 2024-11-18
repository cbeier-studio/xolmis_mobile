import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../data/models/app_image.dart';
import '../../providers/app_image_provider.dart';
import '../../data/models/inventory.dart';
import '../app_image_screen.dart';

class VegetationListItem extends StatefulWidget {
  final Vegetation vegetation;
  final VoidCallback onLongPress;

  const VegetationListItem({
    super.key,
    required this.vegetation,
    required this.onLongPress,
  });

  @override
  VegetationListItemState createState() => VegetationListItemState();
}

class VegetationListItemState extends State<VegetationListItem> {
  @override
  Widget build(BuildContext context) {
    return ListTile(
        leading: FutureBuilder<List<AppImage>>(
          future: Provider.of<AppImageProvider>(context, listen: false)
              .fetchImagesForVegetation(widget.vegetation.id ?? 0),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return const Icon(Icons.error);
            } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(0),
                child: Image.file(
                  File(snapshot.data!.first.imagePath),
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
              );
            } else {
              return const Icon(Icons.hide_image_outlined);
            }
          },
        ),
        title: Text(DateFormat('dd/MM/yyyy HH:mm:ss').format(widget.vegetation.sampleTime!)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${widget.vegetation.latitude}; ${widget.vegetation.longitude}'),
            Text('Herbáceas: ${widget.vegetation.herbsDistribution?.index ?? 0}; ${widget.vegetation.herbsProportion}%; ${widget.vegetation.herbsHeight} cm'),
            Text('Arbustos: ${widget.vegetation.shrubsDistribution?.index ?? 0}; ${widget.vegetation.shrubsProportion}%; ${widget.vegetation.shrubsHeight} cm'),
            Text('Árvores: ${widget.vegetation.treesDistribution?.index ?? 0}; ${widget.vegetation.treesProportion}%; ${widget.vegetation.treesHeight} cm'),
          ],
        ),
        onLongPress: widget.onLongPress,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AppImageScreen(
                vegetationId: widget.vegetation.id,
              ),
            ),
          );
        },
    );
  }
}