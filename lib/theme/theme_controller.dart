import 'package:flutter/widgets.dart';

import 'marlin_theme.dart';

class ThemeController extends ChangeNotifier {
  ThemeController({MarlinThemePalette initialPalette = MarlinThemePalette.ocean})
    : _palette = initialPalette;

  MarlinThemePalette _palette;

  MarlinThemePalette get palette => _palette;

  void setPalette(MarlinThemePalette palette) {
    if (_palette == palette) {
      return;
    }

    _palette = palette;
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
