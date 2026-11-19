import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'app_theme.dart';

const _themeStorageKey = 'daybreak_selected_theme_style';
const _storage = FlutterSecureStorage();

class ThemeNotifier extends StateNotifier<AppThemeStyle> {
  ThemeNotifier() : super(AppThemeStyle.fluentLuxe) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final saved = await _storage.read(key: _themeStorageKey);
      if (saved != null) {
        final match = AppThemeStyle.values.firstWhere(
          (e) => e.name == saved,
          orElse: () => AppThemeStyle.fluentLuxe,
        );
        state = match;
      }
    } catch (_) {}
  }

  Future<void> setTheme(AppThemeStyle style) async {
    state = style;
    try {
      await _storage.write(key: _themeStorageKey, value: style.name);
    } catch (_) {}
  }

  void cycleNext() {
    const values = AppThemeStyle.values;
    final nextIdx = (values.indexOf(state) + 1) % values.length;
    setTheme(values[nextIdx]);
  }
}

final themeStyleProvider =
    StateNotifierProvider<ThemeNotifier, AppThemeStyle>((ref) {
  return ThemeNotifier();
});

final currentThemeProvider = Provider<DaybreakTheme>((ref) {
  final style = ref.watch(themeStyleProvider);
  return DaybreakTheme.fromStyle(style);
});
