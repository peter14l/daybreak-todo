class RecurrenceHelper {
  /// Calculates the next occurrence based on [currentDueDate] and [rule].
  /// Supported rules: 'daily', 'weekdays', 'weekly', 'monthly', 'yearly'.
  static DateTime getNextOccurrence(DateTime currentDueDate, String rule) {
    final lowerRule = rule.toLowerCase().trim();
    switch (lowerRule) {
      case 'daily':
        return currentDueDate.add(const Duration(days: 1));

      case 'weekdays':
        DateTime next = currentDueDate.add(const Duration(days: 1));
        while (next.weekday == DateTime.saturday ||
            next.weekday == DateTime.sunday) {
          next = next.add(const Duration(days: 1));
        }
        return next;

      case 'weekly':
        return currentDueDate.add(const Duration(days: 7));

      case 'monthly':
        return _addMonths(currentDueDate, 1);

      case 'yearly':
        return _addYears(currentDueDate, 1);

      default:
        return currentDueDate.add(const Duration(days: 1));
    }
  }

  /// Adds [months] to [date], clamping to the last valid day of the target month
  /// (e.g. Jan 31 + 1 month -> Feb 28 or Feb 29 in leap year).
  static DateTime _addMonths(DateTime date, int months) {
    int newYear = date.year;
    int newMonth = date.month + months;
    while (newMonth > 12) {
      newYear++;
      newMonth -= 12;
    }
    while (newMonth < 1) {
      newYear--;
      newMonth += 12;
    }

    final maxDaysInNewMonth = _daysInMonth(newYear, newMonth);
    final newDay = date.day > maxDaysInNewMonth ? maxDaysInNewMonth : date.day;

    return DateTime(
      newYear,
      newMonth,
      newDay,
      date.hour,
      date.minute,
      date.second,
      date.millisecond,
    );
  }

  static DateTime _addYears(DateTime date, int years) {
    final newYear = date.year + years;
    final maxDays = _daysInMonth(newYear, date.month);
    final newDay = date.day > maxDays ? maxDays : date.day;

    return DateTime(
      newYear,
      date.month,
      newDay,
      date.hour,
      date.minute,
      date.second,
      date.millisecond,
    );
  }

  static int _daysInMonth(int year, int month) {
    if (month == 2) {
      final isLeapYear =
          (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
      return isLeapYear ? 29 : 28;
    }
    const days = [31, -1, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    return days[month - 1];
  }
}
