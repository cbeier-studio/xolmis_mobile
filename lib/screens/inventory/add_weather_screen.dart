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
  String? _selectedWindDirection;
  late TextEditingController _atmosphericPressureController;
  late TextEditingController _relativeHumidityController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _cloudCoverController = TextEditingController();
    _temperatureController = TextEditingController();
    _windSpeedController = TextEditingController();
    _atmosphericPressureController = TextEditingController();
    _relativeHumidityController = TextEditingController();

    if (widget.isEditing) {
      _selectedPrecipitation = widget.weather!.precipitation!;
      _cloudCoverController.text = widget.weather!.cloudCover.toString();
      _temperatureController.text = widget.weather!.temperature.toString();
      _windSpeedController.text = widget.weather!.windSpeed.toString();
      _selectedWindDirection = widget.weather!.windDirection;
      _atmosphericPressureController.text = widget.weather!.atmosphericPressure.toString();
      _relativeHumidityController.text = widget.weather!.relativeHumidity.toString();
    }
  }

  @override
  void dispose() {
    _cloudCoverController.dispose();
    _temperatureController.dispose();
    _windSpeedController.dispose();
    _atmosphericPressureController.dispose();
    _relativeHumidityController.dispose();
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _cloudCoverController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                decoration: InputDecoration(
                                  labelText: S.of(context).cloudCover,
                                  border: OutlineInputBorder(),
                                  suffixText: '%',
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return null;
                                  }
                                  final clouds = int.tryParse(value);
                                  if (clouds == null) {
                                    return S.of(context).invalidNumericValue;
                                  }
                                  if (clouds < 0 || clouds > 100) {
                                    return S.of(context).cloudCoverRangeError;
                                  }
                                  return null;
                                },
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
                              child: SizedBox(width: 8.0),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16.0,),
                        Row(
                          children: [
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
                                  if (value == null || value.isEmpty) {
                                    return null;
                                  }
                                  final speed = int.tryParse(value);
                                  if (speed == null) {
                                    return S.of(context).invalidNumericValue;
                                  }
                                  if (speed < 0 || speed > 12) {
                                    return S.of(context).windSpeedRangeError;
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 8.0),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: _selectedWindDirection,
                                decoration: InputDecoration(
                                  labelText: S.current.windDirection,
                                  border: const OutlineInputBorder(),
                                ),
                                // hint: Text(S.current.selectADirection),
                                isExpanded: true,
                                items: [
                                  // Pontos Cardeais
                                  'N', 'S', 'E', 'W',
                                  // Pontos Colaterais (Intercardinais)
                                  'NE', 'NW', 'SE', 'SW',
                                  // Pontos Subcolaterais (Secundários)
                                  // 'NNE', 'ENE', 'ESE', 'SSE', 'SSW', 'WSW', 'WNW', 'NNW',
                                ].map<DropdownMenuItem<String>>((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _selectedWindDirection = newValue;
                                  });
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
                                controller: _atmosphericPressureController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  CommaToDotTextInputFormatter(),
                                  // Allow only numbers and decimal separator with 1 decimal place
                                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}')),
                                ],
                                decoration: InputDecoration(
                                  labelText: S.of(context).atmosphericPressure,
                                  border: OutlineInputBorder(),
                                  suffixText: 'mPa',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8.0),
                            Expanded(
                              child: TextFormField(
                                controller: _relativeHumidityController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  CommaToDotTextInputFormatter(),
                                  // Allow only numbers and decimal separator with 1 decimal place
                                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}')),
                                ],
                                decoration: InputDecoration(
                                  labelText: S.of(context).relativeHumidity,
                                  border: OutlineInputBorder(),
                                  suffixText: '%',
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return null;
                                  }
                                  final humidity = double.tryParse(value);
                                  if (humidity == null) {
                                    return S.of(context).invalidNumericValue;
                                  }
                                  if (humidity < 0 || humidity > 100) {
                                    return S.of(context).relativeHumidityRangeError;
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
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          year2023: false,),
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
    if (!_formKey.currentState!.validate()) {
      if (_isSubmitting) {
        setState(() {
          _isSubmitting = false;
        });
      }
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      if (widget.isEditing) {
        final updatedWeather = widget.weather!.copyWith(
          cloudCover: int.tryParse(_cloudCoverController.text) ?? 0,
          precipitation: _selectedPrecipitation,
          temperature: double.tryParse(_temperatureController.text) ?? 0,
          windSpeed: int.tryParse(_windSpeedController.text) ?? 0,
          windDirection: _selectedWindDirection,
          atmosphericPressure: double.tryParse(_atmosphericPressureController.text) ?? 0,
          relativeHumidity: double.tryParse(_relativeHumidityController.text) ?? 0,
        );

        final weatherProvider = Provider.of<WeatherProvider>(context, listen: false);
        await weatherProvider.updateWeather(updatedWeather);

        if (mounted) {
          Navigator.pop(context, true);
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
          windDirection: _selectedWindDirection,
          atmosphericPressure: double.tryParse(_atmosphericPressureController.text) ?? 0,
          relativeHumidity: double.tryParse(_relativeHumidityController.text) ?? 0,
        );

        final weatherProvider = Provider.of<WeatherProvider>(context, listen: false);
        await weatherProvider.addWeather(context, widget.inventory.id, weather);

        if (mounted) {
          Navigator.pop(context, true);
          // ScaffoldMessenger.of(context).showSnackBar(
          //   SnackBar(
          //     content: Row(
          //       children: [
          //         Icon(Icons.check_circle_outlined, color: Colors.green),
          //         SizedBox(width: 8),
          //         Text(S.current.weatherDataAddedSuccessfully), // Use sua string traduzida
          //       ],
          //     ),
          //   ),
          // );
        }
      }
    } catch (error) {
      if (kDebugMode) {
        print('Error saving weather: $error');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outlined, color: Colors.red),
                const SizedBox(width: 8),
                Text(S.of(context).errorSavingWeather), // Use S.of(context)
              ],
            ),
          ),
        );
      }
    } finally {
      if (mounted && _isSubmitting) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

}