import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'subtask_dao.g.dart';

@DriftAccessor(tables: [Subtasks])
class SubtaskDao extends DatabaseAccessor<AppDatabase> with _$SubtaskDaoMixin {
  SubtaskDao(super.db);

  Future<List<Subtask>> getSubtasksByTask(String taskId) {
    return (select(subtasks)
          ..where((s) => s.taskId.equals(taskId) & s.isDeleted.equals(false))
          ..orderBy([(s) => OrderingTerm.asc(s.sortOrder)]))
        .get();
  }

  Stream<List<Subtask>> watchSubtasksByTask(String taskId) {
    return (select(subtasks)
          ..where((s) => s.taskId.equals(taskId) & s.isDeleted.equals(false))
          ..orderBy([(s) => OrderingTerm.asc(s.sortOrder)]))
        .watch();
  }

  Future<int> insertSubtask(SubtasksCompanion subtask) =>
      into(subtasks).insert(subtask);

  Future<bool> updateSubtask(SubtasksCompanion subtask) =>
      update(subtasks).replace(subtask);

  Future<int> toggleSubtask(String id, bool isCompleted, DateTime updatedAt) {
    return (update(subtasks)..where((s) => s.id.equals(id))).write(
      SubtasksCompanion(
        isCompleted: Value(isCompleted),
        updatedAt: Value(updatedAt),
        syncStatus: const Value('pending'),
      ),
    );
  }

  Future<int> softDeleteSubtask(String id, DateTime updatedAt) {
    return (update(subtasks)..where((s) => s.id.equals(id))).write(
      SubtasksCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(updatedAt),
        syncStatus: const Value('pending'),
      ),
    );
  }
}
