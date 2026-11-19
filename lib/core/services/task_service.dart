import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/services.dart';

import '../db/app_database.dart';
import '../db/daos/subtask_dao.dart';
import '../db/daos/sync_outbox_dao.dart';
import '../db/daos/task_dao.dart';
import '../db/daos/task_list_dao.dart';
import 'my_day_rollover_service.dart';
import 'recurrence_helper.dart';
import 'widget_sync_service.dart';

class TaskService {
  final TaskDao taskDao;
  final TaskListDao taskListDao;
  final SubtaskDao subtaskDao;
  final SyncOutboxDao syncOutboxDao;

  TaskService(
    this.taskDao,
    this.taskListDao,
    this.subtaskDao,
    this.syncOutboxDao,
  );

  /// Seeds initial task lists and welcome tasks if the local database is fresh
  Future<void> seedInitialDataIfEmpty() async {
    final existingLists = await taskListDao.getAllLists();
    if (existingLists.isNotEmpty) return;

    try {
      final jsonString =
          await rootBundle.loadString('assets/data/seed_tasks.json');
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final now = DateTime.now().toUtc();
      final todayIso = MyDayRolloverService.getTodayDateIso();

      if (data.containsKey('lists')) {
        for (final item in data['lists'] as List<dynamic>) {
          await taskListDao.insertList(
            TaskListsCompanion(
              id: Value(item['id'] as String),
              name: Value(item['name'] as String),
              createdAt: Value(now),
              updatedAt: Value(now),
              isDeleted: const Value(false),
              syncStatus: const Value('synced'),
            ),
          );
        }
      }

      if (data.containsKey('tasks')) {
        for (final item in data['tasks'] as List<dynamic>) {
          final isMyDay = item['isMyDay'] as bool? ?? false;
          await taskDao.insertTask(
            TasksCompanion(
              id: Value(item['id'] as String),
              listId: Value(item['listId'] as String),
              title: Value(item['title'] as String),
              notes: Value(item['notes'] as String? ?? ''),
              isCompleted: Value(item['isCompleted'] as bool? ?? false),
              isImportant: Value(item['isImportant'] as bool? ?? false),
              isMyDay: Value(isMyDay),
              myDayDate: Value(isMyDay ? todayIso : ''),
              sortOrder: Value(item['sortOrder'] as int? ?? 0),
              updatedAt: Value(now),
              isDeleted: const Value(false),
              syncStatus: const Value('synced'),
            ),
          );
        }
      }

      await refreshWidgets();
    } catch (_) {
      // Fallback: manually create default "Tasks" list if asset loading fails
      final now = DateTime.now().toUtc();
      await taskListDao.insertList(
        TaskListsCompanion(
          id: const Value('default-tasks-list'),
          name: const Value('Tasks'),
          createdAt: Value(now),
          updatedAt: Value(now),
          isDeleted: const Value(false),
          syncStatus: const Value('synced'),
        ),
      );
    }
  }

  /// Creates a new task
  Future<String> createTask({
    required String listId,
    required String title,
    String notes = '',
    bool isImportant = false,
    bool isMyDay = false,
    DateTime? dueDate,
    DateTime? reminderAt,
    String? recurrenceRule,
  }) async {
    final taskId = AppDatabase.generateId();
    final now = DateTime.now().toUtc();
    final todayIso = MyDayRolloverService.getTodayDateIso();

    await taskDao.insertTask(
      TasksCompanion(
        id: Value(taskId),
        listId: Value(listId),
        title: Value(title),
        notes: Value(notes),
        isCompleted: const Value(false),
        isImportant: Value(isImportant),
        isMyDay: Value(isMyDay),
        myDayDate: Value(isMyDay ? todayIso : ''),
        dueDate: Value(dueDate),
        reminderAt: Value(reminderAt),
        recurrenceRule: Value(recurrenceRule),
        sortOrder: const Value(0),
        updatedAt: Value(now),
        isDeleted: const Value(false),
        syncStatus: const Value('pending'),
      ),
    );

    // Queue sync outbox
    await syncOutboxDao.enqueue(
      SyncOutboxCompanion(
        id: Value(AppDatabase.generateId()),
        tableNameCol: const Value('tasks'),
        recordId: Value(taskId),
        operation: const Value('create'),
        payload: Value(jsonEncode({
          'id': taskId,
          'listId': listId,
          'title': title,
          'notes': notes,
          'isCompleted': false,
          'isImportant': isImportant,
          'isMyDay': isMyDay,
          'myDayDate': isMyDay ? todayIso : '',
          'dueDate': dueDate?.toIso8601String(),
          'reminderAt': reminderAt?.toIso8601String(),
          'recurrenceRule': recurrenceRule,
          'updatedAt': now.toIso8601String(),
          'isDeleted': false,
        })),
        createdAt: Value(now),
        synced: const Value(false),
      ),
    );

    await refreshWidgets();
    return taskId;
  }

  /// Toggles task completion, handling recurring tasks automatically
  Future<void> toggleTaskCompletion(String taskId, bool isCompleted) async {
    final task = await taskDao.getTask(taskId);
    if (task == null) return;

    final now = DateTime.now().toUtc();

    await taskDao.completeTask(taskId, isCompleted, now);

    // If marked completed and has a recurrence rule, spawn next occurrence
    if (isCompleted &&
        task.recurrenceRule != null &&
        task.recurrenceRule!.isNotEmpty) {
      final baseDate = task.dueDate ?? DateTime.now();
      final nextDueDate =
          RecurrenceHelper.getNextOccurrence(baseDate, task.recurrenceRule!);

      await createTask(
        listId: task.listId,
        title: task.title,
        notes: task.notes,
        isImportant: task.isImportant,
        isMyDay: task.isMyDay,
        dueDate: nextDueDate,
        recurrenceRule: task.recurrenceRule,
      );
    }

    // Queue outbox
    await syncOutboxDao.enqueue(
      SyncOutboxCompanion(
        id: Value(AppDatabase.generateId()),
        tableNameCol: const Value('tasks'),
        recordId: Value(taskId),
        operation: const Value('update'),
        payload: Value(jsonEncode({
          'id': taskId,
          'isCompleted': isCompleted,
          'updatedAt': now.toIso8601String(),
        })),
        createdAt: Value(now),
        synced: const Value(false),
      ),
    );

    await refreshWidgets();
  }

  /// Toggles task importance
  Future<void> toggleImportance(String taskId, bool isImportant) async {
    final now = DateTime.now().toUtc();
    await taskDao.toggleImportant(taskId, isImportant, now);
    await refreshWidgets();
  }

  /// Toggles task My Day assignment
  Future<void> toggleMyDay(String taskId, bool isMyDay) async {
    final now = DateTime.now().toUtc();
    final todayIso = MyDayRolloverService.getTodayDateIso();
    await taskDao.toggleMyDay(taskId, isMyDay, isMyDay ? todayIso : '', now);
    await refreshWidgets();
  }

  /// Soft deletes a task
  Future<void> deleteTask(String taskId) async {
    final now = DateTime.now().toUtc();
    await taskDao.softDeleteTask(taskId, now);

    await syncOutboxDao.enqueue(
      SyncOutboxCompanion(
        id: Value(AppDatabase.generateId()),
        tableNameCol: const Value('tasks'),
        recordId: Value(taskId),
        operation: const Value('delete'),
        payload: Value(jsonEncode({
          'id': taskId,
          'isDeleted': true,
          'updatedAt': now.toIso8601String(),
        })),
        createdAt: Value(now),
        synced: const Value(false),
      ),
    );

    await refreshWidgets();
  }

  /// Updates task details (title, notes, due date, reminder, recurrence, list)
  Future<void> updateTaskDetails({
    required String taskId,
    String? title,
    String? notes,
    Value<DateTime?>? dueDate,
    Value<DateTime?>? reminderAt,
    Value<String?>? recurrenceRule,
    String? listId,
  }) async {
    final now = DateTime.now().toUtc();
    await taskDao.updateTaskFields(
      id: taskId,
      title: title,
      notes: notes,
      dueDate: dueDate,
      reminderAt: reminderAt,
      recurrenceRule: recurrenceRule,
      listId: listId,
      updatedAt: now,
    );
    await refreshWidgets();
  }

  /// Subtask operations
  Future<void> createSubtask(String taskId, String title) async {
    if (title.trim().isEmpty) return;
    final now = DateTime.now().toUtc();
    final subtasks = await subtaskDao.getSubtasksByTask(taskId);
    await subtaskDao.insertSubtask(
      SubtasksCompanion(
        id: Value(AppDatabase.generateId()),
        taskId: Value(taskId),
        title: Value(title.trim()),
        isCompleted: const Value(false),
        sortOrder: Value(subtasks.length),
        createdAt: Value(now),
        updatedAt: Value(now),
        isDeleted: const Value(false),
        syncStatus: const Value('pending'),
      ),
    );
  }

  Future<void> toggleSubtask(String subtaskId, bool isCompleted) async {
    final now = DateTime.now().toUtc();
    await subtaskDao.toggleSubtask(subtaskId, isCompleted, now);
  }

  Future<void> deleteSubtask(String subtaskId) async {
    final now = DateTime.now().toUtc();
    await subtaskDao.softDeleteSubtask(subtaskId, now);
  }

  /// Creates a new user list
  Future<String> createList(String name) async {
    final listId = AppDatabase.generateId();
    final now = DateTime.now().toUtc();

    await taskListDao.insertList(
      TaskListsCompanion(
        id: Value(listId),
        name: Value(name),
        createdAt: Value(now),
        updatedAt: Value(now),
        isDeleted: const Value(false),
        syncStatus: const Value('pending'),
      ),
    );

    return listId;
  }

  /// Soft deletes a list
  Future<void> deleteList(String listId) async {
    final now = DateTime.now().toUtc();
    await taskListDao.softDeleteList(listId, now);
  }

  /// Triggers widget synchronization
  Future<void> refreshWidgets() async {
    final todayIso = MyDayRolloverService.getTodayDateIso();
    final myDayTasks = await taskDao.getMyDayTasks(todayIso);
    await WidgetSyncService.syncWidgets(myDayTasks);
  }
}
