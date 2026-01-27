import 'package:flutter/services.dart';

class AppHaptics {
  /// Light impact for minor actions (e.g., swiping cards, toggling switches)
  static void light() {
    HapticFeedback.lightImpact();
  }

  /// Medium impact for successful actions (e.g., sending a message, starting a task)
  static void medium() {
    HapticFeedback.mediumImpact();
  }

  /// Heavy impact for major events (e.g., A MATCH!, Task Completed)
  static void heavy() {
    HapticFeedback.heavyImpact();
  }

  /// Distinctive vibrating pattern for alerts/notifications
  static void alert() {
    HapticFeedback.vibrate();
  }

  /// Double tap feel for selection
  static void selection() {
    HapticFeedback.selectionClick();
  }
}
