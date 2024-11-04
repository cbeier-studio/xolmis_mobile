import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../data/models/nest.dart';
import '../../data/models/app_image.dart';
import '../../providers/app_image_provider.dart';
import '../app_image_screen.dart';

class RevisionListItem extends StatefulWidget {
  final NestRevision nestRevision;
  final VoidCallback onLongPress;

  const RevisionListItem({
    super.key,
    required this.nestRevision,
    required this.onLongPress,
  });

  @override
  RevisionListItemState createState() => RevisionListItemState();
}

class RevisionListItemState extends State<RevisionListItem> {
  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: FutureBuilder<List<AppImage>>(
        future: Provider.of<AppImageProvider>(context, listen: false)
            .fetchImagesForNestRevision(widget.nestRevision.id!),
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
        title: Text(DateFormat('dd/MM/yyyy HH:mm:ss').format(widget.nestRevision.sampleTime!)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${nestStatusTypeFriendlyNames[widget.nestRevision.nestStatus]}: ${nestStageTypeFriendlyNames[widget.nestRevision.nestStage]}',
              style: TextStyle(
                color: widget.nestRevision.nestStatus == NestStatusType.nstActive
                    ? Colors.blue
                    : widget.nestRevision.nestStatus == NestStatusType.nstInactive
                    ? Colors.red
                    : null,
              ),
            ),
            Text('Hospedeiro: ${widget.nestRevision.eggsHost ?? 0} ovo(s), ${widget.nestRevision.nestlingsHost ?? 0} ninhego(s)'),
            Text('Nidoparasita: ${widget.nestRevision.eggsParasite ?? 0} ovo(s), ${widget.nestRevision.nestlingsParasite ?? 0} ninhego(s)'),
          ],
        ),
        onLongPress: widget.onLongPress,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AppImageScreen(
                nestRevisionId: widget.nestRevision.id,
              ),
            ),
          );
        },

    );
  }
}