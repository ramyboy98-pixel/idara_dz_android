import '../../core/database/database_helper.dart';
import '../models/service_link.dart';

class ServicesRepository {
  Future<List<ServiceLink>> getLinks() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('service_links', orderBy: 'id DESC');
    return rows.map(ServiceLink.fromMap).toList();
  }
}
