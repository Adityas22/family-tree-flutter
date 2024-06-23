import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB('users.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    const userTable = '''
    CREATE TABLE users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT NOT NULL,
      password TEXT NOT NULL
    )
    ''';

    const familyTable = '''
    CREATE TABLE family_members (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      gender TEXT NOT NULL,
      parent_id INTEGER,
      user_id INTEGER NOT NULL,
      FOREIGN KEY (user_id) REFERENCES users (id)
    )
    ''';

    await db.execute(userTable);
    await db.execute(familyTable);
  }

  Future<int> createUser(String username, String password) async {
    final db = await instance.database;
    final data = {
      'username': username,
      'password': password,
    };
    return await db.insert('users', data);
  }

  Future<Map<String, dynamic>?> getUser(String username) async {
    final db = await instance.database;
    final maps = await db.query(
      'users',
      columns: ['id', 'username', 'password'],
      where: 'username = ?',
      whereArgs: [username],
    );

    if (maps.isNotEmpty) {
      return maps.first;
    } else {
      return null;
    }
  }

  Future<int> createFamilyMember(String name, String gender, int userId,
      {int? parentId}) async {
    final db = await instance.database;
    final data = {
      'name': name,
      'gender': gender,
      'parent_id': parentId,
      'user_id': userId,
    };
    return await db.insert('family_members', data);
  }

  Future<List<Map<String, dynamic>>> getFamilyMembers(int userId) async {
    final db = await instance.database;
    return await db.query(
      'family_members',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  Future<int> updateFamilyMember(int id, String name, String gender) async {
    final db = await instance.database;
    final data = {
      'name': name,
      'gender': gender,
    };
    return await db.update(
      'family_members',
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteFamilyMember(int id) async {
    final db = await instance.database;
    return await db.delete(
      'family_members',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
