import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:http/http.dart' as http;

import '../db/app_database.dart';
import '../db/daos/task_dao.dart';
import '../db/daos/task_list_dao.dart';

class ImportResult {
  final int listsImported;
  final int tasksImported;
  final List<String> errors;

  ImportResult({
    required this.listsImported,
    required this.tasksImported,
    this.errors = const [],
  });
}

class MicrosoftTodoImportService {
  final TaskDao taskDao;
  final TaskListDao taskListDao;

  MicrosoftTodoImportService(this.taskDao, this.taskListDao);

  /// Imports lists and tasks directly from Microsoft Graph API using an OAuth access token with Tasks.Read scope
  Future<ImportResult> importFromGraphApi(String accessToken) async {
    int listsCount = 0;
    int tasksCount = 0;
    final errors = <String>[];

    try {
      final headers = {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      };

      // 1. Fetch task lists: https://graph.microsoft.com/v1.0/me/todo/lists
      final listsResponse = await http.get(
        Uri.parse('https://graph.microsoft.com/v1.0/me/todo/lists'),
        headers: headers,
      );

      if (listsResponse.statusCode != 200) {
        errors.add(
            'Failed to fetch lists from Graph API: ${listsResponse.statusCode}');
        return ImportResult(listsImported: 0, tasksImported: 0, errors: errors);
      }

      final listsJson = jsonDecode(listsResponse.body);
      final List<dynamic> graphLists = listsJson['value'] ?? [];

      for (final gList in graphLists) {
        final listId = AppDatabase.generateId();
        final listName = gList['displayName'] as String? ?? 'Imported List';
        final now = DateTime.now().toUtc();

        await taskListDao.insertList(
          TaskListsCompanion(
            id: Value(listId),
            name: Value(listName),
            createdAt: Value(now),
            updatedAt: Value(now),
            isDeleted: const Value(false),
            syncStatus: const Value('pending'),
          ),
        );
        listsCount++;

        // 2. Fetch tasks for each list: https://graph.microsoft.com/v1.0/me/todo/lists/{id}/tasks
        final msListId = gList['id'];
        final tasksResponse = await http.get(
          Uri.parse(
              'https://graph.microsoft.com/v1.0/me/todo/lists/$msListId/tasks'),
          headers: headers,
        );

        if (tasksResponse.statusCode == 200) {
          final tasksJson = jsonDecode(tasksResponse.body);
          final List<dynamic> graphTasks = tasksJson['value'] ?? [];

          for (final gTask in graphTasks) {
            final taskId = AppDatabase.generateId();
            final title = gTask['title'] as String? ?? 'Untitled Task';
            final body = gTask['body']?['content'] as String? ?? '';
            final status = gTask['status'] as String? ?? 'notStarted';
            final isCompleted = status.toLowerCase() == 'completed';
            final importance = gTask['importance'] as String? ?? 'normal';
            final isImportant = importance.toLowerCase() == 'high';

            DateTime? dueDate;
            if (gTask['dueDateTime']?['dateTime'] != null) {
              dueDate = DateTime.tryParse(gTask['dueDateTime']['dateTime']);
            }

            DateTime? reminderAt;
            if (gTask['reminderDateTime']?['dateTime'] != null) {
              reminderAt =
                  DateTime.tryParse(gTask['reminderDateTime']['dateTime']);
            }

            String? recurrenceRule;
            if (gTask['recurrence']?['pattern']?['type'] != null) {
              recurrenceRule = gTask['recurrence']['pattern']['type']
                  .toString()
                  .toLowerCase();
            }

            await taskDao.insertTask(
              TasksCompanion(
                id: Value(taskId),
                listId: Value(listId),
                title: Value(title),
                notes: Value(body),
                isCompleted: Value(isCompleted),
                isImportant: Value(isImportant),
                isMyDay: const Value(false),
                myDayDate: const Value(''),
                dueDate: Value(dueDate),
                reminderAt: Value(reminderAt),
                recurrenceRule: Value(recurrenceRule),
                sortOrder: Value(tasksCount),
                updatedAt: Value(now),
                isDeleted: const Value(false),
                syncStatus: const Value('pending'),
              ),
            );
            tasksCount++;
          }
        }
      }
    } catch (e) {
      errors.add(e.toString());
    }

    return ImportResult(
      listsImported: listsCount,
      tasksImported: tasksCount,
      errors: errors,
    );
  }

  /// Imports from a local JSON archive backup
  Future<ImportResult> importFromJsonString(String jsonContent) async {
    int listsCount = 0;
    int tasksCount = 0;
    final errors = <String>[];

    try {
      final data = jsonDecode(jsonContent) as Map<String, dynamic>;
      final now = DateTime.now().toUtc();

      final listIdMapping = <String, String>{};

      if (data.containsKey('lists')) {
        final lists = data['lists'] as List<dynamic>;
        for (final item in lists) {
          final oldId = item['id']?.toString() ?? AppDatabase.generateId();
          final newId = AppDatabase.generateId();
          listIdMapping[oldId] = newId;

          await taskListDao.insertList(
            TaskListsCompanion(
              id: Value(newId),
              name: Value(item['name']?.toString() ?? 'Imported List'),
              createdAt: Value(now),
              updatedAt: Value(now),
              isDeleted: const Value(false),
              syncStatus: const Value('pending'),
            ),
          );
          listsCount++;
        }
      }

      if (data.containsKey('tasks')) {
        final tasks = data['tasks'] as List<dynamic>;
        for (final item in tasks) {
          final originalListId = item['listId']?.toString() ?? '';
          final targetListId = listIdMapping[originalListId] ??
              (listIdMapping.values.isNotEmpty
                  ? listIdMapping.values.first
                  : 'default');

          await taskDao.insertTask(
            TasksCompanion(
              id: Value(AppDatabase.generateId()),
              listId: Value(targetListId),
              title: Value(item['title']?.toString() ?? 'Task'),
              notes: Value(item['notes']?.toString() ?? ''),
              isCompleted: Value(item['isCompleted'] as bool? ?? false),
              isImportant: Value(item['isImportant'] as bool? ?? false),
              isMyDay: Value(item['isMyDay'] as bool? ?? false),
              myDayDate: Value(item['myDayDate']?.toString() ?? ''),
              dueDate: Value(item['dueDate'] != null
                  ? DateTime.tryParse(item['dueDate'].toString())
                  : null),
              reminderAt: Value(item['reminderAt'] != null
                  ? DateTime.tryParse(item['reminderAt'].toString())
                  : null),
              recurrenceRule: Value(item['recurrenceRule']?.toString()),
              sortOrder: Value(tasksCount),
              updatedAt: Value(now),
              isDeleted: const Value(false),
              syncStatus: const Value('pending'),
            ),
          );
          tasksCount++;
        }
      }
    } catch (e) {
      errors.add(e.toString());
    }

    return ImportResult(
      listsImported: listsCount,
      tasksImported: tasksCount,
      errors: errors,
    );
  }

  /// Exports all non-deleted task lists and tasks into a portable JSON backup archive
  Future<String> exportToJsonString() async {
    final lists = await taskListDao.getAllLists();
    final tasks = await taskDao.watchAllActiveTasks().first;

    final exportData = {
      'version': '1.0',
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'lists': lists
          .map((l) => {
                'id': l.id,
                'name': l.name,
                'createdAt': l.createdAt.toIso8601String(),
              })
          .toList(),
      'tasks': tasks
          .map((t) => {
                'id': t.id,
                'listId': t.listId,
                'title': t.title,
                'notes': t.notes,
                'isCompleted': t.isCompleted,
                'isImportant': t.isImportant,
                'isMyDay': t.isMyDay,
                'myDayDate': t.myDayDate,
                'dueDate': t.dueDate?.toIso8601String(),
                'reminderAt': t.reminderAt?.toIso8601String(),
                'recurrenceRule': t.recurrenceRule,
                'updatedAt': t.updatedAt.toIso8601String(),
              })
          .toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(exportData);
  }
}
