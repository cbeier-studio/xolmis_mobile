import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../data/models/nest.dart';
import '../../data/models/app_image.dart';
import '../../providers/app_image_provider.dart';
import '../app_image_screen.dart';

class EggListItem extends StatefulWidget {
  final Egg egg;
  final VoidCallback onLongPress;

  const EggListItem({
    super.key,
    required this.egg,
    required this.onLongPress,
  });

  @override
  EggListItemState createState() => EggListItemState();
}

class EggListItemState extends State<EggListItem> {
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: FutureBuilder<List<AppImage>>(
        future: Provider.of<AppImageProvider>(context, listen: false)
            .fetchImagesForEgg(widget.egg.id!),
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
        title: Text('${widget.egg.fieldNumber}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.egg.speciesName!,
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
            Text(DateFormat('dd/MM/yyyy HH:mm:ss').format(widget.egg.sampleTime!)),
          ],
        ),
        onLongPress: widget.onLongPress,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AppImageScreen(
                eggId: widget.egg.id,
              ),
            ),
          );
        },

    );
  }
}