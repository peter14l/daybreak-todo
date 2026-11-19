import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/platform/platform_config.dart';
import '../core/state/providers.dart';
import '../core/theme/theme_provider.dart';
import 'desktop/desktop_app_shell.dart';
import 'mobile/mobile_app_shell.dart';
import 'onboarding/onboarding_screen.dart';

class AdaptiveAppShell extends ConsumerWidget {
  final bool? forceDesktop;

  const AdaptiveAppShell({super.key, this.forceDesktop});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingCompleted = ref.watch(onboardingNotifierProvider);
    final theme = ref.watch(currentThemeProvider);

    // Initial storage check
    if (onboardingCompleted == null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: theme.toMaterialTheme(),
        home: Scaffold(
          backgroundColor: theme.scaffoldBackground,
          body: Center(
            child: Icon(
              Icons.wb_sunny_rounded,
              size: 48,
              color: theme.accentColor,
            ),
          ),
        ),
      );
    }

    // First-run onboarding & sign in
    if (onboardingCompleted == false) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: theme.toMaterialTheme(),
        home: const OnboardingScreen(),
      );
    }

    // Main App Shell
    final useDesktop = forceDesktop ?? isDesktop;
    if (useDesktop) {
      return const DesktopAppShell();
    }
    return const MobileAppShell();
  }
}
