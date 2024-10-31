import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/nest.dart';

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
        leading: const Icon(Icons.beenhere_outlined),
        title: Text(DateFormat('dd/MM/yyyy HH:mm:ss').format(widget.nestRevision.sampleTime!)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${nestStatusTypeFriendlyNames[widget.nestRevision.nestStatus]}: ${nestStageTypeFriendlyNames[widget.nestRevision.nestStage]}'),
            Text('Hospedeiro: ${widget.nestRevision.eggsHost ?? 0} ovo(s), ${widget.nestRevision.nestlingsHost ?? 0} ninhego(s)'),
            Text('Nidoparasita: ${widget.nestRevision.eggsParasite ?? 0} ovo(s), ${widget.nestRevision.nestlingsParasite ?? 0} ninhego(s)'),
          ],
        ),
        onLongPress: widget.onLongPress,
        onTap: () {

        },

    );
  }
}