import 'package:flutter/material.dart';

import '../core/platform/platform_config.dart';
import 'desktop/desktop_app_shell.dart';
import 'mobile/mobile_app_shell.dart';

class AdaptiveAppShell extends StatelessWidget {
  final bool? forceDesktop;

  const AdaptiveAppShell({super.key, this.forceDesktop});

  @override
  Widget build(BuildContext context) {
    final useDesktop = forceDesktop ?? isDesktop;
    if (useDesktop) {
      return const DesktopAppShell();
    }
    return const MobileAppShell();
  }
}
