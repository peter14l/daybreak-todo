import 'package:daybreak/core/theme/app_theme.dart';
import 'package:daybreak/core/theme/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Daybreak Theme Engine Tests', () {
    test('All 3 design archetypes are defined and have distinct properties',
        () {
      final fluent = DaybreakTheme.fromStyle(AppThemeStyle.fluentLuxe);
      final sunrise = DaybreakTheme.fromStyle(AppThemeStyle.sunriseWarmth);
      final linear = DaybreakTheme.fromStyle(AppThemeStyle.linearObsidian);

      expect(fluent.displayName, 'Fluent Luxe');
      expect(fluent.isTranslucent, isTrue);
      expect(fluent.borderRadius.topLeft.x, 8.0);

      expect(sunrise.displayName, 'Sunrise Warmth');
      expect(sunrise.isTranslucent, isFalse);
      expect(sunrise.borderRadius.topLeft.x, 18.0);

      expect(linear.displayName, 'Linear Obsidian');
      expect(linear.isTranslucent, isFalse);
      expect(linear.borderRadius.topLeft.x, 6.0);
    });

    test('Each archetype generates valid Material and Fluent themes', () {
      for (final style in AppThemeStyle.values) {
        final theme = DaybreakTheme.fromStyle(style);
        final material = theme.toMaterialTheme();
        final fluent = theme.toFluentTheme();

        expect(material.brightness, Brightness.dark);
        expect(material.cardTheme.color, theme.surface);
        expect(fluent.brightness, isNotNull);
      }
    });

    test('ThemeNotifier cycles through all 3 themes', () {
      final notifier = ThemeNotifier();
      expect(notifier.state, AppThemeStyle.fluentLuxe);

      notifier.cycleNext();
      expect(notifier.state, AppThemeStyle.sunriseWarmth);

      notifier.cycleNext();
      expect(notifier.state, AppThemeStyle.linearObsidian);

      notifier.cycleNext();
      expect(notifier.state, AppThemeStyle.fluentLuxe);
    });
  });
}
