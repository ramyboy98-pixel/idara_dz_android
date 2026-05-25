class DocumentCategory {
  const DocumentCategory({
    required this.id,
    required this.name,
    this.icon,
  });

  final int id;
  final String name;
  final String? icon;

  factory DocumentCategory.fromMap(Map<String, Object?> map) {
    return DocumentCategory(
      id: map['id'] as int,
      name: map['name'] as String,
      icon: map['icon'] as String?,
    );
  }
}
