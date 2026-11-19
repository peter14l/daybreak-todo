import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/app_database.dart';
import '../services/service_locator.dart';
import '../services/task_service.dart';
import '../services/my_day_rollover_service.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  return ServiceLocator.database;
});

final taskServiceProvider = Provider<TaskService>((ref) {
  return ServiceLocator.taskService;
});

final activeViewIdProvider = StateProvider<String>((ref) => 'my-day');

final searchQueryProvider = StateProvider<String>((ref) => '');

final isCompactGlanceProvider = StateProvider<bool>((ref) => false);

/// Stream provider for all task lists
final allListsStreamProvider = StreamProvider<List<TaskList>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.taskListDao.watchAllLists();
});

/// Stream provider for active tasks based on activeViewId
final activeTasksStreamProvider = StreamProvider<List<Task>>((ref) {
  final db = ref.watch(databaseProvider);
  final activeView = ref.watch(activeViewIdProvider);
  final todayIso = MyDayRolloverService.getTodayDateIso();

  switch (activeView) {
    case 'my-day':
      return db.taskDao.watchMyDayTasks(todayIso);
    case 'important':
      return db.taskDao.watchImportantTasks();
    case 'planned':
      return db.taskDao.watchPlannedTasks();
    case 'all':
      return db.taskDao.watchAllActiveTasks();
    default:
      return db.taskDao.watchTasksByList(activeView);
  }
});
