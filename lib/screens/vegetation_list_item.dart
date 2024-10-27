import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/inventory.dart';

class VegetationListItem extends StatefulWidget {
  final Vegetation vegetation;
  final Animation<double> animation;
  final VoidCallback onDelete;

  const VegetationListItem({
    super.key,
    required this.vegetation,
    required this.animation,
    required this.onDelete,
  });

  @override
  VegetationListItemState createState() => VegetationListItemState();
}

class VegetationListItemState extends State<VegetationListItem> {
  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: widget.animation,
      child: ListTile(
        leading: const Icon(Icons.local_florist),
        title: Text(DateFormat('dd/MM/yyyy HH:mm:ss').format(widget.vegetation.sampleTime!)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${widget.vegetation.latitude}; ${widget.vegetation.longitude}'),
            Text('Herbáceas: ${widget.vegetation.herbsDistribution}; ${widget.vegetation.herbsProportion}%; ${widget.vegetation.herbsHeight} cm'),
            Text('Arbustos: ${widget.vegetation.shrubsDistribution}; ${widget.vegetation.shrubsProportion}%; ${widget.vegetation.shrubsHeight} cm'),
            Text('Árvores: ${widget.vegetation.treesDistribution}; ${widget.vegetation.treesProportion}%; ${widget.vegetation.treesHeight} cm'),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete),
          tooltip: 'Apagar dados de vegetação',
          onPressed: widget.onDelete,
        ),
        onTap: () {

        },
      ),
    );
  }
}