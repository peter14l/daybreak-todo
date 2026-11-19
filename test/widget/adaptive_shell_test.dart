import 'package:flutter/material.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:daybreak/ui/adaptive_app_shell.dart';
import 'package:daybreak/core/state/providers.dart';

void main() {
  group('Adaptive App Shell Rendering Tests', () {
    testWidgets('Renders Material 3 NavigationBar when running in mobile mode',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeTasksStreamProvider.overrideWith((ref) => Stream.value([])),
            allListsStreamProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: const AdaptiveAppShell(forceDesktop: false),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Android M3E NavigationBar is rendered
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('My Day'), findsOneWidget);
      expect(find.text('Important'), findsOneWidget);
      expect(find.text('Planned'), findsOneWidget);
      expect(find.text('All Tasks'), findsOneWidget);
    });

    testWidgets('Renders Fluent NavigationView when running in desktop mode',
        (tester) async {
      // In headless test, set larger desktop surface size
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeTasksStreamProvider.overrideWith((ref) => Stream.value([])),
            allListsStreamProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: const AdaptiveAppShell(forceDesktop: true),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Windows Fluent NavigationView is rendered
      expect(find.byType(fluent.NavigationView), findsOneWidget);
      expect(find.text('Daybreak'), findsOneWidget);
    });
  });
}
