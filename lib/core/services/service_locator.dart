import 'package:supabase_flutter/supabase_flutter.dart';

import '../db/app_database.dart';
import '../db/daos/task_dao.dart';
import '../db/daos/task_list_dao.dart';
import '../db/daos/subtask_dao.dart';
import '../db/daos/sync_outbox_dao.dart';
import 'task_service.dart';
import 'sync_service.dart';
import 'auth_service.dart';
import 'microsoft_import_service.dart';
import 'my_day_rollover_service.dart';

class ServiceLocator {
  static late AppDatabase database;
  static late TaskDao taskDao;
  static late TaskListDao taskListDao;
  static late SubtaskDao subtaskDao;
  static late SyncOutboxDao syncOutboxDao;
  static late TaskService taskService;
  static late SyncService syncService;
  static late AuthService authService;
  static late MicrosoftTodoImportService microsoftImportService;
  static late MyDayRolloverService myDayRolloverService;

  static bool _initialized = false;

  static Future<void> initialize({
    String? supabaseUrl,
    String? supabaseAnonKey,
    AppDatabase? testDb,
  }) async {
    if (_initialized && testDb == null) return;

    database = testDb ?? AppDatabase.instance;
    taskDao = database.taskDao;
    taskListDao = database.taskListDao;
    subtaskDao = database.subtaskDao;
    syncOutboxDao = database.syncOutboxDao;

    SupabaseClient? client;
    if (supabaseUrl != null &&
        supabaseAnonKey != null &&
        supabaseUrl.isNotEmpty &&
        supabaseAnonKey.isNotEmpty &&
        !supabaseUrl.contains('placeholder')) {
      try {
        await Supabase.initialize(
          url: supabaseUrl,
          anonKey: supabaseAnonKey,
        );
        client = Supabase.instance.client;
      } catch (_) {}
    }

    authService = AuthService(client);
    syncService = SyncService(database, syncOutboxDao, client);
    taskService = TaskService(taskDao, taskListDao, subtaskDao, syncOutboxDao);
    microsoftImportService = MicrosoftTodoImportService(taskDao, taskListDao);
    myDayRolloverService = MyDayRolloverService(database);

    // Perform My Day midnight rollover check and seed data
    await myDayRolloverService.performRolloverCheck();
    await taskService.seedInitialDataIfEmpty();

    _initialized = true;
  }
}
