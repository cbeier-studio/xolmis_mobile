import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/inventory.dart';
import '../providers/weather_provider.dart';

class AddWeatherScreen extends StatefulWidget {
  final Inventory inventory;

  const AddWeatherScreen({
    super.key,
    required this.inventory,
  });

  @override
  AddWeatherScreenState createState() => AddWeatherScreenState();
}

class AddWeatherScreenState extends State<AddWeatherScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _cloudCoverController;
  PrecipitationType _selectedPrecipitation = PrecipitationType.preNone;
  late TextEditingController _temperatureController;
  late TextEditingController _windSpeedController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _cloudCoverController = TextEditingController();
    _temperatureController = TextEditingController();
    _windSpeedController = TextEditingController();
  }

  @override
  void dispose() {
    _cloudCoverController.dispose();
    _temperatureController.dispose();
    _windSpeedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dados do Tempo'),
          actions: [
            _isSubmitting
                ? CircularProgressIndicator()
                : TextButton(
              onPressed: _submitForm,
              child: const Text('Salvar'),
            ),
          ]
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView( // Prevent keyboard overflow
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cloudCoverController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Nebulosidade',
                        border: OutlineInputBorder(),
                        suffixText: '%',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: DropdownButtonFormField<PrecipitationType>(
                        value: _selectedPrecipitation,
                        decoration: const InputDecoration(
                          labelText: 'Precipitação',
                          border: OutlineInputBorder(),
                        ),
                        items: PrecipitationType.values.map((precipitation) {
                          return DropdownMenuItem(
                            value: precipitation,
                            child: Text(precipitationTypeFriendlyNames[precipitation]!),
                          );
                        }).toList(),
                        onChanged: (PrecipitationType? newValue) {
                          setState(() {
                            _selectedPrecipitation = newValue!;
                          });
                        }
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _temperatureController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Temperatura',
                        border: OutlineInputBorder(),
                        suffixText: '°C',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: TextFormField(
                      controller: _windSpeedController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Vento',
                        border: OutlineInputBorder(),
                        suffixText: 'bft',
                      ),
                    ),
                  ),
                ],
              ),
              // const SizedBox(height: 16.0),
              // ElevatedButton(
              //   onPressed: _isSubmitting ? null : () async {
              //
              //   },
              //   child: _isSubmitting
              //       ? const CircularProgressIndicator()
              //       : const Text('Salvar'),
              // ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitForm() async {
    setState(() {
      _isSubmitting = true;
    });

    if (_formKey.currentState!.validate()) {
      // Save the weather data
      final weather = Weather(
        inventoryId: widget.inventory.id,
        sampleTime: DateTime.now(),
        cloudCover: int.tryParse(_cloudCoverController.text) ?? 0,
        precipitation: _selectedPrecipitation,
        temperature: double.tryParse(_temperatureController.text) ?? 0,
        windSpeed: int.tryParse(_windSpeedController.text) ?? 0,
      );

      setState(() {
        _isSubmitting = false;
      });

      final weatherProvider = Provider.of<WeatherProvider>(context, listen: false);
      try {
        await weatherProvider.addWeather(context, widget.inventory.id, weather);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Row(
            children: [
              Icon(Icons.check_circle_outlined, color: Colors.green),
              SizedBox(width: 8),
              Text('Dados do tempo adicionados!'),
            ],
          ),
          ),
        );
      } catch (error) {
        if (kDebugMode) {
          print('Error adding weather: $error');
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Row(
            children: [
              Icon(Icons.error_outlined, color: Colors.red),
              SizedBox(width: 8),
              Text('Erro ao salvar os dados do tempo'),
            ],
          ),
          ),
        );
      }
    }
  }
}