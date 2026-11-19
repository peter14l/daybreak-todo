import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../db/app_database.dart';
import '../services/auth_service.dart';
import '../services/service_locator.dart';
import '../services/task_service.dart';
import '../services/my_day_rollover_service.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  return ServiceLocator.database;
});

final taskServiceProvider = Provider<TaskService>((ref) {
  return ServiceLocator.taskService;
});

final authServiceProvider = Provider<AuthService>((ref) {
  return ServiceLocator.authService;
});

final currentUserProvider = StateProvider<User?>((ref) {
  return ServiceLocator.authService.currentUser;
});

final activeViewIdProvider = StateProvider<String>((ref) => 'my-day');

final searchQueryProvider = StateProvider<String>((ref) => '');

final isCompactGlanceProvider = StateProvider<bool>((ref) => false);

const _onboardingStorageKey = 'daybreak_onboarding_completed';

class OnboardingNotifier extends StateNotifier<bool?> {
  final _storage = const FlutterSecureStorage();

  OnboardingNotifier([bool? initial]) : super(initial) {
    if (initial == null) {
      _loadState();
    }
  }

  Future<void> _loadState() async {
    try {
      final value = await _storage.read(key: _onboardingStorageKey);
      state = value == 'true';
    } catch (_) {
      state = false;
    }
  }

  Future<void> completeOnboarding() async {
    state = true;
    try {
      await _storage.write(key: _onboardingStorageKey, value: 'true');
    } catch (_) {}
  }

  Future<void> resetOnboarding() async {
    state = false;
    try {
      await _storage.delete(key: _onboardingStorageKey);
    } catch (_) {}
  }
}

final onboardingNotifierProvider =
    StateNotifierProvider<OnboardingNotifier, bool?>((ref) {
  return OnboardingNotifier();
});

/// Selected task for the detail inspector pane
final selectedTaskIdProvider = StateProvider<String?>((ref) => null);

/// Filter options for current view
enum TaskFilter { all, pending, completed, important }

final taskFilterProvider = StateProvider<TaskFilter>((ref) => TaskFilter.all);

final selectedTagFilterProvider = StateProvider<String?>((ref) => null);

/// Watch a single task by ID
final singleTaskStreamProvider =
    StreamProvider.family<Task?, String>((ref, taskId) {
  final db = ref.watch(databaseProvider);
  return db.taskDao.watchTask(taskId);
});

/// Watch subtasks for a task
final taskSubtasksStreamProvider =
    StreamProvider.family<List<Subtask>, String>((ref, taskId) {
  final db = ref.watch(databaseProvider);
  return db.subtaskDao.watchSubtasksByTask(taskId);
});

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
