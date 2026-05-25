import '../../core/database/database_helper.dart';
import '../models/archive_item.dart';

class ArchiveRepository {
  Future<List<ArchiveItem>> getItems() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('archive_items', orderBy: 'id DESC');
    return rows.map(ArchiveItem.fromMap).toList();
  }

  Future<int> addPdfItem({
    required String title,
    required String filePath,
    String? customerName,
  }) async {
    final db = await DatabaseHelper.instance.database;
    return db.insert('archive_items', {
      'title': title,
      'type': 'PDF',
      'file_path': filePath,
      'customer_name': customerName,
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}
