import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/inventory.dart';
import '../../providers/weather_provider.dart';
import 'weather_list_item.dart';

class WeatherTab extends StatefulWidget {
  final Inventory inventory;

  const WeatherTab({super.key, required this.inventory});

  @override
  State<WeatherTab> createState() => _WeatherTabState();
}

class _WeatherTabState extends State<WeatherTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return _buildWeatherList();
  }

  Widget _buildWeatherList() {
    return Consumer<WeatherProvider>(
      builder: (context, weatherProvider, child) {
        final weatherList = weatherProvider.getWeatherForInventory(
            widget.inventory.id);
        if (weatherList.isEmpty) {
          return const Center(
            child: Text('Nenhum registro do tempo.'),
          );
        } else {
          return RefreshIndicator(
              onRefresh: () async {
            await weatherProvider.getWeatherForInventory(widget.inventory.id);
          },
        child: ListView.builder(
        itemCount: weatherList.length,
        itemBuilder: (context, index) {
              final weather = weatherList[index];
              return WeatherListItem(
                weather: weather,
                onLongPress: () => _showBottomSheet(context, weather),
              );
            },
          )
          );
        }
      },
    );
  }

  void _showBottomSheet(BuildContext context, Weather weather) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return BottomSheet(
          onClosing: () {},
          builder: (BuildContext context) {
            return Container(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  // Expanded(
                  //     child:
                  ListTile(
                    leading: const Icon(Icons.delete_outlined, color: Colors.red,),
                    title: const Text('Apagar registro do tempo', style: TextStyle(color: Colors.red),),
                    onTap: () {
                      // Ask for user confirmation
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Confirmar exclusão'),
                            content: const Text('Tem certeza que deseja excluir este registro do tempo?'),
                            actions: <Widget>[
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop(false);
                                  Navigator.of(context).pop();
                                },
                                child: const Text('Cancelar'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop(true);
                                  Navigator.of(context).pop();
                                  // Call the function to delete species
                                  Provider.of<WeatherProvider>(context, listen: false)
                                      .removeWeather(widget.inventory.id, weather.id!);
                                },
                                child: const Text('Excluir'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  )
                  // )
                ],
              ),
            );
          },
        );
      },
    );
  }
}
