import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'task_list_dao.g.dart';

@DriftAccessor(tables: [TaskLists])
class TaskListDao extends DatabaseAccessor<AppDatabase>
    with _$TaskListDaoMixin {
  TaskListDao(super.db);

  Future<List<TaskList>> getAllLists() {
    return (select(taskLists)
          ..where((l) => l.isDeleted.equals(false))
          ..orderBy([(l) => OrderingTerm.asc(l.name)]))
        .get();
  }

  Stream<List<TaskList>> watchAllLists() {
    return (select(taskLists)
          ..where((l) => l.isDeleted.equals(false))
          ..orderBy([(l) => OrderingTerm.asc(l.name)]))
        .watch();
  }

  Future<TaskList?> getList(String id) {
    return (select(taskLists)..where((l) => l.id.equals(id))).getSingleOrNull();
  }

  Future<int> insertList(TaskListsCompanion list) =>
      into(taskLists).insert(list);

  Future<bool> updateList(TaskListsCompanion list) =>
      update(taskLists).replace(list);

  Future<int> softDeleteList(String id, DateTime updatedAt) {
    return (update(taskLists)..where((l) => l.id.equals(id))).write(
      TaskListsCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(updatedAt),
        syncStatus: const Value('pending'),
      ),
    );
  }
}
