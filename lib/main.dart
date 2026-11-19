import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import 'core/platform/platform_config.dart';
import 'core/services/service_locator.dart';
import 'ui/adaptive_app_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Core Services & Database with Supabase Sync
  const supabaseUrlEnv = String.fromEnvironment('SUPABASE_URL');
  const supabaseAnonKeyEnv = String.fromEnvironment('SUPABASE_ANON_KEY');

  await ServiceLocator.initialize(
    supabaseUrl: supabaseUrlEnv.isNotEmpty
        ? supabaseUrlEnv
        : 'https://zdpolpxaurqjfzvnzaet.supabase.co',
    supabaseAnonKey: supabaseAnonKeyEnv.isNotEmpty
        ? supabaseAnonKeyEnv
        : 'sb_publishable_eLtc2jgxiMuAy8rEi3xYcA_AltvRmTn',
  );

  if (isDesktop) {
    await windowManager.ensureInitialized();
    const windowOptions = WindowOptions(
      size: Size(1200, 780),
      minimumSize: Size(900, 600),
      center: true,
      title: 'Daybreak',
      titleBarStyle: TitleBarStyle.normal,
    );
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
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
