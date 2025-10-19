import 'package:flutter/material.dart';
import 'package:remote_mouse/providers/cache_provider.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  final CacheProvider _cacheProvider;
  ThemeProvider(this._cacheProvider);
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  Future<void> loadThemeData() async {
    await _cacheProvider.initPrefs();
    final mode = await _cacheProvider.getString("theme") ?? "light";
    final theme = mode == ThemeMode.dark.name
        ? ThemeMode.dark
        : mode == ThemeMode.light.name
        ? ThemeMode.light
        : ThemeMode.system;
    setThemeMode(theme);
  }

  void setThemeMode(ThemeMode mode) {
    if (_themeMode != mode) {
      _themeMode = mode;
      _cacheProvider.setString('theme', mode.name);
      notifyListeners();
    }
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      appBarTheme: AppBarTheme(
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        elevation: 0,
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.grey,
        brightness: Brightness.light,
      ),
    );
  }

  // Dark theme colors
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      appBarTheme: AppBarTheme(
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        elevation: 0,
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.black,
        brightness: Brightness.dark,
      ),
    );
  }
}
