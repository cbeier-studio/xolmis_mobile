import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../data/models/inventory.dart';
import '../../providers/weather_provider.dart';
import '../../generated/l10n.dart';
import '../../utils/utils.dart';

class AddWeatherScreen extends StatefulWidget {
  final Inventory inventory;
  final Weather? weather;
  final bool isEditing;

  const AddWeatherScreen({
    super.key,
    required this.inventory,
    this.weather,
    this.isEditing = false,
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

    if (widget.isEditing) {
      _selectedPrecipitation = widget.weather!.precipitation!;
      _cloudCoverController.text = widget.weather!.cloudCover.toString();
      _temperatureController.text = widget.weather!.temperature.toString();
      _windSpeedController.text = widget.weather!.windSpeed.toString();
    }
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
          title: Text(S.of(context).weatherData),
        ),
        body: Column(
            children: [
              Expanded(
                child: Form(
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
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                decoration: InputDecoration(
                                  labelText: S.of(context).cloudCover,
                                  helperText: ' ',
                                  border: OutlineInputBorder(),
                                  suffixText: '%',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8.0),
                            Expanded(
                              child: DropdownButtonFormField<PrecipitationType>(
                                  value: _selectedPrecipitation,
                                  decoration: InputDecoration(
                                    labelText: '${S.of(context).precipitation} *',
                                    helperText: S.of(context).requiredField,
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
                                  },
                                validator: (value) {
                                  if (value == null || value.index < 0) {
                                    return S.of(context).selectPrecipitation;
                                  }
                                  return null;
                                },
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
                                inputFormatters: [
                                  CommaToDotTextInputFormatter(),
                                  // Allow only numbers and decimal separator with 1 decimal place
                                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}')),
                                ],
                                decoration: InputDecoration(
                                  labelText: S.of(context).temperature,
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
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                decoration: InputDecoration(
                                  labelText: S.of(context).windSpeed,
                                  border: OutlineInputBorder(),
                                  suffixText: 'bft',
                                ),
                                validator: (value) {
                                  if (value != null && (int.tryParse(value)! < 0 || int.tryParse(value)! > 12)) {
                                    return S.of(context).windSpeedRangeError;
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Container(
                    padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
                    width: double.infinity,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: _isSubmitting
                          ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : FilledButton(
                        onPressed: _submitForm,
                        child: Text(S.of(context).save),
                      ),
                    )
                ),
              ),
            ]
        )
    );
  }

  void _submitForm() async {
    setState(() {
      _isSubmitting = true;
    });

    if (_formKey.currentState!.validate()) {
      if (widget.isEditing) {
        final updatedWeather = widget.weather!.copyWith(
          cloudCover: int.tryParse(_cloudCoverController.text) ?? 0,
          precipitation: _selectedPrecipitation,
          temperature: double.tryParse(_temperatureController.text) ?? 0,
          windSpeed: int.tryParse(_windSpeedController.text) ?? 0,
        );

        try {
          final weatherProvider = Provider.of<WeatherProvider>(context, listen: false);
          await weatherProvider.updateWeather(updatedWeather);

          Navigator.pop(context);
        } catch (error) {
          if (kDebugMode) {
            print('Error saving weather: $error');
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error_outlined, color: Colors.red),
                  SizedBox(width: 8),
                  Text(S.current.errorSavingWeather),
                ],
              ),
            ),
          );
        }
      } else {
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

        final weatherProvider =
            Provider.of<WeatherProvider>(context, listen: false);
        try {
          await weatherProvider.addWeather(
              context, widget.inventory.id, weather);
          Navigator.pop(context);
          // ScaffoldMessenger.of(context).showSnackBar(
          //   const SnackBar(content: Row(
          //     children: [
          //       Icon(Icons.check_circle_outlined, color: Colors.green),
          //       SizedBox(width: 8),
          //       Text('Dados do tempo adicionados!'),
          //     ],
          //   ),
          //   ),
          // );
        } catch (error) {
          if (kDebugMode) {
            print('Error adding weather: $error');
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error_outlined, color: Colors.red),
                  SizedBox(width: 8),
                  Text(S.current.errorSavingWeather),
                ],
              ),
            ),
          );
        }
      }
    } else {
      setState(() {
        _isSubmitting = false;
      });
    }
  }
}