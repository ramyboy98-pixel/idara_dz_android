import '../../core/database/database_helper.dart';
import '../models/custom_document_template.dart';
import '../models/template_field.dart';
import '../models/template_field_position.dart';

class CustomTemplatesRepository {
  const CustomTemplatesRepository();

  Future<List<CustomDocumentTemplate>> getTemplates(String categoryName) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.rawQuery(
      '''
      SELECT document_templates.*, COUNT(template_fields.id) AS fields_count
      FROM document_templates
      LEFT JOIN template_fields
        ON template_fields.template_id = document_templates.id
      WHERE document_templates.category_name = ?
      GROUP BY document_templates.id
      ORDER BY document_templates.id DESC
      ''',
      [categoryName],
    );
    return rows.map(CustomDocumentTemplate.fromMap).toList();
  }

  Future<int> addTemplateWithFields({
    required String categoryName,
    required String title,
    required String description,
    required String? templateFilePath,
    required List<NewTemplateField> fields,
  }) async {
    final db = await DatabaseHelper.instance.database;
    return db.transaction((txn) async {
      final templateId = await txn.insert('document_templates', {
        'category_name': categoryName,
        'title': title,
        'description': description,
        'template_file_path': templateFilePath,
        'created_at': DateTime.now().toIso8601String(),
      });

      for (var i = 0; i < fields.length; i++) {
        final field = fields[i];
        final fieldId = await txn.insert('template_fields', {
          'template_id': templateId,
          'label': field.label,
          'key_name': _makeKeyName(field.label, i),
          'field_type': field.fieldType,
          'sort_order': i,
        });

        await txn.insert('template_field_positions', {
          'template_id': templateId,
          'field_id': fieldId,
          'x': 0.78,
          'y': 0.16 + (i * 0.055),
          'font_size': 12,
        });
      }

      return templateId;
    });
  }

  Future<CustomDocumentTemplate?> getTemplate(int templateId) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.rawQuery(
      '''
      SELECT document_templates.*, COUNT(template_fields.id) AS fields_count
      FROM document_templates
      LEFT JOIN template_fields
        ON template_fields.template_id = document_templates.id
      WHERE document_templates.id = ?
      GROUP BY document_templates.id
      LIMIT 1
      ''',
      [templateId],
    );
    if (rows.isEmpty) return null;
    return CustomDocumentTemplate.fromMap(rows.first);
  }

  Future<List<TemplateField>> getFields(int templateId) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'template_fields',
      where: 'template_id = ?',
      whereArgs: [templateId],
      orderBy: 'sort_order ASC',
    );
    return rows.map(TemplateField.fromMap).toList();
  }

  Future<List<TemplateFieldPosition>> getFieldPositions(int templateId) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'template_field_positions',
      where: 'template_id = ?',
      whereArgs: [templateId],
      orderBy: 'id ASC',
    );
    return rows.map(TemplateFieldPosition.fromMap).toList();
  }

  Future<void> saveFieldPositions({
    required int templateId,
    required List<TemplateFieldPosition> positions,
  }) async {
    final db = await DatabaseHelper.instance.database;
    await db.transaction((txn) async {
      await txn.delete(
        'template_field_positions',
        where: 'template_id = ?',
        whereArgs: [templateId],
      );
      for (final position in positions) {
        await txn.insert('template_field_positions', {
          'template_id': templateId,
          'field_id': position.fieldId,
          'x': position.x.clamp(0.0, 1.0),
          'y': position.y.clamp(0.0, 1.0),
          'font_size': position.fontSize,
        });
      }
    });
  }

  Future<void> deleteTemplate(int templateId) async {
    final db = await DatabaseHelper.instance.database;
    await db.transaction((txn) async {
      await txn.delete(
        'template_field_positions',
        where: 'template_id = ?',
        whereArgs: [templateId],
      );
      await txn.delete(
        'template_fields',
        where: 'template_id = ?',
        whereArgs: [templateId],
      );
      await txn.delete(
        'document_templates',
        where: 'id = ?',
        whereArgs: [templateId],
      );
    });
  }

  String _makeKeyName(String label, int index) {
    final normalized = label
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'[^\u0600-\u06FFa-z0-9_]'), '');
    if (normalized.isEmpty) return 'field_$index';
    return normalized;
  }
}

class NewTemplateField {
  const NewTemplateField({
    required this.label,
    required this.fieldType,
  });

  final String label;
  final String fieldType;
}
