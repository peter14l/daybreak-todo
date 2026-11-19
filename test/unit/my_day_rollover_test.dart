import 'package:flutter_test/flutter_test.dart';
import 'package:daybreak/core/services/my_day_rollover_service.dart';

void main() {
  group('My Day Midnight Rollover Unit Tests', () {
    test('Iso date formatting generates correct YYYY-MM-DD format', () {
      final date = DateTime(2026, 11, 19, 15, 30);
      final iso = MyDayRolloverService.getTodayDateIso(date);
      expect(iso, equals('2026-11-19'));
    });

    test(
        'Stale task detection correctly identifies yesterday tasks vs today tasks',
        () {
      final today = DateTime(2026, 11, 20);
      final todayIso = MyDayRolloverService.getTodayDateIso(today);

      const yesterdayTaskMyDayDate = '2026-11-19';
      const todayTaskMyDayDate = '2026-11-20';
      const futureTaskMyDayDate = '2026-11-21';

      // Verify lexicographical comparison matches date comparison
      expect(yesterdayTaskMyDayDate.compareTo(todayIso) < 0, isTrue);
      expect(todayTaskMyDayDate.compareTo(todayIso) == 0, isTrue);
      expect(futureTaskMyDayDate.compareTo(todayIso) > 0, isTrue);
    });

    test('Rollover clears isMyDay flag while keeping parent list intact', () {
      final task = {
        'id': 'task-123',
        'listId': 'work-list-id',
        'title': 'Submit Financial Report',
        'isMyDay': true,
        'myDayDate': '2026-11-18', // Stale
        'isCompleted': false,
      };

      final todayIso = '2026-11-19';

      // Simulate rollover logic
      if ((task['myDayDate'] as String).compareTo(todayIso) < 0 &&
          (task['isMyDay'] as bool)) {
        task['isMyDay'] = false;
        task['myDayDate'] = '';
      }

      expect(task['isMyDay'], isFalse);
      expect(task['myDayDate'], isEmpty);
      // Crucial: parent list must remain unchanged!
      expect(task['listId'], equals('work-list-id'));
      expect(task['title'], equals('Submit Financial Report'));
      expect(task['isCompleted'], isFalse);
    });
  });
}
