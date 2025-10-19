import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CacheProvider extends ChangeNotifier {
  SharedPreferences? _prefs;

  Future<void> initPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    debugPrint('CacheProvider: SharedPreferences initialized');
  }

  Future<void> setString(String key, String value) async {
    await initPrefs();
    await _prefs?.setString(key, value);
    debugPrint('CacheProvider: Set string for key $key with value $value');
    notifyListeners();
  }

  Future<String?> getString(String key) async {
    await initPrefs();
    debugPrint('CacheProvider: Retrieved string for key $key');
    return _prefs?.getString(key);
  }

  Future<void> setBool(String key, bool value) async {
    await initPrefs();
    _prefs?.setBool(key, value);
    notifyListeners();
  }

  Future<bool?> getBool(String key) async {
    await initPrefs();
    return _prefs?.getBool(key);
  }

  Future<void> remove(String key) async {
    await initPrefs();
    await _prefs?.remove(key);
    debugPrint('CacheProvider: Removed string for key $key');
    notifyListeners();
  }
}
