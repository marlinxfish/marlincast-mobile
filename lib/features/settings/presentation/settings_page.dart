import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../shared/presentation/widgets/menu_button.dart';
import '../../../theme/marlin_theme.dart';
import '../../../theme/theme_controller.dart';
import '../../home/presentation/widgets/home_drawer.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = ThemeScope.of(context);

    return Scaffold(
      drawer: const HomeDrawer(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 20),
          child: AnimatedBuilder(
            animation: themeController,
            builder: (context, _) {
              return ListView(
                children: [
                  const MenuButton(),
                  const SizedBox(height: 18),
                  Text(
                    'Settings',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Atur tampilan aplikasi sesuai kebutuhan.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 22),
                  _ThemeSection(
                    selectedPalette: themeController.palette,
                    onChanged: themeController.setPalette,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ThemeSection extends StatelessWidget {
  const _ThemeSection({
    required this.selectedPalette,
    required this.onChanged,
  });

  final MarlinThemePalette selectedPalette;
  final ValueChanged<MarlinThemePalette> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.palette, color: colorScheme.primary, size: 20),
              const SizedBox(width: 10),
              Text(
                'Tema Warna',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final palette in MarlinThemePalette.values) ...[
            _ThemeOptionTile(
              palette: palette,
              selected: palette == selectedPalette,
              onTap: () => onChanged(palette),
            ),
            if (palette != MarlinThemePalette.values.last)
              const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _ThemeOptionTile extends StatelessWidget {
  const _ThemeOptionTile({
    required this.palette,
    required this.selected,
    required this.onTap,
  });

  final MarlinThemePalette palette;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = MarlinThemes.byPalette(palette);

    return Material(
      color: selected ? colorScheme.primaryContainer : colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _ThemeSwatch(theme: theme),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      palette.label,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      palette.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(LucideIcons.check, color: colorScheme.primary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeSwatch extends StatelessWidget {
  const _ThemeSwatch({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(child: ColoredBox(color: scheme.primary)),
          Expanded(child: ColoredBox(color: scheme.secondary)),
          Expanded(child: ColoredBox(color: scheme.tertiary)),
        ],
      ),
    );
  }
}
