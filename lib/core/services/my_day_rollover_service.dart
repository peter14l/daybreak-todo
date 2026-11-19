import 'package:intl/intl.dart';
import '../db/app_database.dart';

class MyDayRolloverService {
  final AppDatabase database;

  MyDayRolloverService(this.database);

  static String getTodayDateIso([DateTime? now]) {
    return DateFormat('yyyy-MM-dd').format(now ?? DateTime.now());
  }

  /// Checks for any tasks marked as My Day whose [myDayDate] is earlier than [todayDateIso].
  /// Clears [isMyDay] and [myDayDate] on them while leaving them in their respective parent list.
  /// Returns the number of affected tasks.
  Future<int> performRolloverCheck([DateTime? now]) async {
    final today = getTodayDateIso(now);
    final updatedAt = (now ?? DateTime.now()).toUtc();
    return await database.taskDao.clearStaleMyDay(today, updatedAt);
  }
}
