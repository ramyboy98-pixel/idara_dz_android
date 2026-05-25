import '../../core/database/database_helper.dart';
import '../models/archive_item.dart';

class ArchiveRepository {
  Future<List<ArchiveItem>> getItems() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('archive_items', orderBy: 'id DESC');
    return rows.map(ArchiveItem.fromMap).toList();
  }
}
