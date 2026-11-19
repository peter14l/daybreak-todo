import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:daybreak/core/services/widget_sync_service.dart';

void main() {
  group('Widget Data Serialization & Empty States Tests', () {
    test('Empty state handles 0 tasks gracefully with safe defaults', () {
      final payload = WidgetSyncPayload(
        dateString: 'Thursday, Nov 19',
        greeting: 'Good morning',
        totalTasks: 0,
        completedTasks: 0,
        progressPercent: 0,
        topTaskTitle: 'No tasks in My Day yet',
        tasksJson: '[]',
      );

      final map = payload.toMap();
      expect(map['totalTasks'], equals(0));
      expect(map['completedTasks'], equals(0));
      expect(map['progressPercent'], equals(0));
      expect(map['topTaskTitle'], equals('No tasks in My Day yet'));
      expect(jsonDecode(map['tasksJson'] as String), isEmpty);
    });

    test('Completed-only state reports 100% completion', () {
      final payload = WidgetSyncPayload(
        dateString: 'Thursday, Nov 19',
        greeting: 'Good evening',
        totalTasks: 3,
        completedTasks: 3,
        progressPercent: 100,
        topTaskTitle: 'All tasks completed! 🎉',
        tasksJson: jsonEncode([
          {'id': '1', 'title': 'Morning Run', 'isCompleted': true},
          {'id': '2', 'title': 'Design Review', 'isCompleted': true},
          {'id': '3', 'title': 'Send Invoices', 'isCompleted': true},
        ]),
      );

      final map = payload.toMap();
      expect(map['totalTasks'], equals(3));
      expect(map['completedTasks'], equals(3));
      expect(map['progressPercent'], equals(100));
      expect(map['topTaskTitle'], contains('All tasks completed!'));
      final decoded = jsonDecode(map['tasksJson'] as String) as List<dynamic>;
      expect(decoded.length, equals(3));
      expect(decoded.every((t) => t['isCompleted'] == true), isTrue);
    });

    test(
        'Complex Unicode, RTL, CJK, Emojis, and quotes serialize safely without crashing',
        () {
      const complexTitle =
          '🌅 Morning Focus: שלום עולם | 早上好 | 👨‍👩‍👧‍👦 "Special Quotes" & <Tags>';
      final tasks = [
        {
          'id': 'task-unicode',
          'title': complexTitle,
          'isCompleted': false,
          'isImportant': true,
        }
      ];

      final jsonStr = jsonEncode(tasks);
      final payload = WidgetSyncPayload(
        dateString: 'Thursday, Nov 19',
        greeting: 'Good afternoon',
        totalTasks: 1,
        completedTasks: 0,
        progressPercent: 0,
        topTaskTitle: complexTitle,
        tasksJson: jsonStr,
      );

      final map = payload.toMap();
      expect(map['topTaskTitle'], equals(complexTitle));

      // Verify deserialization is byte-exact
      final decoded = jsonDecode(map['tasksJson'] as String) as List<dynamic>;
      expect(decoded.first['title'], equals(complexTitle));
      expect(decoded.first['isImportant'], isTrue);
    });
  });
}
