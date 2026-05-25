class CustomDocumentTemplate {
  const CustomDocumentTemplate({
    this.id,
    required this.categoryName,
    required this.title,
    this.description,
    this.templateFilePath,
    required this.createdAt,
    this.fieldsCount = 0,
  });

  final int? id;
  final String categoryName;
  final String title;
  final String? description;
  final String? templateFilePath;
  final DateTime createdAt;
  final int fieldsCount;

  factory CustomDocumentTemplate.fromMap(Map<String, Object?> map) {
    return CustomDocumentTemplate(
      id: map['id'] as int?,
      categoryName: (map['category_name'] as String?) ?? 'طلب خطي',
      title: map['title'] as String,
      description: map['description'] as String?,
      templateFilePath: map['template_file_path'] as String?,
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
      'created_at': createdAt.toIso8601String(),
    };
  }
}
