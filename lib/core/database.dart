import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'finapp.db');
    return await openDatabase(path, version: 5, onCreate: _onCreate, onUpgrade: _onUpgrade);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''CREATE TABLE transactions (
      id INTEGER PRIMARY KEY AUTOINCREMENT, type TEXT NOT NULL, amount REAL NOT NULL,
      category TEXT NOT NULL, account TEXT NOT NULL, note TEXT, date TEXT NOT NULL)''');
    await db.execute('''CREATE TABLE budgets (
      id INTEGER PRIMARY KEY AUTOINCREMENT, category TEXT NOT NULL,
      amount REAL NOT NULL, month TEXT NOT NULL)''');
    await db.execute('''CREATE TABLE goals (
      id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, target_amount REAL NOT NULL,
      current_amount REAL NOT NULL DEFAULT 0, deadline TEXT, created_at TEXT NOT NULL,
      account TEXT, icon TEXT, color TEXT)''');
    await db.execute('''CREATE TABLE bills (
      id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, amount REAL NOT NULL,
      due_day INTEGER NOT NULL, type TEXT NOT NULL, is_active INTEGER NOT NULL DEFAULT 1)''');
    await db.execute('''CREATE TABLE accounts (
      id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL,
      type TEXT NOT NULL, balance REAL NOT NULL DEFAULT 0)''');
    await db.execute('''CREATE TABLE recurring_bills (
      id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, amount REAL NOT NULL,
      category TEXT NOT NULL, frequency TEXT NOT NULL, custom_days INTEGER,
      next_due_date TEXT, account TEXT, note TEXT, created_at TEXT NOT NULL,
      is_active INTEGER NOT NULL DEFAULT 1, auto_pay INTEGER NOT NULL DEFAULT 0)''');
    await db.execute('''CREATE TABLE credit_cards (
      id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, bank TEXT NOT NULL,
      card_number TEXT NOT NULL, credit_limit REAL NOT NULL, current_balance REAL NOT NULL DEFAULT 0,
      bill_day INTEGER NOT NULL, payment_day INTEGER NOT NULL, color TEXT NOT NULL, created_at TEXT NOT NULL)''');
    await db.execute('''CREATE TABLE assets (
      id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, type TEXT NOT NULL,
      amount REAL NOT NULL DEFAULT 0, cost_basis REAL, note TEXT,
      created_at TEXT NOT NULL, updated_at TEXT, icon TEXT)''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try { await db.execute('ALTER TABLE goals ADD COLUMN account TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE goals ADD COLUMN icon TEXT'); } catch (_) {}
      try { await db.execute('ALTER TABLE goals ADD COLUMN color TEXT'); } catch (_) {}
    }
    if (oldVersion < 3) {
      try { await db.execute('''CREATE TABLE IF NOT EXISTS recurring_bills (
        id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, amount REAL NOT NULL,
        category TEXT NOT NULL, frequency TEXT NOT NULL, custom_days INTEGER,
        next_due_date TEXT, account TEXT, note TEXT, created_at TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1, auto_pay INTEGER NOT NULL DEFAULT 0)'''); } catch (_) {}
      try { await db.execute('''CREATE TABLE IF NOT EXISTS credit_cards (
        id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, bank TEXT NOT NULL,
        card_number TEXT NOT NULL, credit_limit REAL NOT NULL, current_balance REAL NOT NULL DEFAULT 0,
        bill_day INTEGER NOT NULL, payment_day INTEGER NOT NULL, color TEXT NOT NULL, created_at TEXT NOT NULL)'''); } catch (_) {}
    }
    if (oldVersion < 4) {
      await db.execute('''CREATE TABLE IF NOT EXISTS assets (
        id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, type TEXT NOT NULL,
        amount REAL NOT NULL DEFAULT 0, cost_basis REAL, note TEXT,
        created_at TEXT NOT NULL, updated_at TEXT, icon TEXT)''');
    }
    if (oldVersion < 5) {
      try { await db.execute('ALTER TABLE recurring_bills ADD COLUMN auto_pay INTEGER NOT NULL DEFAULT 0'); } catch (_) {}
    }
  }

  Future<int> insertTransaction(Map<String, dynamic> row) async =>
      (await database).insert('transactions', row);
  Future<List<Map<String, dynamic>>> getAllTransactions() async =>
      (await database).query('transactions', orderBy: 'date DESC');
  Future<List<Map<String, dynamic>>> getTransactionsByMonth(String month) async =>
      (await database).query('transactions', where: "date LIKE ?", whereArgs: ['$month%'], orderBy: 'date DESC');
  Future<int> updateTransaction(Map<String, dynamic> row) async =>
      (await database).update('transactions', row, where: 'id = ?', whereArgs: [row['id']]);
  Future<int> deleteTransaction(int id) async =>
      (await database).delete('transactions', where: 'id = ?', whereArgs: [id]);

  Future<List<Map<String, dynamic>>> getBudgetsByMonth(String month) async =>
      (await database).query('budgets', where: 'month = ?', whereArgs: [month]);
  Future<int> upsertBudget(Map<String, dynamic> row) async {
    final db = await database;
    final existing = await db.query('budgets', where: 'category = ? AND month = ?', whereArgs: [row['category'], row['month']]);
    if (existing.isEmpty) return db.insert('budgets', row);
    final id = existing.first['id'] as int;
    await db.update('budgets', row, where: 'id = ?', whereArgs: [id]);
    return id;
  }
  Future<int> deleteBudget(int id) async =>
      (await database).delete('budgets', where: 'id = ?', whereArgs: [id]);

  Future<int> insertGoal(Map<String, dynamic> row) async =>
      (await database).insert('goals', row);
  Future<List<Map<String, dynamic>>> getGoals() async =>
      (await database).query('goals', orderBy: 'created_at DESC');
  Future<int> updateGoal(Map<String, dynamic> row) async =>
      (await database).update('goals', row, where: 'id = ?', whereArgs: [row['id']]);
  Future<int> deleteGoal(int id) async =>
      (await database).delete('goals', where: 'id = ?', whereArgs: [id]);

  Future<int> insertBill(Map<String, dynamic> row) async =>
      (await database).insert('bills', row);
  Future<List<Map<String, dynamic>>> getBills() async =>
      (await database).query('bills', where: 'is_active = 1', orderBy: 'due_day ASC');
  Future<int> deleteBill(int id) async =>
      (await database).delete('bills', where: 'id = ?', whereArgs: [id]);

  Future<int> insertRecurringBill(Map<String, dynamic> row) async =>
      (await database).insert('recurring_bills', row);
  Future<List<Map<String, dynamic>>> getRecurringBills() async =>
      (await database).query('recurring_bills', orderBy: 'next_due_date ASC');
  Future<int> updateRecurringBill(Map<String, dynamic> row) async =>
      (await database).update('recurring_bills', row, where: 'id = ?', whereArgs: [row['id']]);
  Future<int> deleteRecurringBill(int id) async =>
      (await database).delete('recurring_bills', where: 'id = ?', whereArgs: [id]);
  Future<List<Map<String, dynamic>>> getUpcomingBills(int days) async {
    final db = await database;
    final now = DateTime.now();
    final today = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final future = now.add(Duration(days: days));
    final cutoff = '${future.year}-${future.month.toString().padLeft(2, '0')}-${future.day.toString().padLeft(2, '0')}';
    return db.query('recurring_bills', where: "is_active = 1 AND next_due_date BETWEEN ? AND ?", whereArgs: [today, cutoff], orderBy: 'next_due_date ASC');
  }

  Future<int> insertCreditCard(Map<String, dynamic> row) async =>
      (await database).insert('credit_cards', row);
  Future<List<Map<String, dynamic>>> getCreditCards() async =>
      (await database).query('credit_cards', orderBy: 'created_at DESC');
  Future<int> updateCreditCard(Map<String, dynamic> row) async =>
      (await database).update('credit_cards', row, where: 'id = ?', whereArgs: [row['id']]);
  Future<int> deleteCreditCard(int id) async =>
      (await database).delete('credit_cards', where: 'id = ?', whereArgs: [id]);

  Future<int> insertAsset(Map<String, dynamic> row) async =>
      (await database).insert('assets', row);
  Future<List<Map<String, dynamic>>> getAssets() async =>
      (await database).query('assets', orderBy: 'created_at DESC');
  Future<int> updateAsset(Map<String, dynamic> row) async =>
      (await database).update('assets', row, where: 'id = ?', whereArgs: [row['id']]);
  Future<int> deleteAsset(int id) async =>
      (await database).delete('assets', where: 'id = ?', whereArgs: [id]);

  // ── Account CRUD ──
  Future<List<Map<String, dynamic>>> getAccounts() async =>
      (await database).query('accounts', orderBy: 'id ASC');
  Future<int> insertAccount(Map<String, dynamic> row) async =>
      (await database).insert('accounts', row);
  Future<int> updateAccount(Map<String, dynamic> row) async =>
      (await database).update('accounts', row, where: 'id = ?', whereArgs: [row['id']]);
  Future<int> deleteAccount(int id) async =>
      (await database).delete('accounts', where: 'id = ?', whereArgs: [id]);
  Future<void> seedDefaultAccounts() async {
    final existing = await getAccounts();
    if (existing.isEmpty) {
      final defaults = ['现金', '银行卡', '微信', '支付宝'];
      for (final name in defaults) {
        await insertAccount({'name': name, 'type': 'default', 'balance': 0.0});
      }
    }
  }
}
