class ServiceLink {
  const ServiceLink({
    required this.id,
    required this.title,
    required this.url,
    this.category,
    this.iconAsset,
  });

  final int id;
  final String title;
  final String url;
  final String? category;
  final String? iconAsset;

  factory ServiceLink.fromMap(Map<String, Object?> map) {
    return ServiceLink(
      id: map['id'] as int,
      title: map['title'] as String,
      url: map['url'] as String,
      category: map['category'] as String?,
      iconAsset: map['icon_asset'] as String?,
    );
  }
}
