import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/nest.dart';

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
        leading: const Icon(Icons.egg_outlined),
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

        },

    );
  }
}