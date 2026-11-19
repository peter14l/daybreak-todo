import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import 'tables.dart';
import 'daos/task_dao.dart';
import 'daos/task_list_dao.dart';
import 'daos/subtask_dao.dart';
import 'daos/sync_outbox_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [TaskLists, Tasks, Subtasks, SyncOutbox],
  daos: [TaskDao, TaskListDao, SubtaskDao, SyncOutboxDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  static AppDatabase? _instance;

  static AppDatabase get instance {
    _instance ??= AppDatabase();
    return _instance!;
  }

  static void setInstance(AppDatabase db) {
    _instance = db;
  }

  @override
  int get schemaVersion => 1;

  static String generateId() {
    return const Uuid().v7();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'daybreak.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
