import 'package:drift/drift.dart';

class TaskLists extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  TextColumn get syncStatus => text().withDefault(const Constant('synced'))();

  @override
  Set<Column> get primaryKey => {id};
}

class Tasks extends Table {
  TextColumn get id => text()();
  TextColumn get listId => text()();
  TextColumn get title => text()();
  TextColumn get notes => text().withDefault(const Constant(''))();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  BoolColumn get isImportant => boolean().withDefault(const Constant(false))();
  BoolColumn get isMyDay => boolean().withDefault(const Constant(false))();
  TextColumn get myDayDate => text().withDefault(const Constant(''))();
  DateTimeColumn get dueDate => dateTime().nullable()();
  DateTimeColumn get reminderAt => dateTime().nullable()();
  TextColumn get recurrenceRule => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  TextColumn get syncStatus => text().withDefault(const Constant('synced'))();

  @override
  Set<Column> get primaryKey => {id};
}

class Subtasks extends Table {
  TextColumn get id => text()();
  TextColumn get taskId => text()();
  TextColumn get title => text()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  TextColumn get syncStatus => text().withDefault(const Constant('synced'))();

  @override
  Set<Column> get primaryKey => {id};
}

class SyncOutbox extends Table {
  TextColumn get id => text()();
  TextColumn get tableNameCol => text().named('table_name')();
  TextColumn get recordId => text()();
  TextColumn get operation => text()(); // create, update, delete
  TextColumn get payload => text()();
  DateTimeColumn get createdAt => dateTime()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
