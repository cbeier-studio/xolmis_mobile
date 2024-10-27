import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/inventory.dart';

class WeatherListItem extends StatefulWidget {
  final Weather weather;
  final Animation<double> animation;
  final VoidCallback onDelete;

  const WeatherListItem({
    super.key,
    required this.weather,
    required this.animation,
    required this.onDelete,
  });

  @override
  WeatherListItemState createState() => WeatherListItemState();
}

class WeatherListItemState extends State<WeatherListItem> {
  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: widget.animation,
      child: ListTile(
        leading: const Icon(Icons.cloudy_snowing),
        title: Text(DateFormat('dd/MM/yyyy HH:mm:ss').format(widget.weather.sampleTime!)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nebulosidade: ${widget.weather.cloudCover}%'),
            Text('Precipitação: ${precipitationTypeFriendlyNames[widget.weather.precipitation]}'),
            Text('Temperatura: ${widget.weather.temperature} °C'),
            Text('Vento: ${widget.weather.windSpeed} bft'),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete),
          tooltip: 'Apagar dados do tempo',
          onPressed: widget.onDelete,
        ),
        onTap: () {

        },
      ),
    );
  }
}