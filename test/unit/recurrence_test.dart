import 'package:flutter_test/flutter_test.dart';
import 'package:daybreak/core/services/recurrence_helper.dart';

void main() {
  group('Recurrence Edge Cases Tests', () {
    test('Daily recurrence advances by exactly one day', () {
      final base = DateTime(2026, 11, 19);
      final next = RecurrenceHelper.getNextOccurrence(base, 'daily');
      expect(next, equals(DateTime(2026, 11, 20)));
    });

    test('Weekday recurrence advances Monday through Thursday to next day', () {
      final monday = DateTime(2026, 11, 16); // Monday
      final next = RecurrenceHelper.getNextOccurrence(monday, 'weekdays');
      expect(next.weekday, equals(DateTime.tuesday));
      expect(next, equals(DateTime(2026, 11, 17)));
    });

    test('Weekday recurrence rolls Friday over the weekend to Monday', () {
      final friday = DateTime(2026, 11, 20); // Friday
      expect(friday.weekday, equals(DateTime.friday));

      final next = RecurrenceHelper.getNextOccurrence(friday, 'weekdays');
      expect(next.weekday, equals(DateTime.monday));
      expect(next, equals(DateTime(2026, 11, 23)));
    });

    test('Month-end rollover: Jan 31 to Feb 28 in common year (2026)', () {
      final jan31 = DateTime(2026, 1, 31);
      final next = RecurrenceHelper.getNextOccurrence(jan31, 'monthly');
      expect(next.year, equals(2026));
      expect(next.month, equals(2));
      expect(next.day, equals(28));
    });

    test('Month-end rollover: Jan 31 to Feb 29 in leap year (2028)', () {
      final jan31Leap = DateTime(2028, 1, 31);
      final next = RecurrenceHelper.getNextOccurrence(jan31Leap, 'monthly');
      expect(next.year, equals(2028));
      expect(next.month, equals(2));
      expect(next.day, equals(29));
    });

    test('Month-end rollover: Mar 31 to Apr 30 (30-day month)', () {
      final mar31 = DateTime(2026, 3, 31);
      final next = RecurrenceHelper.getNextOccurrence(mar31, 'monthly');
      expect(next.year, equals(2026));
      expect(next.month, equals(4));
      expect(next.day, equals(30));
    });

    test('Year-end rollover: Dec 15 to Jan 15 of next year', () {
      final dec15 = DateTime(2026, 12, 15);
      final next = RecurrenceHelper.getNextOccurrence(dec15, 'monthly');
      expect(next.year, equals(2027));
      expect(next.month, equals(1));
      expect(next.day, equals(15));
    });

    test('Yearly leap year recurrence: Feb 29, 2028 to Feb 28, 2029', () {
      final leapDay = DateTime(2028, 2, 29);
      final next = RecurrenceHelper.getNextOccurrence(leapDay, 'yearly');
      expect(next.year, equals(2029));
      expect(next.month, equals(2));
      expect(next.day, equals(28));
    });
  });
}
