class TemplateFieldPosition {
  const TemplateFieldPosition({
    this.id,
    required this.templateId,
    required this.fieldId,
    required this.x,
    required this.y,
    this.fontSize = 12,
  });

  final int? id;
  final int templateId;
  final int fieldId;
  final double x;
  final double y;
  final double fontSize;

  factory TemplateFieldPosition.fromMap(Map<String, Object?> map) {
    return TemplateFieldPosition(
      id: map['id'] as int?,
      templateId: map['template_id'] as int,
      fieldId: map['field_id'] as int,
      x: ((map['x'] as num?) ?? 0).toDouble(),
      y: ((map['y'] as num?) ?? 0).toDouble(),
      fontSize: ((map['font_size'] as num?) ?? 12).toDouble(),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'template_id': templateId,
      'field_id': fieldId,
      'x': x,
      'y': y,
      'font_size': fontSize,
    };
  }
}
