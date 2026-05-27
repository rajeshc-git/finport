import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:finport/models/expense.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  
  // High-security Keychain storage that survives app deletion (100% free)
  final _secureStorage = const FlutterSecureStorage();

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('finport.db');
    
    // Auto-restore from Keychain if local database was wiped/deleted
    await checkForAndRestoreKeychainBackup();
    
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        date TEXT NOT NULL,
        note TEXT NOT NULL
      )
    ''');

    await db.execute('CREATE INDEX idx_expenses_date ON expenses (date)');
  }

  // --- CRUD OPERATIONS ---

  Future<int> insertExpense(Expense expense) async {
    final db = await instance.database;
    final id = await db.insert('expenses', expense.toMap());
    
    // Auto-sync database JSON to Keychain in background
    syncDatabaseToKeychain();
    
    return id;
  }

  Future<List<Expense>> getAllExpenses() async {
    final db = await instance.database;
    final result = await db.query('expenses', orderBy: 'date DESC');
    return result.map((json) => Expense.fromMap(json)).toList();
  }

  Future<int> updateExpense(Expense expense) async {
    final db = await instance.database;
    final count = await db.update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
    
    syncDatabaseToKeychain();
    
    return count;
  }

  Future<int> deleteExpense(int id) async {
    final db = await instance.database;
    final count = await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
    
    syncDatabaseToKeychain();
    
    return count;
  }

  Future<List<Expense>> getExpensesForMonth(String yearMonth) async {
    final db = await instance.database;
    final result = await db.query(
      'expenses',
      where: "date LIKE ?",
      whereArgs: ['$yearMonth%'],
      orderBy: 'date DESC',
    );
    return result.map((json) => Expense.fromMap(json)).toList();
  }

  // --- BACKUP & RESTORE PIPELINES ---

  Future<String> exportToJson() async {
    final expenses = await getAllExpenses();
    final jsonList = expenses.map((e) => e.toJson()).toList();
    return const JsonEncoder.withIndent('  ').convert(jsonList);
  }

  Future<bool> importFromJson(String jsonString) async {
    final db = await instance.database;

    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is! List) {
        throw const FormatException(
          'Restore failed: Backup format must be a list of transactions.',
        );
      }

      final List<Expense> importedExpenses = [];
      for (var item in decoded) {
        if (item is! Map<String, dynamic>) {
          throw const FormatException(
            'Restore failed: Invalid item structure inside backup.',
          );
        }

        if (!item.containsKey('amount') ||
            !item.containsKey('category') ||
            !item.containsKey('date')) {
          throw const FormatException(
            'Restore failed: Missing required fields (amount, category, date).',
          );
        }

        importedExpenses.add(Expense.fromJson(item));
      }

      await db.transaction((txn) async {
        await txn.delete('expenses'); 
        for (var expense in importedExpenses) {
          await txn.insert('expenses', {
            'amount': expense.amount,
            'category': expense.category,
            'date': expense.date.toIso8601String(),
            'note': expense.note,
          });
        }
      });

      // Sync the newly restored database to Keychain
      syncDatabaseToKeychain();

      return true;
    } catch (e) {
      rethrow;
    }
  }

  /// Securely purge both the local SQLite database and the iOS Secure Keychain backup
  Future<void> wipeAllData() async {
    final db = await instance.database;
    await db.transaction((txn) async {
      await txn.delete('expenses');
    });
    // Erase the Keychain entry completely
    await _secureStorage.delete(key: 'finport_db_backup');
  }

  // --- KEYCHAIN AUTO-SYNC PIPELINE ---

  /// Silently backup entire database in JSON format to iOS Secure Keychain
  Future<void> syncDatabaseToKeychain() async {
    try {
      final jsonString = await exportToJson();
      await _secureStorage.write(key: 'finport_db_backup', value: jsonString);
    } catch (e) {
      // Fail silently to prevent breaking UI lifecycle in case of latency
      print('Keychain backup error: $e');
    }
  }

  /// Query the Keychain and restore empty local database if a backup string exists
  Future<bool> checkForAndRestoreKeychainBackup() async {
    try {
      final backupJson = await _secureStorage.read(key: 'finport_db_backup');
      if (backupJson != null && backupJson.isNotEmpty) {
        // Query database via direct helper query to check if it has items
        final db = _database;
        if (db != null) {
          final countResult = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM expenses'),
          );
          if (countResult == 0) {
            // Database is empty (new install), run restore pipeline
            final success = await importFromJson(backupJson);
            return success;
          }
        }
      }
    } catch (e) {
      print('Keychain auto-restore error: $e');
    }
    return false;
  }

  Future close() async {
    final db = _database;
    if (db != null) {
      await db.close();
    }
  }
}
