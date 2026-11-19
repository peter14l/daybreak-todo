import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import 'core/platform/platform_config.dart';
import 'core/services/service_locator.dart';
import 'ui/adaptive_app_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Core Services & Database
  await ServiceLocator.initialize(
    supabaseUrl: const String.fromEnvironment('SUPABASE_URL'),
    supabaseAnonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
  );

  if (isDesktop) {
    await windowManager.ensureInitialized();
    const windowOptions = WindowOptions(
      size: Size(1200, 780),
      minimumSize: Size(900, 600),
      center: true,
      title: 'Daybreak',
      titleBarStyle: TitleBarStyle.hidden,
      windowButtonVisibility: false,
    );
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.setTitleBarStyle(
        TitleBarStyle.hidden,
        windowButtonVisibility: false,
      );
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(
    const ProviderScope(
      child: DaybreakApp(),
    ),
  );
}

class DaybreakApp extends StatelessWidget {
  const DaybreakApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdaptiveAppShell();
  }
}
