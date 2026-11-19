import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';

import '../db/app_database.dart';
import '../platform/platform_config.dart';

class WidgetSyncPayload {
  final String dateString;
  final String greeting;
  final int totalTasks;
  final int completedTasks;
  final int progressPercent;
  final String topTaskTitle;
  final String tasksJson;

  WidgetSyncPayload({
    required this.dateString,
    required this.greeting,
    required this.totalTasks,
    required this.completedTasks,
    required this.progressPercent,
    required this.topTaskTitle,
    required this.tasksJson,
  });

  Map<String, dynamic> toMap() {
    return {
      'dateString': dateString,
      'greeting': greeting,
      'totalTasks': totalTasks,
      'completedTasks': completedTasks,
      'progressPercent': progressPercent,
      'topTaskTitle': topTaskTitle,
      'tasksJson': tasksJson,
    };
  }
}

class WidgetSyncService {
  static const String appWidgetGroupId = 'group.com.daybreak.daybreak';
  static const String androidWidgetMyDay = 'MyDayWidgetProvider';
  static const String androidWidgetFocus = 'FocusWidgetProvider';

  /// Generates the payload data from a list of tasks.
  static WidgetSyncPayload generatePayload(List<Task> myDayTasks,
      {DateTime? now}) {
    final current = now ?? DateTime.now();
    final dateString = DateFormat('EEEE, MMM d').format(current);

    final hour = current.hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Good morning';
    } else if (hour < 17) {
      greeting = 'Good afternoon';
    } else {
      greeting = 'Good evening';
    }

    final totalTasks = myDayTasks.length;
    final completedTasks = myDayTasks.where((t) => t.isCompleted).length;
    final progressPercent =
        totalTasks == 0 ? 0 : ((completedTasks / totalTasks) * 100).round();

    // Find next uncompleted task (or first task if all completed or empty)
    String topTaskTitle = '';
    final incompleteTasks = myDayTasks.where((t) => !t.isCompleted).toList();
    if (incompleteTasks.isNotEmpty) {
      // Prioritize important tasks first
      incompleteTasks.sort((a, b) {
        if (a.isImportant && !b.isImportant) return -1;
        if (!a.isImportant && b.isImportant) return 1;
        return a.sortOrder.compareTo(b.sortOrder);
      });
      topTaskTitle = incompleteTasks.first.title;
    } else if (totalTasks > 0) {
      topTaskTitle = 'All tasks completed! 🎉';
    } else {
      topTaskTitle = 'No tasks in My Day yet';
    }

    // Serialize tasks list to JSON for custom list rendering
    final tasksListJson = jsonEncode(
      myDayTasks
          .map((t) => {
                'id': t.id,
                'title': t.title,
                'isCompleted': t.isCompleted,
                'isImportant': t.isImportant,
              })
          .toList(),
    );

    return WidgetSyncPayload(
      dateString: dateString,
      greeting: greeting,
      totalTasks: totalTasks,
      completedTasks: completedTasks,
      progressPercent: progressPercent,
      topTaskTitle: topTaskTitle,
      tasksJson: tasksListJson,
    );
  }

  /// Pushes the latest My Day tasks to home_widget on Android.
  static Future<void> syncWidgets(List<Task> myDayTasks) async {
    if (!isAndroid) return;

    try {
      final payload = generatePayload(myDayTasks);

      await HomeWidget.saveWidgetData<String>(
          'daybreak_date', payload.dateString);
      await HomeWidget.saveWidgetData<String>(
          'daybreak_greeting', payload.greeting);
      await HomeWidget.saveWidgetData<int>(
          'daybreak_total_count', payload.totalTasks);
      await HomeWidget.saveWidgetData<int>(
          'daybreak_completed_count', payload.completedTasks);
      await HomeWidget.saveWidgetData<int>(
          'daybreak_progress_pct', payload.progressPercent);
      await HomeWidget.saveWidgetData<String>(
          'daybreak_top_task', payload.topTaskTitle);
      await HomeWidget.saveWidgetData<String>(
          'daybreak_tasks_json', payload.tasksJson);

      await HomeWidget.updateWidget(
        name: androidWidgetMyDay,
        androidName: androidWidgetMyDay,
        qualifiedAndroidName: 'com.daybreak.daybreak.MyDayWidgetProvider',
      );

      await HomeWidget.updateWidget(
        name: androidWidgetFocus,
        androidName: androidWidgetFocus,
        qualifiedAndroidName: 'com.daybreak.daybreak.FocusWidgetProvider',
      );

      // Feature 4: Update Android Sticky Notification Shade Glance
      try {
        const glanceChannel =
            MethodChannel('com.daybreak.daybreak/notification_glance');
        final remaining = payload.totalTasks - payload.completedTasks;
        await glanceChannel.invokeMethod('updateGlance', {
          'title': '${payload.greeting} • Daybreak 🌅',
          'content': remaining > 0
              ? '$remaining remaining today • Next: ${payload.topTaskTitle}'
              : 'All clear! Every task finished for today 🎉',
          'count': remaining,
        });
      } catch (_) {}
    } catch (_) {
      // Gracefully ignore widget sync errors on unsupported platforms or during tests
    }
  }
}
