import '../../models/inventory.dart';
import '../daos/weather_dao.dart';

class WeatherRepository {
  final WeatherDao _weatherDao;

  WeatherRepository(this._weatherDao);

  Future<int?> insertWeather(Weather weather) {
    return _weatherDao.insertWeather(weather);
  }

  Future<void> updateWeather(Weather weather) {
    return _weatherDao.updateWeather(weather);
  }

  Future<void> deleteWeather(int? weatherId) {
    return _weatherDao.deleteWeather(weatherId);
  }

  Future<List<Weather>> getWeatherByInventory(String inventoryId) {
    return _weatherDao.getWeatherByInventory(inventoryId);
  }
}