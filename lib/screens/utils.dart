import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ThemeMode> getThemeMode() async {
  final prefs = await SharedPreferences.getInstance();
  final themeModeIndex = prefs.getInt('themeMode') ?? 0; // 0 é o valor padrão para ThemeMode.system
  return ThemeMode.values[themeModeIndex];
}