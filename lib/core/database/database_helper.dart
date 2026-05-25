import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'idara_dz.db');
    return openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE document_categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE document_templates (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id INTEGER,
        title TEXT NOT NULL,
        description TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE template_fields (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        template_id INTEGER NOT NULL,
        label TEXT NOT NULL,
        key_name TEXT NOT NULL,
        field_type TEXT NOT NULL DEFAULT 'text',
        sort_order INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE archive_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        type TEXT NOT NULL,
        file_path TEXT,
        customer_name TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE service_links (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        url TEXT NOT NULL,
        category TEXT,
        icon_asset TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await _seed(db);
  }

  Future<void> _seed(Database db) async {
    final now = DateTime.now().toIso8601String();

    await db.insert('document_categories', {
      'name': 'طلب خطي',
      'icon': '📄',
      'created_at': now,
    });

    await db.insert('document_categories', {
      'name': 'تصريحات',
      'icon': '📝',
      'created_at': now,
    });

    await db.insert('service_links', {
      'title': 'بريد الجزائر',
      'url': 'https://www.poste.dz',
      'category': 'خدمات الكترونية',
      'icon_asset': 'assets/services/algerie_poste.png',
      'created_at': now,
    });
  }
}
