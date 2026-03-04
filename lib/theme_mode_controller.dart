import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global controller for handling theme mode changes across the app.
class ThemeModeController extends ChangeNotifier {
  ThemeModeController();

  static const _themeModeKey = 'app_theme_mode';

  ThemeMode _mode = ThemeMode.system;

  ThemeMode get mode => _mode;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final rawMode = prefs.getString(_themeModeKey);
    switch (rawMode) {
      case 'light':
        _mode = ThemeMode.light;
        break;
      case 'dark':
        _mode = ThemeMode.dark;
        break;
      default:
        _mode = ThemeMode.system;
        break;
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode.name);
  }

  void toggleLightDark() {
    setMode(_mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
  }
}

final ThemeModeController themeModeController = ThemeModeController();
