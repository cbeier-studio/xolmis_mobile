import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
    return Column(
        children: [
          Consumer<WeatherProvider>(
        builder: (context, weatherProvider, child) {
          final weatherList = weatherProvider.getWeatherForInventory(
              widget.inventory.id);
          if (weatherList.isEmpty) {
            return const Center(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8.0, 16.0, 8.0, 16.0),
                child: Text('Nenhum registro do tempo.'),
              ),
            );
          } else {
            return RefreshIndicator(
              onRefresh: () async {
                await weatherProvider.getWeatherForInventory(
                    widget.inventory.id);
              },
              child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    final screenWidth = constraints.maxWidth;
                    final isLargeScreen = screenWidth > 600;

                    if (isLargeScreen) {
                      return Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 840),
                          child: GridView.builder(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 3.0,
                            ),
                            shrinkWrap: true,
                            itemCount: weatherList.length,
                            itemBuilder: (context, index) {
                              final weather = weatherList[index];
                              return GridTile(
                                child: InkWell(
                                  onLongPress: () =>
                                      _showBottomSheet(context, weather),
                                  // onTap: () {
                                  //
                                  // },
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Row(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(0.0, 16.0, 16.0, 16.0),
                                          child: const Icon(Icons.wb_sunny_outlined),
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              DateFormat('dd/MM/yyyy HH:mm:ss').format(weather.sampleTime!),
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            Text('Nebulosidade: ${weather.cloudCover}%'),
                                            Text('Precipitação: ${precipitationTypeFriendlyNames[weather.precipitation]}'),
                                            Text('Temperatura: ${weather.temperature} °C'),
                                            Text('Vento: ${weather.windSpeed} bft'),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    } else {
                      return ListView.builder(
                        shrinkWrap: true,
                        itemCount: weatherList.length,
                        itemBuilder: (context, index) {
                          final weather = weatherList[index];
                          return WeatherListItem(
                            weather: weather,
                            onLongPress: () =>
                                _showBottomSheet(context, weather),
                          );
                        },
                      );
                    }
                  }
              ),
            );
          }
        }
    )
    ]
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
