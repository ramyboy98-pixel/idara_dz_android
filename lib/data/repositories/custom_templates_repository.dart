
import '../../core/database/database_helper.dart';
import '../models/custom_document_template.dart';
import '../models/template_field.dart';

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
    required String? editorContent,
    required TemplatePageSettings pageSettings,
    required List<NewTemplateField> fields,
  }) async {
    final db = await DatabaseHelper.instance.database;
    return db.transaction((txn) async {
      final templateId = await txn.insert('document_templates', {
        'category_name': categoryName,
        'title': title,
        'description': description,
        'template_file_path': templateFilePath,
        'editor_content': editorContent,
        'page_size': pageSettings.pageSize,
        'orientation': pageSettings.orientation,
        'margin_top': pageSettings.marginTop,
        'margin_right': pageSettings.marginRight,
        'margin_bottom': pageSettings.marginBottom,
        'margin_left': pageSettings.marginLeft,
        'text_direction': pageSettings.textDirection,
        'base_font_size': pageSettings.baseFontSize,
        'line_spacing': pageSettings.lineSpacing,
        'created_at': DateTime.now().toIso8601String(),
      });

      for (var i = 0; i < fields.length; i++) {
        final field = fields[i];
        await txn.insert('template_fields', {
          'template_id': templateId,
          'label': field.label,
          'key_name': _makeKeyName(field.label, i),
          'field_type': field.fieldType,
          'sort_order': i,
        });
      }

      return templateId;
    });
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

  Future<void> deleteTemplate(int templateId) async {
    final db = await DatabaseHelper.instance.database;
    await db.transaction((txn) async {
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


class TemplatePageSettings {
  const TemplatePageSettings({
    this.pageSize = 'A4',
    this.orientation = 'portrait',
    this.marginTop = 32,
    this.marginRight = 32,
    this.marginBottom = 32,
    this.marginLeft = 32,
    this.textDirection = 'rtl',
    this.baseFontSize = 14,
    this.lineSpacing = 6,
  });

  final String pageSize;
  final String orientation;
  final double marginTop;
  final double marginRight;
  final double marginBottom;
  final double marginLeft;
  final String textDirection;
  final double baseFontSize;
  final double lineSpacing;
}
