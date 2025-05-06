import 'package:drift/drift.dart';
import 'package:last_money/models/database.dart';

class AuthService {
  final AppDb db = AppDb();

  // LOGIN
  Future<User?> login(String email, String password) async {
    final result = await (db.select(db.users)
          ..where(
              (tbl) => tbl.email.equals(email) & tbl.password.equals(password)))
        .getSingleOrNull();
    return result;
  }

  // REGISTER
  Future<User?> register(String email, String password) async {
    // Cek apakah email sudah ada
    final existingUser = await (db.select(db.users)
          ..where((tbl) => tbl.email.equals(email)))
        .get();

    if (existingUser.isNotEmpty) {
      return null; // Email sudah terdaftar
    }

    // Insert user baru
    final newUser = await db.into(db.users).insertReturning(
          UsersCompanion.insert(
            email: email,
            password: password,
            createdAt: DateTime.now(),
          ),
        );

    return newUser;
  }
}
