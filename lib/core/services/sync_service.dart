import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../db/app_database.dart';
import '../db/daos/sync_outbox_dao.dart';

enum SyncDecision {
  applyRemote,
  keepLocal,
  noAction,
}

class SyncService {
  final AppDatabase database;
  final SyncOutboxDao outboxDao;
  final SupabaseClient? supabase;

  SyncService(this.database, this.outboxDao, [this.supabase]);

  /// Resolves conflict between local Task and remote Supabase record using
  /// Last-Write-Wins (LWW) based on UTC updatedAt timestamp.
  static SyncDecision resolveConflict({
    required DateTime localUpdatedAt,
    required DateTime remoteUpdatedAt,
  }) {
    if (remoteUpdatedAt.isAfter(localUpdatedAt)) {
      return SyncDecision.applyRemote;
    } else if (localUpdatedAt.isAfter(remoteUpdatedAt)) {
      return SyncDecision.keepLocal;
    }
    return SyncDecision.noAction;
  }

  /// Synchronizes outbox changes to Supabase cloud database
  Future<int> processOutbox() async {
    if (supabase == null) return 0;

    final pending = await outboxDao.getPendingItems();
    if (pending.isEmpty) return 0;

    final List<String> successfullySyncedIds = [];

    for (final item in pending) {
      try {
        final payload = jsonDecode(item.payload) as Map<String, dynamic>;
        final targetTable = item.tableNameCol;

        if (item.operation == 'create' || item.operation == 'update') {
          await supabase!.from(targetTable).upsert(payload);
        } else if (item.operation == 'delete') {
          await supabase!.from(targetTable).update({
            'isDeleted': true,
            'updatedAt': DateTime.now().toUtc().toIso8601String(),
          }).eq('id', item.recordId);
        }

        successfullySyncedIds.add(item.id);
      } catch (_) {
        // Break on network error and retry during next sync cycle
        break;
      }
    }

    if (successfullySyncedIds.isNotEmpty) {
      await outboxDao.markSynced(successfullySyncedIds);
    }

    return successfullySyncedIds.length;
  }

  /// Pulls remote updates from Supabase and applies them using LWW
  Future<void> pullRemoteChanges() async {
    if (supabase == null) return;

    try {
      final response = await supabase!.from('tasks').select();
      final List<dynamic> remoteRecords = response as List<dynamic>;

      for (final raw in remoteRecords) {
        final remote = raw as Map<String, dynamic>;
        final id = remote['id'] as String;
        final remoteUpdatedAt =
            DateTime.parse(remote['updatedAt'] as String).toUtc();
        final local = await database.taskDao.getTask(id);

        if (local == null) {
          // New record from remote
          await database.taskDao.insertTask(
            TasksCompanion(
              id: Value(id),
              listId: Value(remote['listId'] as String),
              title: Value(remote['title'] as String),
              notes: Value(remote['notes'] as String? ?? ''),
              isCompleted: Value(remote['isCompleted'] as bool? ?? false),
              isImportant: Value(remote['isImportant'] as bool? ?? false),
              isMyDay: Value(remote['isMyDay'] as bool? ?? false),
              myDayDate: Value(remote['myDayDate'] as String? ?? ''),
              dueDate: Value(remote['dueDate'] != null
                  ? DateTime.parse(remote['dueDate'] as String)
                  : null),
              reminderAt: Value(remote['reminderAt'] != null
                  ? DateTime.parse(remote['reminderAt'] as String)
                  : null),
              recurrenceRule: Value(remote['recurrenceRule'] as String?),
              sortOrder: Value(remote['sortOrder'] as int? ?? 0),
              updatedAt: Value(remoteUpdatedAt),
              isDeleted: Value(remote['isDeleted'] as bool? ?? false),
              syncStatus: const Value('synced'),
            ),
          );
        } else {
          final decision = resolveConflict(
            localUpdatedAt: local.updatedAt.toUtc(),
            remoteUpdatedAt: remoteUpdatedAt,
          );

          if (decision == SyncDecision.applyRemote) {
            await database.taskDao.updateTask(
              TasksCompanion(
                id: Value(id),
                listId: Value(remote['listId'] as String),
                title: Value(remote['title'] as String),
                notes: Value(remote['notes'] as String? ?? ''),
                isCompleted: Value(remote['isCompleted'] as bool? ?? false),
                isImportant: Value(remote['isImportant'] as bool? ?? false),
                isMyDay: Value(remote['isMyDay'] as bool? ?? false),
                myDayDate: Value(remote['myDayDate'] as String? ?? ''),
                dueDate: Value(remote['dueDate'] != null
                    ? DateTime.parse(remote['dueDate'] as String)
                    : null),
                reminderAt: Value(remote['reminderAt'] != null
                    ? DateTime.parse(remote['reminderAt'] as String)
                    : null),
                recurrenceRule: Value(remote['recurrenceRule'] as String?),
                sortOrder: Value(remote['sortOrder'] as int? ?? 0),
                updatedAt: Value(remoteUpdatedAt),
                isDeleted: Value(remote['isDeleted'] as bool? ?? false),
                syncStatus: const Value('synced'),
              ),
            );
          }
        }
      }
    } catch (_) {
      // Ignore sync pull failures when offline
    }
  }
}
