import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/nest.dart';

class RevisionListItem extends StatefulWidget {
  final NestRevision nestRevision;
  final Animation<double> animation;
  final VoidCallback onDelete;

  const RevisionListItem({
    super.key,
    required this.nestRevision,
    required this.animation,
    required this.onDelete,
  });

  @override
  RevisionListItemState createState() => RevisionListItemState();
}

class RevisionListItemState extends State<RevisionListItem> {
  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: widget.animation,
      child: ListTile(
        leading: const Icon(Icons.rate_review_outlined),
        title: Text(DateFormat('dd/MM/yyyy HH:mm:ss').format(widget.nestRevision.sampleTime!)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${nestStatusTypeFriendlyNames[widget.nestRevision.nestStatus]}: ${nestStageTypeFriendlyNames[widget.nestRevision.nestStage]}'),
            Text('Hospedeiro: ${widget.nestRevision.eggsHost ?? 0} ovo(s), ${widget.nestRevision.nestlingsHost ?? 0} ninhego(s)'),
            Text('Nidoparasita: ${widget.nestRevision.eggsParasite ?? 0} ovo(s), ${widget.nestRevision.nestlingsParasite ?? 0} ninhego(s)'),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outlined),
          tooltip: 'Apagar revisão de ninho',
          onPressed: widget.onDelete,
        ),
        onTap: () {

        },
      ),
    );
  }
}