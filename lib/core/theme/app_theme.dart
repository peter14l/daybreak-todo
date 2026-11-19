import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter/material.dart';

enum AppThemeStyle {
  fluentLuxe,
  sunriseWarmth,
  linearObsidian,
}

class DaybreakTheme {
  final AppThemeStyle style;
  final String displayName;
  final String tagline;
  final IconData icon;
  final Color scaffoldBackground;
  final Color sidebarBackground;
  final Color surface;
  final Color surfaceHover;
  final Color surfaceCompleted;
  final Color borderColor;
  final BorderRadius borderRadius;
  final Color accentColor;
  final Color textColor;
  final Color textMutedColor;
  final Color quickAddBackground;
  final BorderRadius quickAddBorderRadius;
  final BorderRadius checkboxBorderRadius;
  final Color checkboxBorderColor;
  final bool isTranslucent;

  const DaybreakTheme({
    required this.style,
    required this.displayName,
    required this.tagline,
    required this.icon,
    required this.scaffoldBackground,
    required this.sidebarBackground,
    required this.surface,
    required this.surfaceHover,
    required this.surfaceCompleted,
    required this.borderColor,
    required this.borderRadius,
    required this.accentColor,
    required this.textColor,
    required this.textMutedColor,
    required this.quickAddBackground,
    required this.quickAddBorderRadius,
    required this.checkboxBorderRadius,
    required this.checkboxBorderColor,
    this.isTranslucent = false,
  });

  /// Windows 11 Fluent Luxe (Mica Alt depth, subtle 1px hairline borders, refined slate cards)
  static final DaybreakTheme fluentLuxe = DaybreakTheme(
    style: AppThemeStyle.fluentLuxe,
    displayName: 'Fluent Luxe',
    tagline: 'Windows 11 Mica Alt with refined slate cards',
    icon: Icons.diamond_outlined,
    scaffoldBackground: const Color(0xFF18181B),
    sidebarBackground: const Color(0xD9161619),
    surface: const Color(0xB324242A),
    surfaceHover: const Color(0xE62D2D35),
    surfaceCompleted: const Color(0x661C1C20),
    borderColor: const Color(0x14FFFFFF),
    borderRadius: BorderRadius.circular(8),
    accentColor: const Color(0xFFFFA726),
    textColor: const Color(0xFFF4F4F5),
    textMutedColor: const Color(0xFFA1A1AA),
    quickAddBackground: const Color(0xE6202026),
    quickAddBorderRadius: BorderRadius.circular(8),
    checkboxBorderRadius: BorderRadius.circular(10),
    checkboxBorderColor: const Color(0x59FFFFFF),
    isTranslucent: true,
  );

  /// Sunrise Warmth (Material 3 Expressive, warm espresso and radiant dawn amber)
  static final DaybreakTheme sunriseWarmth = DaybreakTheme(
    style: AppThemeStyle.sunriseWarmth,
    displayName: 'Sunrise Warmth',
    tagline: 'Warm espresso and radiant dawn amber squircles',
    icon: Icons.wb_sunny_outlined,
    scaffoldBackground: const Color(0xFF17131B),
    sidebarBackground: const Color(0xFF1D1723),
    surface: const Color(0xFF251E2C),
    surfaceHover: const Color(0xFF2F2639),
    surfaceCompleted: const Color(0x80251E2C),
    borderColor: const Color(0x1FFFBA4D),
    borderRadius: BorderRadius.circular(18),
    accentColor: const Color(0xFFFFB74D),
    textColor: const Color(0xFFFCEEE8),
    textMutedColor: const Color(0xFFAB9FAE),
    quickAddBackground: const Color(0xFF251E2C),
    quickAddBorderRadius: BorderRadius.circular(26),
    checkboxBorderRadius: BorderRadius.circular(12),
    checkboxBorderColor: const Color(0xFFFFB74D),
    isTranslucent: false,
  );

  /// Linear Obsidian (High-density matte obsidian with keyboard-centric clarity)
  static final DaybreakTheme linearObsidian = DaybreakTheme(
    style: AppThemeStyle.linearObsidian,
    displayName: 'Linear Obsidian',
    tagline: 'Ultra-compact obsidian matte with high-density precision',
    icon: Icons.bolt_outlined,
    scaffoldBackground: const Color(0xFF090A0D),
    sidebarBackground: const Color(0xFF0D0E12),
    surface: const Color(0xFF12141A),
    surfaceHover: const Color(0xFF181B23),
    surfaceCompleted: const Color(0x5012141A),
    borderColor: const Color(0xFF1E2029),
    borderRadius: BorderRadius.circular(6),
    accentColor: const Color(0xFFFFA726),
    textColor: const Color(0xFFEDEDED),
    textMutedColor: const Color(0xFF71717A),
    quickAddBackground: const Color(0xFF0D0E12),
    quickAddBorderRadius: BorderRadius.circular(6),
    checkboxBorderRadius: BorderRadius.circular(4),
    checkboxBorderColor: const Color(0xFF3F3F46),
    isTranslucent: false,
  );

  static DaybreakTheme fromStyle(AppThemeStyle style) {
    switch (style) {
      case AppThemeStyle.fluentLuxe:
        return fluentLuxe;
      case AppThemeStyle.sunriseWarmth:
        return sunriseWarmth;
      case AppThemeStyle.linearObsidian:
        return linearObsidian;
    }
  }

  /// Material ThemeData matching this theme
  ThemeData toMaterialTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: scaffoldBackground,
      colorScheme: ColorScheme.dark(
        primary: accentColor,
        onPrimary: const Color(0xFF121212),
        surface: surface,
        onSurface: textColor,
        onSurfaceVariant: textMutedColor,
        outline: borderColor,
        outlineVariant: borderColor,
      ),
      cardTheme: CardTheme(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius,
          side: BorderSide(color: borderColor, width: 1),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: checkboxBorderRadius),
        side: BorderSide(color: checkboxBorderColor, width: 1.5),
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return accentColor;
          }
          return Colors.transparent;
        }),
        checkColor: const WidgetStatePropertyAll(Color(0xFF121212)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: TextStyle(color: textMutedColor, fontSize: 13),
      ),
      iconTheme: IconThemeData(color: textColor, size: 18),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: textColor, fontSize: 14),
        bodyMedium: TextStyle(color: textColor, fontSize: 13),
        bodySmall: TextStyle(color: textMutedColor, fontSize: 11),
        titleMedium: TextStyle(
          color: textColor,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// FluentThemeData matching this theme for Windows
  fluent.FluentThemeData toFluentTheme() {
    return fluent.FluentThemeData(
      brightness: fluent.Brightness.dark,
      accentColor: fluent.AccentColor.swatch({
        'darkest': const Color(0xFF8B4D00),
        'darker': const Color(0xFFB36200),
        'dark': const Color(0xFFCC7000),
        'normal': accentColor,
        'light': const Color(0xFFFFB74D),
        'lighter': const Color(0xFFFFCC80),
        'lightest': const Color(0xFFFFE0B2),
      }),
      scaffoldBackgroundColor:
          isTranslucent ? fluent.Colors.transparent : scaffoldBackground,
      navigationPaneTheme: fluent.NavigationPaneThemeData(
        backgroundColor:
            isTranslucent ? fluent.Colors.transparent : sidebarBackground,
      ),
    );
  }
}
