import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/inventory.dart';
import '../providers/weather_provider.dart';
import 'weather_list_item.dart';

class WeatherTab extends StatefulWidget {
  final Inventory inventory;
  final GlobalKey<AnimatedListState> weatherListKey;

  const WeatherTab({super.key, required this.inventory, required this.weatherListKey});

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
        return AnimatedList(
          key: widget.weatherListKey,
          initialItemCount: weatherList.length,
          itemBuilder: (context, index, animation) {
            final weather = weatherList[index];
            return WeatherListItem(
              weather: weather,
              animation: animation,
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
                            Navigator.of(context).pop(true);
                            final indexToRemove = weatherList.indexOf(
                                weather);
                            weatherProvider.removeWeather(
                                widget.inventory.id, weather.id!).then((
                                _) {
                              widget.weatherListKey.currentState?.removeItem(
                                indexToRemove,
                                    (context, animation) =>
                                    WeatherListItem(weather: weather,
                                        animation: animation,
                                        onDelete: () {}),
                              );
                            });
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
        );
      },
    );
  }
}
