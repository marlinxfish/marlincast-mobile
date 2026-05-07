import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'marlin_theme.dart';

class ThemeController extends ChangeNotifier {
  ThemeController({MarlinThemeMode initialMode = MarlinThemeMode.light})
    : _mode = initialMode;

  static const _storageKey = 'theme_mode';

  MarlinThemeMode _mode;

  MarlinThemeMode get mode => _mode;

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    final storedMode = preferences.getString(_storageKey);
    final mode = MarlinThemeMode.values.where((value) {
      return value.name == storedMode;
    }).firstOrNull;

    if (mode != null && mode != _mode) {
      _mode = mode;
      notifyListeners();
    }
  }

  Future<void> setMode(MarlinThemeMode mode) async {
    if (_mode == mode) {
      return;
    }

    _mode = mode;
    notifyListeners();

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_storageKey, mode.name);
  }
}

class ThemeScope extends InheritedNotifier<ThemeController> {
  const ThemeScope({
    super.key,
    required ThemeController controller,
    required super.child,
  }) : super(notifier: controller);

  static ThemeController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ThemeScope>();
    assert(scope != null, 'ThemeScope not found');
    return scope!.notifier!;
  }
}
