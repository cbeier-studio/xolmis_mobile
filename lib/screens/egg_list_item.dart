import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/nest.dart';

class EggListItem extends StatefulWidget {
  final Egg egg;
  final Animation<double> animation;
  final VoidCallback onDelete;

  const EggListItem({
    super.key,
    required this.egg,
    required this.animation,
    required this.onDelete,
  });

  @override
  EggListItemState createState() => EggListItemState();
}

class EggListItemState extends State<EggListItem> {
  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: widget.animation,
      child: ListTile(
        leading: const Icon(Icons.egg),
        title: Text('${widget.egg.fieldNumber}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${widget.egg.speciesName}'),
            Text(DateFormat('dd/MM/yyyy HH:mm:ss').format(widget.egg.sampleTime!)),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete),
          onPressed: widget.onDelete,
        ),
        onTap: () {

        },
      ),
    );
  }
}