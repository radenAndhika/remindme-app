import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('remindme.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    if (kIsWeb) {
      return await databaseFactoryFfiWeb.openDatabase(
        filePath,
        options: OpenDatabaseOptions(
          version: 3,
          onCreate: _createDB,
          onUpgrade: _onUpgrade,
        ),
      );
    }
    
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      final dbPath = await databaseFactoryFfi.getDatabasesPath();
      return await databaseFactoryFfi.openDatabase(
        join(dbPath, filePath),
        options: OpenDatabaseOptions(
          version: 3,
          onCreate: _createDB,
          onUpgrade: _onUpgrade,
        ),
      );
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE reminders ADD COLUMN deadline TEXT');
    }
    if (oldVersion < 3) {
      await db.execute("ALTER TABLE reminders ADD COLUMN category TEXT DEFAULT 'Umum'");
      await db.execute('ALTER TABLE reminders ADD COLUMN priorityScore INTEGER DEFAULT 10');
      await db.execute("ALTER TABLE reminders ADD COLUMN priorityLabel TEXT DEFAULT 'Rendah'");
    }
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        profile_image TEXT,
        session_token TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE reminders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        dateTime TEXT NOT NULL,
        location TEXT,
        isCompleted INTEGER DEFAULT 0,
        deadline TEXT,
        category TEXT DEFAULT 'Umum',
        priorityScore INTEGER DEFAULT 10,
        priorityLabel TEXT DEFAULT 'Rendah',
        FOREIGN KEY (userId) REFERENCES users (id)
      )
    ''');


  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
