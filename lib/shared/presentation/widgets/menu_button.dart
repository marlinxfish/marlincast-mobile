import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class MenuButton extends StatelessWidget {
  const MenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return IconButton.filledTonal(
      tooltip: 'Buka menu',
      onPressed: () => Scaffold.of(context).openDrawer(),
      icon: Icon(LucideIcons.menu, color: colorScheme.primary),
    );
  }
}
