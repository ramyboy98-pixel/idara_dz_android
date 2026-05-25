class TemplateField {
  const TemplateField({
    this.id,
    required this.templateId,
    required this.label,
    required this.keyName,
    required this.fieldType,
    required this.sortOrder,
  });

  final int? id;
  final int templateId;
  final String label;
  final String keyName;
  final String fieldType;
  final int sortOrder;

  factory TemplateField.fromMap(Map<String, Object?> map) {
    return TemplateField(
      id: map['id'] as int?,
      templateId: map['template_id'] as int,
      label: map['label'] as String,
      keyName: map['key_name'] as String,
      fieldType: map['field_type'] as String,
      sortOrder: map['sort_order'] as int,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'template_id': templateId,
      'label': label,
      'key_name': keyName,
      'field_type': fieldType,
      'sort_order': sortOrder,
    };
  }
}
