import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('cards.db');
    return _database!;
  }

  Future<Database> _initDB(String dbName) async {
    String path = join(await getDatabasesPath(), dbName);
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE Folders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        folder_name TEXT NOT NULL,
        timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE TABLE Cards (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        suit TEXT NOT NULL,
        image_url TEXT NOT NULL,
        folder_id INTEGER,
        FOREIGN KEY (folder_id) REFERENCES Folders (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE CardsInFolder (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        card_id INTEGER,
        folder_id INTEGER,
        FOREIGN KEY (card_id) REFERENCES Cards(id),
        FOREIGN KEY (folder_id) REFERENCES Folders(id)
      )
    ''');

    await _prepopulateCards(db);
  }

  Future<void> _prepopulateCards(Database db) async {
    await db.delete('Folders');
    await db.delete('Cards');
    await db.delete('CardsInFolder');
    List<Map<String, dynamic>> suits = [
      {'name': 'Hearts', 'folderId': 1},
      {'name': 'Spades', 'folderId': 2},
      {'name': 'Diamonds', 'folderId': 3},
      {'name': 'Clubs', 'folderId': 4},
    ];

    for (var suit in suits) {
      await db.insert('Folders', {'folder_name': suit['name']});
    }

    List<String> cardNames = [
      'Ace',
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      '10',
      'J',
      'Q',
      'K'
    ];

    for (var suit in suits) {
      for (var cardName in cardNames) {
        String cardImageName = '${cardName}${suit['name'].substring(0, 1)}.png';
        String imageUrl = 'img/$cardImageName';
        await db.insert('Cards', {
          'name': cardName,
          'suit': suit['name'],
          'image_url': imageUrl,
          'folder_id': suit['folderId'],
        });
      }
    }
  }

  Future<void> _addSelectedCardsToFolder(
      List<int> selectedCardIds, int folderId) async {
    final db = DatabaseHelper();
    final database = await db.database;

    try {
      await database.transaction((txn) async {
        for (int cardId in selectedCardIds) {
          await txn.insert('CardsInFolder', {
            'card_id': cardId,
            'folder_id': folderId,
          });
        }
      });
    } catch (e) {
      print('Error adding cards: $e');
    }
  }

  Future<void> resetDatabase() async {
    String path = join(await getDatabasesPath(), 'cards.db');
    await deleteDatabase(path);
    _database = await _initDB('cards.db');
  }
}
