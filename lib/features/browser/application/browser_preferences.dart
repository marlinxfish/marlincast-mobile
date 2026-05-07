import 'package:shared_preferences/shared_preferences.dart';

class BrowserPreferences {
  static const _darkModeKey = 'browser_dark_mode_enabled';

  Future<bool?> loadDarkModeEnabled() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_darkModeKey);
  }

  Future<void> saveDarkModeEnabled(bool enabled) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_darkModeKey, enabled);
  }
}
