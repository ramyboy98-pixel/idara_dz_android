import '../../core/database/database_helper.dart';
import '../models/document_category.dart';

class DocumentsRepository {
  Future<List<DocumentCategory>> getCategories() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('document_categories', orderBy: 'id ASC');
    return rows.map(DocumentCategory.fromMap).toList();
  }
}
