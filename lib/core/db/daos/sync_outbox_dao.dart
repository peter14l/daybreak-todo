import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables.dart';

part 'sync_outbox_dao.g.dart';

@DriftAccessor(tables: [SyncOutbox])
class SyncOutboxDao extends DatabaseAccessor<AppDatabase>
    with _$SyncOutboxDaoMixin {
  SyncOutboxDao(super.db);

  Future<List<SyncOutboxData>> getPendingItems() {
    return (select(syncOutbox)..where((s) => s.synced.equals(false))).get();
  }

  Stream<List<SyncOutboxData>> watchPendingItems() {
    return (select(syncOutbox)..where((s) => s.synced.equals(false))).watch();
  }

  Future<int> enqueue(SyncOutboxCompanion item) =>
      into(syncOutbox).insertOnConflictUpdate(item);

  Future<void> markSynced(List<String> ids) async {
    await (update(syncOutbox)..where((s) => s.id.isIn(ids))).write(
      const SyncOutboxCompanion(synced: Value(true)),
    );
  }

  Future<void> clearSynced() {
    return (delete(syncOutbox)..where((s) => s.synced.equals(true))).go();
  }
}
