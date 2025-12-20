import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../data/models/inventory.dart';
import '../../providers/weather_provider.dart';
import '../../core/core_consts.dart';
import '../../utils/utils.dart';
import '../../generated/l10n.dart';
import 'add_weather_screen.dart';

class WeatherTab extends StatefulWidget {
  final Inventory inventory;

  const WeatherTab({super.key, required this.inventory});

  @override
  State<WeatherTab> createState() => _WeatherTabState();
}

class _WeatherTabState extends State<WeatherTab>
    with AutomaticKeepAliveClientMixin {
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
      Provider.of<WeatherProvider>(
        context,
        listen: false,
      ).removeWeather(widget.inventory.id, weather.id!);
    }
  }

  Future<bool> _showDeleteConfirmationDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog.adaptive(
              title: Text(S.of(context).confirmDelete),
              content: Text(
                S.of(context).confirmDeleteMessage(1, "male", S.of(context).weatherRecord,),
              ),
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
        ) ??
        false;
  }

  Widget _buildWeatherList() {
    return Column(
      children: [
        Expanded(
          child: Consumer<WeatherProvider>(
            builder: (context, weatherProvider, child) {
              final weatherList = weatherProvider.getWeatherForInventory(
                widget.inventory.id,
              );
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
                      widget.inventory.id,
                    );
                  },
                  child: _buildListView(weatherList),
                      
                    
                  
                );
              }
            },
          ),
        ),
      ],
    );
  }

  void _showBottomSheet(BuildContext context, Weather weather) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: BottomSheet(
            onClosing: () {},
            builder: (BuildContext context) {
              return Container(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        DateFormat('dd/MM/yyyy HH:mm:ss',).format(weather.sampleTime!),
                        style: TextTheme.of(context).bodyLarge,
                      ),
                    ),
                    // ListTile(
                    //   title: Text(
                    //     DateFormat(
                    //       'dd/MM/yyyy HH:mm:ss',
                    //     ).format(weather.sampleTime!),
                    //   ),
                    // ),
                    const Divider(),
                    GridView.count(
                      crossAxisCount: MediaQuery.sizeOf(context).width < 600 ? 4 : 5,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: <Widget>[
                        buildGridMenuItem(
                          context,
                          Icons.edit_outlined,
                          S.current.edit,
                          () {
                            Navigator.of(context).pop();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => AddWeatherScreen(
                                      inventory: widget.inventory,
                                      weather: weather,
                                      isEditing: true,
                                    ),
                              ),
                            );
                          },
                        ),
                        buildGridMenuItem(
                          context,
                          Icons.delete_outlined,
                          S.of(context).delete,
                          () async {
                            Navigator.of(context).pop();
                            await _deleteWeather(weather);
                          },
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ],
                    ),
                  ],
                ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildListView(List<Weather> weatherList) {
    return ListView.separated(
      separatorBuilder: (context, index) => Divider(),
      shrinkWrap: true,
      itemCount: weatherList.length,
      itemBuilder: (context, index) {
        final weather = weatherList[index];
        return WeatherListItem(
          weather: weather,
          onLongPress: () => _showBottomSheet(context, weather),
        );
      },
    );
  }
}

class WeatherGridItem extends StatefulWidget {
  final Weather weather;
  final VoidCallback onLongPress;

  const WeatherGridItem({
    super.key,
    required this.weather,
    required this.onLongPress,
  });

  @override
  WeatherGridItemState createState() => WeatherGridItemState();
}

class WeatherGridItemState extends State<WeatherGridItem> {
  @override
  Widget build(BuildContext context) {
    return GridTile(
        child: InkWell(
      onLongPress: () => widget.onLongPress,
      child: Card.outlined(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('dd/MM/yyyy HH:mm:ss').format(widget.weather.sampleTime!),
                style: TextTheme.of(context).headlineSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0, // horizontal space between children
                runSpacing: 4.0, // vertical space between runs
                alignment: WrapAlignment.start,
                children: <Widget>[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_outlined),
                      const SizedBox(width: 4),
                      Text('${widget.weather.cloudCover}%'),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloudy_snowing),
                      const SizedBox(width: 4),
                      Text(
                        '${precipitationTypeFriendlyNames[widget.weather.precipitation]}',
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.thermostat_outlined),
                      const SizedBox(width: 4),
                      Text('${widget.weather.temperature} °C'),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wind_power_outlined),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.weather.windSpeed} bft ${widget.weather.windDirection ?? ''}',
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cyclone_outlined),
                      const SizedBox(width: 4),
                      Text('${widget.weather.atmosphericPressure ?? 0} mPa'),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.water_drop_outlined),
                      const SizedBox(width: 4),
                      Text('${widget.weather.relativeHumidity ?? 0}%'),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
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
      title: Text(
        DateFormat('dd/MM/yyyy HH:mm:ss').format(widget.weather.sampleTime!),
      ),
      subtitle: Wrap(
        direction: Axis.horizontal,
        spacing: 8.0, // horizontal space between children
        runSpacing: 4.0, // vertical space between runs
        alignment: WrapAlignment.start,
        children: <Widget>[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_outlined),
              const SizedBox(width: 4),
              Text('${widget.weather.cloudCover}%'),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloudy_snowing),
              const SizedBox(width: 4),
              Text(
                '${precipitationTypeFriendlyNames[widget.weather.precipitation]}',
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.thermostat_outlined),
              const SizedBox(width: 4),
              Text('${widget.weather.temperature} °C'),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wind_power_outlined),
              const SizedBox(width: 4),
              Text(
                '${widget.weather.windSpeed} bft ${widget.weather.windDirection ?? ''}',
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cyclone_outlined),
              const SizedBox(width: 4),
              Text('${widget.weather.atmosphericPressure ?? 0} mPa'),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.water_drop_outlined),
              const SizedBox(width: 4),
              Text('${widget.weather.relativeHumidity ?? 0}%'),
            ],
          ),
        ],
      ),
      onLongPress: widget.onLongPress,
      // onTap: () {
      //
      // },
    );
  }
}
