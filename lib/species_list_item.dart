import 'package:flutter/material.dart';
import 'inventory.dart';

class SpeciesListItem extends StatelessWidget {
  final Species species;
  final Animation<double> animation;

  const SpeciesListItem({
    super.key,
    required this.species,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: animation,
      child: ListTile(
        title: Text(species.name),
        trailing: Text('${species.count}'),
      ),
    );
  }
}