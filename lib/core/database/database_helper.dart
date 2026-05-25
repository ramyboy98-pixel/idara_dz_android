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
    return openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
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
        category_name TEXT NOT NULL DEFAULT 'طلب خطي',
        title TEXT NOT NULL,
        description TEXT,
        template_file_path TEXT,
        editor_content TEXT,
        page_size TEXT NOT NULL DEFAULT 'A4',
        orientation TEXT NOT NULL DEFAULT 'portrait',
        margin_top REAL NOT NULL DEFAULT 32,
        margin_right REAL NOT NULL DEFAULT 32,
        margin_bottom REAL NOT NULL DEFAULT 32,
        margin_left REAL NOT NULL DEFAULT 32,
        text_direction TEXT NOT NULL DEFAULT 'rtl',
        base_font_size REAL NOT NULL DEFAULT 14,
        line_spacing REAL NOT NULL DEFAULT 6,
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

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _addColumnIfMissing(
        db,
        tableName: 'document_templates',
        columnName: 'category_name',
        sql: "ALTER TABLE document_templates ADD COLUMN category_name TEXT NOT NULL DEFAULT 'طلب خطي'",
      );
      await _addColumnIfMissing(
        db,
        tableName: 'document_templates',
        columnName: 'template_file_path',
        sql: 'ALTER TABLE document_templates ADD COLUMN template_file_path TEXT',
      );
    }

    if (oldVersion < 3) {
      await _addColumnIfMissing(
        db,
        tableName: 'document_templates',
        columnName: 'editor_content',
        sql: 'ALTER TABLE document_templates ADD COLUMN editor_content TEXT',
      );
      await _addColumnIfMissing(
        db,
        tableName: 'document_templates',
        columnName: 'page_size',
        sql: "ALTER TABLE document_templates ADD COLUMN page_size TEXT NOT NULL DEFAULT 'A4'",
      );
      await _addColumnIfMissing(
        db,
        tableName: 'document_templates',
        columnName: 'orientation',
        sql: "ALTER TABLE document_templates ADD COLUMN orientation TEXT NOT NULL DEFAULT 'portrait'",
      );
      await _addColumnIfMissing(
        db,
        tableName: 'document_templates',
        columnName: 'margin_top',
        sql: 'ALTER TABLE document_templates ADD COLUMN margin_top REAL NOT NULL DEFAULT 32',
      );
      await _addColumnIfMissing(
        db,
        tableName: 'document_templates',
        columnName: 'margin_right',
        sql: 'ALTER TABLE document_templates ADD COLUMN margin_right REAL NOT NULL DEFAULT 32',
      );
      await _addColumnIfMissing(
        db,
        tableName: 'document_templates',
        columnName: 'margin_bottom',
        sql: 'ALTER TABLE document_templates ADD COLUMN margin_bottom REAL NOT NULL DEFAULT 32',
      );
      await _addColumnIfMissing(
        db,
        tableName: 'document_templates',
        columnName: 'margin_left',
        sql: 'ALTER TABLE document_templates ADD COLUMN margin_left REAL NOT NULL DEFAULT 32',
      );
      await _addColumnIfMissing(
        db,
        tableName: 'document_templates',
        columnName: 'text_direction',
        sql: "ALTER TABLE document_templates ADD COLUMN text_direction TEXT NOT NULL DEFAULT 'rtl'",
      );
      await _addColumnIfMissing(
        db,
        tableName: 'document_templates',
        columnName: 'base_font_size',
        sql: 'ALTER TABLE document_templates ADD COLUMN base_font_size REAL NOT NULL DEFAULT 14',
      );
      await _addColumnIfMissing(
        db,
        tableName: 'document_templates',
        columnName: 'line_spacing',
        sql: 'ALTER TABLE document_templates ADD COLUMN line_spacing REAL NOT NULL DEFAULT 6',
      );
    }
  }

  Future<void> _addColumnIfMissing(
    Database db, {
    required String tableName,
    required String columnName,
    required String sql,
  }) async {
    final columns = await db.rawQuery('PRAGMA table_info($tableName)');
    final exists = columns.any((column) => column['name'] == columnName);
    if (!exists) {
      await db.execute(sql);
    }
  }

  Future<void> _seed(Database db) async {
    final now = DateTime.now().toIso8601String();

    final categories = [
      {'name': 'طلب خطي', 'icon': '📄'},
      {'name': 'تصريح شرفي', 'icon': '📝'},
      {'name': 'سيرة ذاتية', 'icon': '👤'},
      {'name': 'فاتورة', 'icon': '🧾'},
    ];

    for (final category in categories) {
      await db.insert('document_categories', {
        'name': category['name'],
        'icon': category['icon'],
        'created_at': now,
      });
    }

    await db.insert('service_links', {
      'title': 'بريد الجزائر',
      'url': 'https://www.poste.dz',
      'category': 'خدمات الكترونية',
      'icon_asset': 'assets/services/algerie_poste.png',
      'created_at': now,
    });
  }
}
