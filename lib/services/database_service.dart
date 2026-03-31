import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import '../models/lotto_round.dart';
import 'lotto_analyzer.dart';

class SavedNumbers {
  final int? id;
  final List<int> numbers;
  final String strategy;
  final String createdAt;
  final int? matchCount;
  final bool? checked;

  SavedNumbers({
    this.id,
    required this.numbers,
    required this.strategy,
    required this.createdAt,
    this.matchCount,
    this.checked,
  });

  Map<String, dynamic> toMap() {
    return {
      'num1': numbers[0],
      'num2': numbers[1],
      'num3': numbers[2],
      'num4': numbers[3],
      'num5': numbers[4],
      'num6': numbers[5],
      'strategy': strategy,
      'created_at': createdAt,
      'match_count': matchCount,
      'checked': (checked ?? false) ? 1 : 0,
    };
  }

  factory SavedNumbers.fromMap(Map<String, dynamic> map) {
    return SavedNumbers(
      id: map['id'] as int?,
      numbers: [
        map['num1'] as int,
        map['num2'] as int,
        map['num3'] as int,
        map['num4'] as int,
        map['num5'] as int,
        map['num6'] as int,
      ],
      strategy: map['strategy'] as String,
      createdAt: map['created_at'] as String,
      matchCount: map['match_count'] as int?,
      checked: (map['checked'] as int?) == 1,
    );
  }
}

class DatabaseService {
  // 웹용 인메모리 저장소
  static final List<SavedNumbers> _memoryStore = [];
  static int _nextId = 1;

  // 네이티브용 SQLite
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/lotto_analyzer.db';
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE saved_numbers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            num1 INTEGER NOT NULL,
            num2 INTEGER NOT NULL,
            num3 INTEGER NOT NULL,
            num4 INTEGER NOT NULL,
            num5 INTEGER NOT NULL,
            num6 INTEGER NOT NULL,
            strategy TEXT NOT NULL,
            created_at TEXT NOT NULL,
            match_count INTEGER,
            checked INTEGER DEFAULT 0
          )
        ''');
      },
    );
  }

  Future<int> saveNumbers(
    List<int> numbers,
    AnalysisStrategy strategy, {
    bool isNeural = false,
  }) async {
    final strategyName = isNeural ? 'neural' : strategy.name;
    if (kIsWeb) {
      final id = _nextId++;
      _memoryStore.insert(
        0,
        SavedNumbers(
          id: id,
          numbers: numbers,
          strategy: strategyName,
          createdAt: DateTime.now().toIso8601String(),
        ),
      );
      return id;
    }

    final db = await database;
    final saved = SavedNumbers(
      numbers: numbers,
      strategy: strategyName,
      createdAt: DateTime.now().toIso8601String(),
    );
    return db.insert('saved_numbers', saved.toMap());
  }

  Future<List<SavedNumbers>> getSavedNumbers() async {
    if (kIsWeb) return List.from(_memoryStore);

    final db = await database;
    final maps = await db.query(
      'saved_numbers',
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => SavedNumbers.fromMap(m)).toList();
  }

  Future<int> checkWinning(int id, LottoRound winningRound) async {
    if (kIsWeb) {
      final idx = _memoryStore.indexWhere((s) => s.id == id);
      if (idx == -1) return 0;
      final saved = _memoryStore[idx];
      final matchCount =
          saved.numbers.where((n) => winningRound.numbers.contains(n)).length;
      _memoryStore[idx] = SavedNumbers(
        id: saved.id,
        numbers: saved.numbers,
        strategy: saved.strategy,
        createdAt: saved.createdAt,
        matchCount: matchCount,
        checked: true,
      );
      return matchCount;
    }

    final db = await database;
    final maps = await db.query(
      'saved_numbers',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return 0;

    final saved = SavedNumbers.fromMap(maps.first);
    final matchCount =
        saved.numbers.where((n) => winningRound.numbers.contains(n)).length;

    await db.update(
      'saved_numbers',
      {'match_count': matchCount, 'checked': 1},
      where: 'id = ?',
      whereArgs: [id],
    );

    return matchCount;
  }

  Future<void> checkAllAgainstRound(LottoRound winningRound) async {
    if (kIsWeb) {
      for (int i = 0; i < _memoryStore.length; i++) {
        final saved = _memoryStore[i];
        if (saved.checked == true) continue;
        final matchCount =
            saved.numbers.where((n) => winningRound.numbers.contains(n)).length;
        _memoryStore[i] = SavedNumbers(
          id: saved.id,
          numbers: saved.numbers,
          strategy: saved.strategy,
          createdAt: saved.createdAt,
          matchCount: matchCount,
          checked: true,
        );
      }
      return;
    }

    final db = await database;
    final unchecked = await db.query(
      'saved_numbers',
      where: 'checked = 0',
    );

    for (final map in unchecked) {
      final saved = SavedNumbers.fromMap(map);
      final matchCount =
          saved.numbers.where((n) => winningRound.numbers.contains(n)).length;
      await db.update(
        'saved_numbers',
        {'match_count': matchCount, 'checked': 1},
        where: 'id = ?',
        whereArgs: [saved.id],
      );
    }
  }

  Future<void> deleteNumber(int id) async {
    if (kIsWeb) {
      _memoryStore.removeWhere((s) => s.id == id);
      return;
    }

    final db = await database;
    await db.delete('saved_numbers', where: 'id = ?', whereArgs: [id]);
  }
}
