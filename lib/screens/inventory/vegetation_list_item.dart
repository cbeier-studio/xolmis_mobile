import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/inventory.dart';

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
        leading: const Icon(Icons.local_florist_outlined),
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
        onLongPress: widget.onLongPress,
        onTap: () {

        },

    );
  }
}