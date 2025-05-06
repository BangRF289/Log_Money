import 'package:drift/drift.dart';

class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get email => text().customConstraint('UNIQUE NOT NULL')();
  TextColumn get password => text()();
  DateTimeColumn get createdAt => dateTime()();
}
