import 'package:flutter/services.dart';

class AudioFeedbackService {
  static bool soundEnabled = true;

  /// Plays a subtle, tactile click and haptic feedback when a task is completed
  static void playTaskCompletion() {
    try {
      HapticFeedback.mediumImpact();
      if (soundEnabled) {
        SystemSound.play(SystemSoundType.click);
      }
    } catch (_) {}
  }

  /// Celebratory haptic pulse when all tasks in My Day are finished
  static void playCelebration() {
    try {
      HapticFeedback.heavyImpact();
      Future.delayed(const Duration(milliseconds: 120), () {
        HapticFeedback.mediumImpact();
      });
      if (soundEnabled) {
        SystemSound.play(SystemSoundType.click);
      }
    } catch (_) {}
  }
}
