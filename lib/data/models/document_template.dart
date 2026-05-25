class DocumentTemplate {
  const DocumentTemplate({
    required this.id,
    required this.title,
    this.categoryId,
    this.description,
  });

  final int id;
  final int? categoryId;
  final String title;
  final String? description;

  factory DocumentTemplate.fromMap(Map<String, Object?> map) {
    return DocumentTemplate(
      id: map['id'] as int,
      categoryId: map['category_id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String?,
    );
  }
}
