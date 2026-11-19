import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'task_dao.g.dart';

@DriftAccessor(tables: [Tasks])
class TaskDao extends DatabaseAccessor<AppDatabase> with _$TaskDaoMixin {
  TaskDao(super.db);

  Future<List<Task>> getMyDayTasks(String date) {
    return (select(tasks)
          ..where((t) =>
              t.isMyDay.equals(true) &
              t.myDayDate.equals(date) &
              t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
  }

  Stream<List<Task>> watchMyDayTasks(String date) {
    return (select(tasks)
          ..where((t) =>
              t.isMyDay.equals(true) &
              t.myDayDate.equals(date) &
              t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .watch();
  }

  Future<List<Task>> getTasksByList(String listId) {
    return (select(tasks)
          ..where((t) => t.listId.equals(listId) & t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
  }

  Stream<List<Task>> watchTasksByList(String listId) {
    return (select(tasks)
          ..where((t) => t.listId.equals(listId) & t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .watch();
  }

  Stream<List<Task>> watchImportantTasks() {
    return (select(tasks)
          ..where((t) => t.isImportant.equals(true) & t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .watch();
  }

  Stream<List<Task>> watchPlannedTasks() {
    return (select(tasks)
          ..where((t) => t.dueDate.isNotNull() & t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.dueDate)]))
        .watch();
  }

  Stream<List<Task>> watchAllActiveTasks() {
    return (select(tasks)
          ..where((t) => t.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .watch();
  }

  Future<Task?> getTask(String id) {
    return (select(tasks)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<int> insertTask(TasksCompanion task) => into(tasks).insert(task);

  Future<bool> updateTask(TasksCompanion task) => update(tasks).replace(task);

  Future<int> softDeleteTask(String id, DateTime updatedAt) {
    return (update(tasks)..where((t) => t.id.equals(id))).write(
      TasksCompanion(
        isDeleted: const Value(true),
        updatedAt: Value(updatedAt),
        syncStatus: const Value('pending'),
      ),
    );
  }

  Future<int> completeTask(String id, bool isCompleted, DateTime updatedAt) {
    return (update(tasks)..where((t) => t.id.equals(id))).write(
      TasksCompanion(
        isCompleted: Value(isCompleted),
        updatedAt: Value(updatedAt),
        syncStatus: const Value('pending'),
      ),
    );
  }

  Future<int> toggleImportant(String id, bool isImportant, DateTime updatedAt) {
    return (update(tasks)..where((t) => t.id.equals(id))).write(
      TasksCompanion(
        isImportant: Value(isImportant),
        updatedAt: Value(updatedAt),
        syncStatus: const Value('pending'),
      ),
    );
  }

  Future<int> toggleMyDay(
      String id, bool isMyDay, String myDayDate, DateTime updatedAt) {
    return (update(tasks)..where((t) => t.id.equals(id))).write(
      TasksCompanion(
        isMyDay: Value(isMyDay),
        myDayDate: Value(myDayDate),
        updatedAt: Value(updatedAt),
        syncStatus: const Value('pending'),
      ),
    );
  }

  Future<int> clearStaleMyDay(String todayDate, DateTime updatedAt) {
    return (update(tasks)
          ..where((t) =>
              t.myDayDate.isSmallerThanValue(todayDate) &
              t.isMyDay.equals(true)))
        .write(
      TasksCompanion(
        isMyDay: const Value(false),
        myDayDate: const Value(''),
        updatedAt: Value(updatedAt),
        syncStatus: const Value('pending'),
      ),
    );
  }

  Future<List<Task>> getUpcomingTasks(DateTime today) {
    return (select(tasks)
          ..where((t) =>
              t.isCompleted.equals(false) &
              t.isDeleted.equals(false) &
              t.dueDate.isSmallerOrEqualValue(today))
          ..orderBy([(t) => OrderingTerm.asc(t.dueDate)]))
        .get();
  }
}
