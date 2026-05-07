import 'package:flutter/widgets.dart';

import 'marlin_theme.dart';

class ThemeController extends ChangeNotifier {
  ThemeController({MarlinThemeMode initialMode = MarlinThemeMode.light})
    : _mode = initialMode;

  MarlinThemeMode _mode;

  MarlinThemeMode get mode => _mode;

  void setMode(MarlinThemeMode mode) {
    if (_mode == mode) {
      return;
    }

    _mode = mode;
    notifyListeners();
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
