import 'package:flutter_test/flutter_test.dart';
import 'package:daybreak/core/services/natural_language_parser.dart';

void main() {
  group('NaturalLanguageParser Tests', () {
    test('parses plain task with no tokens', () {
      final res = NaturalLanguageParser.parse('Buy organic milk');
      expect(res.cleanTitle, 'Buy organic milk');
      expect(res.dueDate, isNull);
      expect(res.reminderAt, isNull);
      expect(res.isImportant, isFalse);
      expect(res.tags, isEmpty);
    });

    test('parses !important and tags', () {
      final res = NaturalLanguageParser.parse(
          'Prepare slide deck !important #work #finance');
      expect(res.cleanTitle, 'Prepare slide deck');
      expect(res.isImportant, isTrue);
      expect(res.tags, containsAll(['work', 'finance']));
    });

    test('parses tomorrow with time', () {
      final res =
          NaturalLanguageParser.parse('Dentist appointment tomorrow at 4pm');
      expect(res.cleanTitle, 'Dentist appointment');
      expect(res.dueDate, isNotNull);
      expect(res.dueDate!.hour, 16);
      expect(res.dueDate!.minute, 0);
      expect(res.reminderAt, isNotNull);
    });

    test('parses today with time', () {
      final res =
          NaturalLanguageParser.parse('Submit report today at 5:30pm !imp');
      expect(res.cleanTitle, 'Submit report');
      expect(res.isImportant, isTrue);
      expect(res.dueDate, isNotNull);
      expect(res.dueDate!.hour, 17);
      expect(res.dueDate!.minute, 30);
    });

    test('parses empty or whitespace input gracefully', () {
      final res = NaturalLanguageParser.parse('   ');
      expect(res.cleanTitle, '');
      expect(res.dueDate, isNull);
      expect(res.isImportant, isFalse);
    });
  });
}
