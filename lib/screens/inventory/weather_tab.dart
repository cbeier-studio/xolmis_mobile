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
            child: Text('Nenhum dado de tempo registrado.'),
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
                onDelete: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Confirmar exclusão'),
                        content: const Text(
                            'Tem certeza que deseja excluir este registro do tempo?'),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancelar'),
                          ),
                          TextButton(
                            onPressed: () {
                              weatherProvider.removeWeather(
                                  widget.inventory.id, weather.id!);
                              Navigator.of(context).pop(true);
                            },
                            child: const Text('Excluir'),
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          )
          );
        }
      },
    );
  }
}
