class ArchiveItem {
  const ArchiveItem({
    required this.id,
    required this.title,
    required this.type,
    required this.createdAt,
    this.filePath,
    this.customerName,
  });

  final int id;
  final String title;
  final String type;
  final String createdAt;
  final String? filePath;
  final String? customerName;

  factory ArchiveItem.fromMap(Map<String, Object?> map) {
    return ArchiveItem(
      id: map['id'] as int,
      title: map['title'] as String,
      type: map['type'] as String,
      filePath: map['file_path'] as String?,
      customerName: map['customer_name'] as String?,
      createdAt: map['created_at'] as String,
    );
  }
}
