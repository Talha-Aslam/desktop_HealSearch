import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'database.g.dart';

class Medicines extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get pharmacyId => text().nullable()(); // NEW TENANT ID COLUMN
  TextColumn get name => text().withLength(min: 1, max: 255)();
  TextColumn get genericName =>
      text().nullable().withLength(min: 1, max: 255)();
  TextColumn get category => text().nullable().withLength(min: 1, max: 255)();
  RealColumn get price => real()();
  IntColumn get stock => integer()();
  DateTimeColumn get expiryDate => dateTime().nullable()();
}

class Sales extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get pharmacyId => text().nullable()(); // NEW TENANT ID COLUMN
  RealColumn get totalAmount => real()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isSyncedToCloud =>
      boolean().withDefault(const Constant(false))();
}

@DriftDatabase(tables: [Medicines, Sales])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2; // INCREMENTED SCHEMA VERSION FOR MIGRATION

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          // WE ADDED THE PHARMACY_ID TO BOTH TABLES
          await m.addColumn(medicines, medicines.pharmacyId);
          await m.addColumn(sales, sales.pharmacyId);
        }
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'healsearch_pos.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
