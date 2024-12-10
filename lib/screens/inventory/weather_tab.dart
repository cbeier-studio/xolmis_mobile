import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../data/models/inventory.dart';
import '../../providers/weather_provider.dart';
import '../../generated/l10n.dart';
import 'add_weather_screen.dart';

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

  Future<void> _deleteWeather(Weather weather) async {
    final confirmed = await _showDeleteConfirmationDialog(context);
    if (confirmed) {
      Provider.of<WeatherProvider>(context, listen: false)
          .removeWeather(widget.inventory.id, weather.id!);
    }
  }

  Future<bool> _showDeleteConfirmationDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(S.of(context).confirmDelete),
          content: Text(S.of(context).confirmDeleteMessage(1, "male", S.of(context).weatherRecord)),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(S.of(context).cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(S.of(context).delete),
            ),
          ],
        );
      },
    ) ?? false;
  }

  Widget _buildWeatherList() {
    return Column(
      children: [
        Expanded(
            child: Consumer<WeatherProvider>(
                builder: (context, weatherProvider, child) {
                  final weatherList = weatherProvider.getWeatherForInventory(
                      widget.inventory.id);
                  if (weatherList.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(8.0, 16.0, 8.0, 16.0),
                        child: Text(S.of(context).noWeatherFound),
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
                              return _buildGridView(weatherList);
                            } else {
                              return _buildListView(weatherList);
                            }
                          }
                      ),
                    );
                  }
                }
            )
        )
      ],
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
                  ListTile(
                    leading: const Icon(Icons.edit_outlined),
                    title: Text(S.of(context).editWeather),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddWeatherScreen(
                            inventory: widget.inventory,
                            weather: weather, // Passe o objeto Vegetation
                            isEditing: true, // Defina isEditing como true
                          ),
                        ),
                      );
                    },
                  ),
                  Divider(),
                  ListTile(
                    leading: const Icon(Icons.delete_outlined, color: Colors.red,),
                    title: Text(S.of(context).deleteWeather, style: TextStyle(color: Colors.red),),
                    onTap: () async {
                      await _deleteWeather(weather);
                      Navigator.pop(context);
                    },
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGridView(List<Weather> weatherList) {
    return SingleChildScrollView(
        child: Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 840),
        child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 3.8,
            ),
            physics: const NeverScrollableScrollPhysics(),
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
                  child: WeatherGridItem(weather: weather),
                ),
              );
            },
        ),
      ),
    ),
    );
  }

  Widget _buildListView(List<Weather> weatherList) {
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

class WeatherGridItem extends StatelessWidget {
  const WeatherGridItem({
    super.key,
    required this.weather,
  });

  final Weather weather;

  @override
  Widget build(BuildContext context) {
    return Card.filled(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Wrap(
          children: [
            Text(
              DateFormat('dd/MM/yyyy HH:mm:ss').format(weather.sampleTime!),
              style: const TextStyle(
                  fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                Icon(Icons.cloud_outlined),
                SizedBox(width: 4,),
                Text('${weather.cloudCover}%'),
                SizedBox(width: 8,),
                Icon(Icons.water_drop_outlined),
                SizedBox(width: 4,),
                Text('${precipitationTypeFriendlyNames[weather.precipitation]}'),
                SizedBox(width: 8,),
                Icon(Icons.thermostat_outlined),
                SizedBox(width: 4,),
                Text('${weather.temperature} °C'),
                SizedBox(width: 8,),
                Icon(Icons.wind_power_outlined),
                SizedBox(width: 4,),
                Text('${weather.windSpeed} bft'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class WeatherListItem extends StatefulWidget {
  final Weather weather;
  final VoidCallback onLongPress;

  const WeatherListItem({
    super.key,
    required this.weather,
    required this.onLongPress,
  });

  @override
  WeatherListItemState createState() => WeatherListItemState();
}

class WeatherListItemState extends State<WeatherListItem> {
  @override
  Widget build(BuildContext context) {
    return ListTile(
      // leading: const Icon(Icons.wb_sunny_outlined),
      title: Text(DateFormat('dd/MM/yyyy HH:mm:ss').format(widget.weather.sampleTime!)),
      subtitle: Row(
        children: [
          Icon(Icons.cloud_outlined),
          SizedBox(width: 4,),
          Text('${widget.weather.cloudCover}%'),
          SizedBox(width: 8,),
          Icon(Icons.water_drop_outlined),
          SizedBox(width: 4,),
          Text('${precipitationTypeFriendlyNames[widget.weather.precipitation]}'),
          SizedBox(width: 8,),
          Icon(Icons.thermostat_outlined),
          SizedBox(width: 4,),
          Text('${widget.weather.temperature} °C'),
          SizedBox(width: 8,),
          Icon(Icons.wind_power_outlined),
          SizedBox(width: 4,),
          Text('${widget.weather.windSpeed} bft'),
        ],
      ),
      onLongPress: widget.onLongPress,
      // onTap: () {
      //
      // },

    );
  }
}
