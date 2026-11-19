class ParsedTaskInput {
  final String cleanTitle;
  final DateTime? dueDate;
  final DateTime? reminderAt;
  final bool isImportant;
  final List<String> tags;

  const ParsedTaskInput({
    required this.cleanTitle,
    this.dueDate,
    this.reminderAt,
    this.isImportant = false,
    this.tags = const [],
  });
}

class NaturalLanguageParser {
  static final RegExp _tagRegex = RegExp(r'#(\w+)', caseSensitive: false);
  static final RegExp _importantRegex = RegExp(
      r'(?:^|\s)(!important|!imp|\*important|\*)(?:\s|$)',
      caseSensitive: false);

  // Time regex: e.g. "at 5pm", "at 5:30pm", "at 17:00", "5pm", "5:30 pm"
  static final RegExp _timeRegex = RegExp(
    r'(?:\bat\s+)?(\d{1,2})(?::(\d{2}))?\s*(am|pm)?\b',
    caseSensitive: false,
  );

  static ParsedTaskInput parse(String raw) {
    if (raw.trim().isEmpty) {
      return const ParsedTaskInput(cleanTitle: '');
    }

    String text = raw;
    bool isImportant = false;
    DateTime? dueDate;
    DateTime? reminderAt;
    final tags = <String>[];

    // 1. Check importance
    if (_importantRegex.hasMatch(text)) {
      isImportant = true;
      text = text.replaceAll(_importantRegex, ' ');
    }

    // 2. Extract tags
    for (final match in _tagRegex.allMatches(text)) {
      final tag = match.group(1);
      if (tag != null && tag.isNotEmpty) {
        tags.add(tag.toLowerCase());
      }
    }
    text = text.replaceAll(_tagRegex, ' ');

    final now = DateTime.now();
    final lower = text.toLowerCase();

    // 3. Detect date keywords
    int? dayOffset;
    String? matchedDateToken;

    if (lower.contains('tomorrow') || lower.contains('tmrw')) {
      dayOffset = 1;
      matchedDateToken = lower.contains('tomorrow') ? 'tomorrow' : 'tmrw';
    } else if (lower.contains('today') || lower.contains('tonight')) {
      dayOffset = 0;
      matchedDateToken = lower.contains('today') ? 'today' : 'tonight';
    } else {
      // Check for weekdays: e.g., "next monday", "on friday"
      final weekdays = {
        'monday': DateTime.monday,
        'tuesday': DateTime.tuesday,
        'wednesday': DateTime.wednesday,
        'thursday': DateTime.thursday,
        'friday': DateTime.friday,
        'saturday': DateTime.saturday,
        'sunday': DateTime.sunday,
      };

      for (final entry in weekdays.entries) {
        final dayName = entry.key;
        final targetWeekday = entry.value;

        if (lower.contains('next $dayName')) {
          var diff = (targetWeekday - now.weekday + 7) % 7;
          if (diff == 0) diff = 7;
          diff += 7; // "next" next week
          dayOffset = diff;
          matchedDateToken = 'next $dayName';
          break;
        } else if (lower.contains('on $dayName') || lower.contains(dayName)) {
          var diff = (targetWeekday - now.weekday + 7) % 7;
          if (diff == 0) diff = 7;
          dayOffset = diff;
          matchedDateToken =
              lower.contains('on $dayName') ? 'on $dayName' : dayName;
          break;
        }
      }
    }

    // 4. Detect time keyword if date was found or standalone "at 5pm"
    int hour = 18; // Default 6:00 PM if date specified without time
    int minute = 0;
    bool hasSpecificTime = false;

    final timeMatch = _timeRegex.firstMatch(text);
    if (timeMatch != null &&
        (dayOffset != null ||
            timeMatch.group(3) != null ||
            text.contains('at '))) {
      final hourParsed = int.tryParse(timeMatch.group(1) ?? '');
      final minuteParsed = int.tryParse(timeMatch.group(2) ?? '0') ?? 0;
      final amPm = timeMatch.group(3)?.toLowerCase();

      if (hourParsed != null && hourParsed >= 1 && hourParsed <= 24) {
        hour = hourParsed;
        minute = minuteParsed;
        if (amPm == 'pm' && hour < 12) hour += 12;
        if (amPm == 'am' && hour == 12) hour = 0;
        hasSpecificTime = true;
        text = text.replaceFirst(timeMatch.group(0)!, ' ');
      }
    }

    if (matchedDateToken != null) {
      final reg = RegExp('\\b$matchedDateToken\\b', caseSensitive: false);
      text = text.replaceFirst(reg, ' ');
    }

    if (dayOffset != null) {
      final targetDate = now.add(Duration(days: dayOffset));
      dueDate = DateTime(
          targetDate.year, targetDate.month, targetDate.day, hour, minute);
      if (hasSpecificTime) {
        reminderAt = dueDate;
      }
    }

    // Clean up excess whitespace
    final cleanTitle = text.replaceAll(RegExp(r'\s+'), ' ').trim();

    return ParsedTaskInput(
      cleanTitle: cleanTitle.isEmpty ? raw.trim() : cleanTitle,
      dueDate: dueDate,
      reminderAt: reminderAt,
      isImportant: isImportant,
      tags: tags,
    );
  }
}
