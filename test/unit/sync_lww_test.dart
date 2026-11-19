import 'package:flutter_test/flutter_test.dart';
import 'package:daybreak/core/services/sync_service.dart';

void main() {
  group('Offline-to-Online Sync LWW Conflict Resolution Tests', () {
    test('Remote record with newer UTC updatedAt overwrites local', () {
      final localUpdatedAt = DateTime.utc(2026, 11, 19, 10, 0, 0);
      final remoteUpdatedAt =
          DateTime.utc(2026, 11, 19, 10, 5, 0); // 5 mins newer

      final decision = SyncService.resolveConflict(
        localUpdatedAt: localUpdatedAt,
        remoteUpdatedAt: remoteUpdatedAt,
      );

      expect(decision, equals(SyncDecision.applyRemote));
    });

    test('Local record with newer UTC updatedAt is kept', () {
      final localUpdatedAt =
          DateTime.utc(2026, 11, 19, 12, 0, 0); // 2 hours newer
      final remoteUpdatedAt = DateTime.utc(2026, 11, 19, 10, 0, 0);

      final decision = SyncService.resolveConflict(
        localUpdatedAt: localUpdatedAt,
        remoteUpdatedAt: remoteUpdatedAt,
      );

      expect(decision, equals(SyncDecision.keepLocal));
    });

    test('Identical timestamps require no conflict action', () {
      final timestamp = DateTime.utc(2026, 11, 19, 12, 0, 0);

      final decision = SyncService.resolveConflict(
        localUpdatedAt: timestamp,
        remoteUpdatedAt: timestamp,
      );

      expect(decision, equals(SyncDecision.noAction));
    });

    test(
        'Soft-delete tombstone with newer timestamp correctly overrides older active record',
        () {
      final localTask = {
        'id': 'task-1',
        'title': 'Active Task on Phone',
        'isDeleted': false,
        'updatedAt': DateTime.utc(2026, 11, 19, 14, 0, 0),
      };

      final remoteTombstone = {
        'id': 'task-1',
        'title': 'Active Task on Phone',
        'isDeleted': true, // Deleted on laptop later
        'updatedAt': DateTime.utc(2026, 11, 19, 14, 30, 0),
      };

      final decision = SyncService.resolveConflict(
        localUpdatedAt: localTask['updatedAt'] as DateTime,
        remoteUpdatedAt: remoteTombstone['updatedAt'] as DateTime,
      );

      expect(decision, equals(SyncDecision.applyRemote));
    });
  });
}
