import 'package:flutter/material.dart';
import 'package:remote_mouse/providers/cache_provider.dart';

class SettingsProvider extends ChangeNotifier {
  final CacheProvider _cacheProvider;

  bool _hapticFeedback = true;
  bool _verticalScrolling = true;
  bool _horizontalScrolling = true;
  double _scrollSensitivity = 0.5;
  double _mouseSensitivity = 1.0;

  bool get hapticFeedback => _hapticFeedback;
  bool get verticalScrolling => _verticalScrolling;
  bool get horizontalScrolling => _horizontalScrolling;
  double get scrollSensitivity => _scrollSensitivity;
  double get mouseSensitivity => _mouseSensitivity;

  SettingsProvider(this._cacheProvider);

  Future<void> loadPreferences() async {
    await _cacheProvider.initPrefs();

    _hapticFeedback =
        (await _cacheProvider.getString('hapticFeedback')) == 'true';
    _verticalScrolling =
        (await _cacheProvider.getString('verticalScrolling')) == 'true';
    _horizontalScrolling =
        (await _cacheProvider.getString('horizontalScrolling')) == 'true';
    _scrollSensitivity =
        double.tryParse(
          await _cacheProvider.getString('scrollSensitivity') ?? '0.5',
        ) ??
        0.5;
    _mouseSensitivity =
        double.tryParse(
          await _cacheProvider.getString('mouseSensitivity') ?? '1.0',
        ) ??
        1.0;

    notifyListeners();
  }

  // Setters that update state and persist to cache
  void setHapticFeedback(bool value) {
    _hapticFeedback = value;
    _cacheProvider.setString('hapticFeedback', value.toString());
    notifyListeners();
  }

  void setVerticalScrolling(bool value) async {
    _verticalScrolling = value;
    await _cacheProvider.setString('verticalScrolling', value.toString());
    notifyListeners();
  }

  void setHorizontalScrolling(bool value) async {
    _horizontalScrolling = value;
    await _cacheProvider.setString('horizontalScrolling', value.toString());
    notifyListeners();
  }

  void setScrollSensitivity(double value) async {
    _scrollSensitivity = value;
    await _cacheProvider.setString('scrollSensitivity', value.toString());
    notifyListeners();
  }

  void setMouseSensitivity(double value) async {
    _mouseSensitivity = value;
    await _cacheProvider.setString('mouseSensitivity', value.toString());
    notifyListeners();
  }
}
