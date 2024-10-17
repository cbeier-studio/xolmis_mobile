import 'package:flutter/material.dart';
import 'package:animated_list/animated_list.dart';
import 'package:geolocator/geolocator.dart';
import 'inventory.dart';
import 'database_helper.dart';
import 'add_inventory_screen.dart';
import 'inventory_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  List<Inventory> _activeInventories = [];
  final dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _checkLocationPermissions();
    _loadActiveInventories().then((_) { // Chama _loadActiveInventories e, em seguida, verifica os inventários
      for (var inventory in _activeInventories) {
        if (inventory.duration > 0 && !inventory.isFinished) { // Verifica se a duração é maior que 0 e se o inventário não está finalizado
          inventory.resumeTimer(); // Chama resumeTimer para os inventários que atendem às condições
        }}
    });
  }

  Future<void> _checkLocationPermissions() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissões negadas permanentemente
        // Exiba uma mensagem ao usuário ou redirecione para as configurações do app
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissões negadas permanentemente
      // Exiba uma mensagem ao usuário ou redirecione para as configurações do app
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // Permissões concedidas, você pode usar o Geolocator aqui
  }

  Future<void> _loadActiveInventories() async {
    final inventories = await dbHelper.loadActiveInventories();
    setState(() {
      _activeInventories = inventories;
    });
  }

  void _onInventoryPausedOrResumed() {
    setState(() {
      _loadActiveInventories(); // Recarrega os inventários
    });
  }

  void onInventoryUpdated() {
    setState(() {
      _loadActiveInventories(); // Recarrega os inventários
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadActiveInventories,
        child: _activeInventories.isEmpty // Verifica se a lista está vazia
            ? const Center(child: Text('Nenhum inventário ativo.')) // Mostra o texto se a lista estiver vazia
            : AnimatedList(
          key: _listKey,
          initialItemCount: _activeInventories.length,
          itemBuilder: (context, index, animation) {
            final inventory = _activeInventories[index];
            return InventoryListItem(
              inventory: inventory,
              animation: animation,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => InventoryDetailScreen(inventory: inventory,
                    onInventoryUpdated: onInventoryUpdated,
                    ),
                  ),
                );
              },
              onInventoryPausedOrResumed: _onInventoryPausedOrResumed,
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddInventoryScreen()),
          ).then((newInventory) {
            if (newInventory != null && newInventory is Inventory) {
              setState(() {
                _activeInventories.add(newInventory);
                _listKey.currentState!.insertItem(_activeInventories.length - 1);
              });
            }
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _addInventory() {
    final newInventory = Inventory(
      id: 'Novo Inventário',
      type: InventoryType.invQualitative,
      duration: 0,
      speciesList: [],
      vegetationList: [],
    );

    newInventory.startTimer();

    dbHelper.insertInventory(newInventory).then((success) {
      if (success) {setState(() {
        _activeInventories.add(newInventory);
        _listKey.currentState!.insertItem(_activeInventories.length - 1);
      });
      } else {
        // Lidar com erro de inserção
      }
    });
  }
}

class InventoryListItem extends StatelessWidget {
  final Inventory inventory;
  final Animation<double> animation;
  final VoidCallback? onTap;
  final VoidCallback? onInventoryPausedOrResumed;

  const InventoryListItem({
    super.key,
    required this.inventory,
    required this.animation,
    this.onTap,
    this.onInventoryPausedOrResumed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell( // Ou GestureDetector
        onTap: onTap,
        child:SizeTransition(
          sizeFactor: animation,
          child: ListTile(
            leading: ValueListenableBuilder<double>( // Usa ValueListenableBuilder para atualizar a CircularProgressIndicator
              key: ValueKey(inventory.id),
              valueListenable: inventory.elapsedTimeNotifier,
              builder: (context, elapsedTime, child) {
                return CircularProgressIndicator(
                  value: inventory.duration == 0 ? 0 : (elapsedTime / (inventory.duration * 60)),
                );
              },
            ),
            title: Text(inventory.id),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${inventoryTypeFriendlyNames[inventory.type]}'),
                if (inventory.duration > 0) Text('${inventory.duration} minutos de duração'),
                Text('${inventory.speciesList.length} espécies'),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Visibility(
                  visible: inventory.duration > 0,
                  child: IconButton(
                    icon: Icon(inventory.isPaused ? Icons.play_arrow : Icons.pause),
                    onPressed: () {
                      if (inventory.isPaused) {
                        inventory.resumeTimer();
                      } else {
                        inventory.pauseTimer();
                      }
                      onInventoryPausedOrResumed?.call();
                    },
                  ),
                ),
              ],
            ),
          ),
        )
    );
  }
}