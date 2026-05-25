class CustomDocumentTemplate {
  const CustomDocumentTemplate({
    this.id,
    required this.categoryName,
    required this.title,
    this.description,
    this.templateFilePath,
    this.editorContent,
    this.pageSize = 'A4',
    this.orientation = 'portrait',
    this.marginTop = 32,
    this.marginRight = 32,
    this.marginBottom = 32,
    this.marginLeft = 32,
    this.textDirection = 'rtl',
    this.baseFontSize = 14,
    this.lineSpacing = 6,
    required this.createdAt,
    this.fieldsCount = 0,
  });

  final int? id;
  final String categoryName;
  final String title;
  final String? description;
  final String? templateFilePath;
  final String? editorContent;
  final String pageSize;
  final String orientation;
  final double marginTop;
  final double marginRight;
  final double marginBottom;
  final double marginLeft;
  final String textDirection;
  final double baseFontSize;
  final double lineSpacing;
  final DateTime createdAt;
  final int fieldsCount;

  factory CustomDocumentTemplate.fromMap(Map<String, Object?> map) {
    return CustomDocumentTemplate(
      id: map['id'] as int?,
      categoryName: (map['category_name'] as String?) ?? 'طلب خطي',
      title: map['title'] as String,
      description: map['description'] as String?,
      templateFilePath: map['template_file_path'] as String?,
      editorContent: map['editor_content'] as String?,
      pageSize: (map['page_size'] as String?) ?? 'A4',
      orientation: (map['orientation'] as String?) ?? 'portrait',
      marginTop: _toDouble(map['margin_top'], 32),
      marginRight: _toDouble(map['margin_right'], 32),
      marginBottom: _toDouble(map['margin_bottom'], 32),
      marginLeft: _toDouble(map['margin_left'], 32),
      textDirection: (map['text_direction'] as String?) ?? 'rtl',
      baseFontSize: _toDouble(map['base_font_size'], 14),
      lineSpacing: _toDouble(map['line_spacing'], 6),
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
      fieldsCount: (map['fields_count'] as int?) ?? 0,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'category_name': categoryName,
      'title': title,
      'description': description,
      'template_file_path': templateFilePath,
      'editor_content': editorContent,
      'page_size': pageSize,
      'orientation': orientation,
      'margin_top': marginTop,
      'margin_right': marginRight,
      'margin_bottom': marginBottom,
      'margin_left': marginLeft,
      'text_direction': textDirection,
      'base_font_size': baseFontSize,
      'line_spacing': lineSpacing,
      'created_at': createdAt.toIso8601String(),
    };
  }

  static double _toDouble(Object? value, double fallback) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }
}
