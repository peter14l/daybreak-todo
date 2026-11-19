import 'dart:io';
import 'package:flutter/foundation.dart';

bool get isDesktop {
  if (kIsWeb) return false;
  return Platform.isWindows || Platform.isMacOS || Platform.isLinux;
}

bool get isWindows => !kIsWeb && Platform.isWindows;
bool get isAndroid => !kIsWeb && Platform.isAndroid;
bool get isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);
