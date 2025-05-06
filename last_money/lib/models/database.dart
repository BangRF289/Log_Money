import 'dart:io';

import 'package:drift/drift.dart';
// These imports are used to open the database
import 'package:drift/native.dart';
import 'package:last_money/models/category.dart';
import 'package:last_money/models/transaction.dart';
import 'package:last_money/models/transaction_with_category.dart';
import 'package:last_money/models/users.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'database.g.dart';

@DriftDatabase(
  tables: [Categories, Transactions, Users],
)
class AppDb extends _$AppDb {
  // Singleton: hanya ada satu instance database
  static final AppDb _instance = AppDb._internal();

  factory AppDb() {
    return _instance;
  }

  AppDb._internal() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  //CRUD Category
  Future<List<Category>> getAllCategoryRepo(int type, int userId) {
    return (select(categories)
          ..where((tbl) => tbl.type.equals(type) & tbl.user_id.equals(userId)))
        .get();
  }

  Future updateCategoryRepo(int id, String name) async {
    return (update(categories)..where((tbl) => tbl.id.equals(id)))
        .write(CategoriesCompanion(name: Value(name)));
  }

  Future deleteCategoryRepo(int id) async {
    return (delete(categories)..where((tbl) => tbl.id.equals(id))).go();
  }

  //TRANSACTION
  Stream<List<TransactionWithCategory>> getTransactionsByDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay
        .add(const Duration(days: 1))
        .subtract(const Duration(seconds: 1));

    final query = (select(transactions).join([
      innerJoin(categories, categories.id.equalsExp(transactions.category_id))
    ])
      ..where(
          transactions.transaction_date.isBetweenValues(startOfDay, endOfDay)));

    return query.watch().map((rows) {
      return rows.map((row) {
        return TransactionWithCategory(
            row.readTable(transactions), row.readTable(categories));
      }).toList();
    });
  }

  Future updateTransactionRepo(int id, int amount, int categoryId,
      DateTime transactionDate, String nameDetail) async {
    return (update(transactions)..where((tbl) => tbl.id.equals(id))).write(
        TransactionsCompanion(
            name: Value(nameDetail),
            amount: Value(amount),
            category_id: Value(categoryId),
            transaction_date: Value(transactionDate)));
  }

  Future<List<TransactionWithCategory>> getAllTransactionsByUser(
      int userId) async {
    final query = await (select(transactions)
          ..where((t) => t.user_id.equals(userId))
          ..orderBy([(t) => OrderingTerm.desc(t.transaction_date)]))
        .join([
      leftOuterJoin(
          categories, categories.id.equalsExp(transactions.category_id))
    ]).get();

    return query.map((row) {
      return TransactionWithCategory(
        row.readTable(transactions),
        row.readTable(categories),
      );
    }).toList();
  }

  Future<List<TransactionWithCategory>> getTransactionsByMonthByUser(
      int userId, int month, int year) async {
    final query = await (select(transactions)
          ..where((t) =>
              t.user_id.equals(userId) &
              t.transaction_date.month.equals(month) &
              t.transaction_date.year.equals(year)))
        .join([
      leftOuterJoin(
          categories, categories.id.equalsExp(transactions.category_id))
    ]).get();

    return query.map((row) {
      return TransactionWithCategory(
        row.readTable(transactions),
        row.readTable(categories),
      );
    }).toList();
  }

  Stream<int> watchTotalIncomeByUser(int userId, int month, int year) {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);

    // ✅ Tambahkan userId ke parameter getAllCategoryRepo
    return getAllCategoryRepo(1, userId)
        .asStream()
        .asyncMap((incomeCategories) async {
      if (incomeCategories.isEmpty) return 0;
      final categoryIds = incomeCategories.map((c) => c.id).toList();

      final transactionsList = await (select(transactions)
            ..where((t) =>
                t.user_id.equals(userId) &
                t.transaction_date.isBetweenValues(startDate, endDate) &
                t.category_id.isIn(categoryIds)))
          .get();

      final totalIncome = transactionsList.fold(0, (sum, t) => sum + t.amount);
      return totalIncome;
    }).distinct();
  }

  Stream<int> watchTotalExpenseByUser(int userId, int month, int year) {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);

    // ✅ Tambahkan userId ke pemanggilan getAllCategoryRepo
    return getAllCategoryRepo(2, userId)
        .asStream()
        .asyncMap((expenseCategories) async {
      if (expenseCategories.isEmpty) return 0;
      final categoryIds = expenseCategories.map((c) => c.id).toList();

      final transactionsList = await (select(transactions)
            ..where((t) =>
                t.user_id.equals(userId) &
                t.transaction_date.isBetweenValues(startDate, endDate) &
                t.category_id.isIn(categoryIds)))
          .get();

      final totalExpense = transactionsList.fold(0, (sum, t) => sum + t.amount);
      return totalExpense;
    }).distinct();
  }

  Future<List<Category>> getAllCategoryByUser(int type, int userId) {
    return (select(categories)
          ..where((tbl) => tbl.type.equals(type))
          ..where((tbl) => tbl.user_id.equals(userId)))
        .get();
  }

  Stream<List<TransactionWithCategory>> getTransactionsByDateByUser(
      DateTime date, int userId) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay
        .add(const Duration(days: 1))
        .subtract(const Duration(seconds: 1));

    final query = (select(transactions).join([
      innerJoin(categories, categories.id.equalsExp(transactions.category_id))
    ])
      ..where(
          transactions.transaction_date.isBetweenValues(startOfDay, endOfDay) &
              transactions.user_id.equals(userId)));

    return query.watch().map((rows) {
      return rows.map((row) {
        return TransactionWithCategory(
          row.readTable(transactions),
          row.readTable(categories),
        );
      }).toList();
    });
  }

  Future deleteTransactionRepo(int id) async {
    return (delete(transactions)..where((tbl) => tbl.id.equals(id))).go();
  }

  Future<void> checkCategories() async {
    final db = AppDb();
    final categories = await db.select(db.categories).get();
    for (var category in categories) {
      print(
          "📌 Kategori: ID=${category.id}, Nama=${category.name}, Type=${category.type}");
    }
  }

  Future<int?> getIncomeCategoryId() async {
    final query = await (select(categories)
          ..where((tbl) => tbl.type.equals(1))) // Find Income category
        .getSingleOrNull();
    return query?.id;
  }

  Stream<int> watchTotalIncome(int userId, int month, int year) {
    print("🔄 Mengambil data Income untuk bulan $month/$year...");

    final startDate = DateTime(year, month, 1);
    final endDate =
        DateTime(year, month + 1, 0, 23, 59, 59); // Hari terakhir bulan

    // ✅ Tambahkan userId ke pemanggilan getAllCategoryRepo
    return getAllCategoryRepo(1, userId)
        .asStream()
        .asyncMap((incomeCategories) async {
      if (incomeCategories.isEmpty) {
        print("⚠️ Tidak ada kategori income, mengembalikan 0.");
        return 0;
      }

      final categoryIds = incomeCategories.map((c) => c.id).toList();
      print("📌 Kategori Income: $categoryIds");

      // Query transaksi dalam rentang waktu & kategori income
      final transactionsList = await (select(transactions)
            ..where(
                (t) => t.transaction_date.isBetweenValues(startDate, endDate))
            ..where((t) => t.category_id.isIn(categoryIds)))
          .get();

      if (transactionsList.isEmpty) {
        print("⚠️ Tidak ada transaksi income di bulan ini.");
        return 0;
      }

      // Debugging transaksi yang ditemukan
      print("🔍 Data transaksi yang ditemukan:");
      for (var t in transactionsList) {
        print("📝 Transaksi: ${t.name}, ${t.amount}");
      }

      final totalIncome = transactionsList.fold(
          0, (prev, transaction) => prev + transaction.amount);

      print("✅ Total Income untuk bulan $month: $totalIncome");

      return totalIncome;
    }).distinct();
  }

  Stream<int> watchTotalExpense(int userId, int month, int year) {
    print("🔄 Mengambil data Expense untuk bulan $month/$year...");

    final startDate = DateTime(year, month, 1);
    final endDate =
        DateTime(year, month + 1, 0, 23, 59, 59); // Hari terakhir bulan

    return getAllCategoryRepo(2, userId)
        .asStream()
        .asyncMap((expenseCategories) async {
      if (expenseCategories.isEmpty) {
        print("⚠️ Tidak ada kategori expense, mengembalikan 0.");
        return 0;
      }

      final categoryIds = expenseCategories.map((c) => c.id).toList();
      print("📌 Kategori Expense: $categoryIds");

      final query = (select(transactions)
            ..where(
                (t) => t.transaction_date.isBetweenValues(startDate, endDate))
            ..where((t) => t.category_id.isIn(categoryIds)))
          .map((row) => row.amount.abs());

      final list = await query.get();
      final totalExpense =
          list.isEmpty ? 0 : list.fold(0, (prev, amount) => prev + amount);

      print("✅ Expense diperbarui: $totalExpense");

      return totalExpense;
    }).distinct();
  }

  Future<List<TransactionWithCategory>> getTransactionsByMonth(
      int month, int year) async {
    final query = await (select(transactions)
          ..where((t) =>
              t.transaction_date.month.equals(month) &
              t.transaction_date.year.equals(year)))
        .join([
      leftOuterJoin(
          categories, categories.id.equalsExp(transactions.category_id))
    ]).get();

    return query.map((row) {
      return TransactionWithCategory(
        row.readTable(transactions),
        row.readTable(categories),
      );
    }).toList();
  }

  Future<List<TransactionWithCategory>> getAllTransactions() async {
    final query = await (select(transactions)
          ..orderBy([(t) => OrderingTerm.desc(t.transaction_date)]))
        .join([
      leftOuterJoin(
          categories, categories.id.equalsExp(transactions.category_id))
    ]).get();

    return query.map((row) {
      return TransactionWithCategory(
        row.readTable(transactions),
        row.readTable(categories),
      );
    }).toList();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    try {
      final dbFolder = await getApplicationSupportDirectory();
      print('Database folder path: ${dbFolder.path}');
      if (!await dbFolder.exists()) {
        await dbFolder.create(recursive: true);
        print('Database folder created.');
      }

      final file = File(p.join(dbFolder.path, 'db.sqlite'));
      print('Database file path: ${file.path}');

      if (!await file.exists()) {
        await file.create();
        print('Database file created.');
      }

      return NativeDatabase.createInBackground(file);
    } catch (e) {
      print('Error opening database: $e');
      rethrow; // Rethrow error untuk debugging
    }
  });
}
