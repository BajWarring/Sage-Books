import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

class SqliteImporterService {
  Database? _db;

  Future<void> openDb(String path) async {
    try {
      _db = await openDatabase(
        path,
        readOnly: true,
        onOpen: (db) {
          debugPrint("Database at $path opened successfully.");
        },
      );
    } catch (e) {
      debugPrint("Error opening database: $e");
      throw Exception(
          "Could not open database file. Is it a valid SQLite file?");
    }
  }

  void closeDb() {
    _db?.close();
    _db = null;
  }

  Future<List<String>> getTables() async {
    if (_db == null) throw Exception("Database is not open.");

    // --- *** THIS IS THE FIX *** ---
    // The previous query filtered out tables named 'sqlite_%' or 'android_metadata'.
    // This new query selects ALL tables, fixing the import issue.
    final List<Map<String, dynamic>> tables = await _db!
        .rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
    // --- *** END OF FIX *** ---

    return tables.map((row) => row['name'] as String).toList();
  }

  Future<List<String>> getColumnNames(String tableName) async {
    if (_db == null) throw Exception("Database is not open.");
    final List<Map<String, dynamic>> tableInfo =
        await _db!.rawQuery('PRAGMA table_info("$tableName")');
    return tableInfo.map((col) => col['name'] as String).toList();
  }

  Future<List<List<dynamic>>> getAllData(String tableName) async {
    if (_db == null) throw Exception("Database is not open.");
    final List<Map<String, dynamic>> dataMaps =
        await _db!.rawQuery('SELECT * FROM "$tableName"');
    if (dataMaps.isEmpty) {
      throw Exception("The selected table '$tableName' has no data.");
    }

    final headers = dataMaps.first.keys.toList();

    List<List<dynamic>> allRows = [];
    for (var map in dataMaps) {
      List<dynamic> row = [];
      for (var header in headers) {
        row.add(map[header]);
      }
      allRows.add(row);
    }

    return allRows;
  }
}
