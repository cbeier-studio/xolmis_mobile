import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/inventory.dart';

class VegetationListItem extends StatelessWidget {
  final Vegetation vegetation;
  final Animation<double> animation;

  const VegetationListItem({
    super.key,
    required this.vegetation,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: animation,
      child: ListTile(
        leading: const Icon(Icons.grass),
        title: Text(DateFormat('dd/MM/yyyy HH:mm:ss').format(vegetation.sampleTime)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${vegetation.latitude}; ${vegetation.longitude}'),
            Text('Herbáceas: ${vegetation.herbsDistribution}; ${vegetation.herbsProportion}%; ${vegetation.herbsHeight} cm'),
            Text('Arbustos: ${vegetation.shrubsDistribution}; ${vegetation.shrubsProportion}%; ${vegetation.shrubsHeight} cm'),
            Text('Árvores: ${vegetation.treesDistribution}; ${vegetation.treesProportion}%; ${vegetation.treesHeight} cm'),
          ],
        ),
      ),
    );
  }
}