import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_provider.dart';

class ThemeSwitcherDialog extends ConsumerWidget {
  const ThemeSwitcherDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (ctx) => const ThemeSwitcherDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(currentThemeProvider);
    final activeStyle = ref.watch(themeStyleProvider);

    return Dialog(
      backgroundColor: currentTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: currentTheme.borderRadius,
        side: BorderSide(color: currentTheme.borderColor, width: 1),
      ),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.palette_outlined,
                  color: currentTheme.accentColor,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Text(
                  'Select Theme Archetype',
                  style: TextStyle(
                    color: currentTheme.textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.close, color: currentTheme.textMutedColor),
                  onPressed: () => Navigator.of(context).pop(),
                  splashRadius: 18,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Switch seamlessly between native Windows 11 Mica, Material 3 Expressive, and high-density Linear Obsidian.',
              style: TextStyle(
                color: currentTheme.textMutedColor,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),

            // Option 1: Fluent Luxe
            _buildThemeOption(
              context: context,
              ref: ref,
              style: AppThemeStyle.fluentLuxe,
              currentTheme: currentTheme,
              isSelected: activeStyle == AppThemeStyle.fluentLuxe,
            ),
            const SizedBox(height: 10),

            // Option 2: Sunrise Warmth
            _buildThemeOption(
              context: context,
              ref: ref,
              style: AppThemeStyle.sunriseWarmth,
              currentTheme: currentTheme,
              isSelected: activeStyle == AppThemeStyle.sunriseWarmth,
            ),
            const SizedBox(height: 10),

            // Option 3: Linear Obsidian
            _buildThemeOption(
              context: context,
              ref: ref,
              style: AppThemeStyle.linearObsidian,
              currentTheme: currentTheme,
              isSelected: activeStyle == AppThemeStyle.linearObsidian,
            ),
            const SizedBox(height: 20),

            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: currentTheme.accentColor,
                  foregroundColor: const Color(0xFF121212),
                  shape: RoundedRectangleBorder(
                    borderRadius: currentTheme.borderRadius,
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Done',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption({
    required BuildContext context,
    required WidgetRef ref,
    required AppThemeStyle style,
    required DaybreakTheme currentTheme,
    required bool isSelected,
  }) {
    final theme = DaybreakTheme.fromStyle(style);

    return InkWell(
      onTap: () {
        ref.read(themeStyleProvider.notifier).setTheme(style);
      },
      borderRadius: theme.borderRadius,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.accentColor.withValues(alpha: 0.12)
              : currentTheme.surfaceHover,
          borderRadius: theme.borderRadius,
          border: Border.all(
            color: isSelected ? theme.accentColor : currentTheme.borderColor,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: theme.surface,
                borderRadius: theme.borderRadius,
                border: Border.all(color: theme.borderColor, width: 1),
              ),
              child: Icon(theme.icon, color: theme.accentColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        theme.displayName,
                        style: TextStyle(
                          color: currentTheme.textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.accentColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'ACTIVE',
                            style: TextStyle(
                              color: Color(0xFF121212),
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    theme.tagline,
                    style: TextStyle(
                      color: currentTheme.textMutedColor,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: isSelected
                  ? theme.accentColor
                  : currentTheme.textMutedColor.withValues(alpha: 0.5),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
