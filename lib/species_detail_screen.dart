import 'package:flutter/material.dart';
import 'inventory.dart';
import 'database_helper.dart';

class SpeciesDetailScreen extends StatefulWidget {
  final Species species;

  const SpeciesDetailScreen({Key? key, required this.species}) : super(key: key);

  @override
  _SpeciesDetailScreenState createState() => _SpeciesDetailScreenState();
}

class _SpeciesDetailScreenState extends State<SpeciesDetailScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('POIs de ${widget.species.name}'),
      ),
      body: AnimatedList(
        key: _listKey,
        initialItemCount: widget.species.pois.length,
        itemBuilder: (context, index, animation){
          final poi = widget.species.pois[index];
          return Dismissible( // Adicione o Dismissible aqui
            key: ValueKey(poi),
            direction: DismissDirection.endToStart,
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20.0),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            confirmDismiss: (direction) async {
              return await showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Confirmar exclusão'),
                    content: const Text('Tem certeza que deseja excluir este POI?'),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Excluir'),
                      ),
                    ],
                  );
                },
              );
            },
            onDismissed: (direction) {
              // Apague o POI do banco de dados
              DatabaseHelper().deletePoi(poi.id!); // Supondo que Poi tenha um ID

              // Remova o POI da lista e atualize a AnimatedList
              setState(() {
                widget.species.pois.removeAt(index);
                _listKey.currentState!.removeItem(
                  index,
                      (context, animation) => PoiListItem(
                    poi: poi,
                    animation: animation,
                  ),
                );
              });
            },
            child: PoiListItem(
              poi: poi,
              animation: animation,
            ),
          );
        },
      ),
    );
  }
}

class PoiListItem extends StatelessWidget {
  final Poi poi;
  final Animation<double> animation;

  const PoiListItem({Key? key, required this.poi, required this.animation})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: animation,
      child: ListTile(title: Text('Latitude: ${poi.latitude}, Longitude: ${poi.longitude}'),
      ),
    );
  }
}