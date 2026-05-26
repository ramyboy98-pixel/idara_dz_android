import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../core/theme/app_colors.dart';
import '../../data/models/custom_document_template.dart';
import '../../data/models/template_field.dart';
import '../../data/models/template_field_position.dart';
import '../../data/repositories/custom_templates_repository.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_topbar.dart';

class PlaceTemplateFieldsPage extends StatefulWidget {
  const PlaceTemplateFieldsPage({super.key, required this.template});

  final CustomDocumentTemplate template;

  @override
  State<PlaceTemplateFieldsPage> createState() => _PlaceTemplateFieldsPageState();
}

class _PlaceTemplateFieldsPageState extends State<PlaceTemplateFieldsPage> {
  final CustomTemplatesRepository _repository = const CustomTemplatesRepository();
  late Future<_PlacementData> _dataFuture;
  int? _selectedFieldId;
  double _fontSize = 12;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadData();
  }

  Future<_PlacementData> _loadData() async {
    final templateId = widget.template.id ?? 0;
    final fields = await _repository.getFields(templateId);
    final positions = await _repository.getFieldPositions(templateId);
    final map = <int, TemplateFieldPosition>{
      for (final position in positions) position.fieldId: position,
    };
    return _PlacementData(fields: fields, positions: map);
  }

  @override
  Widget build(BuildContext context) {
    final templatePath = widget.template.templateFilePath ?? '';
    final isImage = _isImagePath(templatePath);

    return Scaffold(
      appBar: const AppTopbar(
        title: 'تحديد أماكن المعلومات',
        subtitle: 'اختر الحقل ثم اضغط على مكانه فوق صورة النموذج',
      ),
      body: SafeArea(
        child: FutureBuilder<_PlacementData>(
          future: _dataFuture,
          builder: (context, snapshot) {
            final data = snapshot.data;
            if (snapshot.connectionState == ConnectionState.waiting || data == null) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!isImage || !File(templatePath).existsSync()) {
              return _UnsupportedTemplateBox(filePath: templatePath);
            }

            _selectedFieldId ??= data.fields.isEmpty ? null : data.fields.first.id;

            return Column(
              children: [
                _TopControls(
                  fields: data.fields,
                  selectedFieldId: _selectedFieldId,
                  fontSize: _fontSize,
                  onFieldChanged: (value) => setState(() => _selectedFieldId = value),
                  onFontChanged: (value) => setState(() => _fontSize = value),
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(12, 6, 12, 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: InteractiveViewer(
                        minScale: 0.6,
                        maxScale: 5,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTapDown: (details) {
                                final selectedId = _selectedFieldId;
                                if (selectedId == null) return;
                                final x = (details.localPosition.dx / constraints.maxWidth).clamp(0.0, 1.0).toDouble();
                                final y = (details.localPosition.dy / constraints.maxHeight).clamp(0.0, 1.0).toDouble();
                                setState(() {
                                  data.positions[selectedId] = TemplateFieldPosition(
                                    templateId: widget.template.id ?? 0,
                                    fieldId: selectedId,
                                    x: x,
                                    y: y,
                                    fontSize: _fontSize,
                                  );
                                });
                              },
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.file(
                                    File(templatePath),
                                    fit: BoxFit.fill,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Center(
                                        child: Text('تعذر عرض صورة النموذج'),
                                      );
                                    },
                                  ),
                                  ...data.fields.map((field) {
                                    final fieldId = field.id;
                                    if (fieldId == null) return const SizedBox.shrink();
                                    final position = data.positions[fieldId];
                                    if (position == null) return const SizedBox.shrink();
                                    return Positioned(
                                      left: position.x * constraints.maxWidth,
                                      top: position.y * constraints.maxHeight,
                                      child: _Marker(
                                        label: field.label,
                                        selected: fieldId == _selectedFieldId,
                                        onTap: () => setState(() => _selectedFieldId = fieldId),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                  child: AppButton(
                    label: _saving ? 'جار الحفظ...' : 'حفظ أماكن الحقول',
                    icon: Icons.save_rounded,
                    onPressed: _saving ? null : () => _savePositions(data),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _savePositions(_PlacementData data) async {
    final templateId = widget.template.id;
    if (templateId == null) return;
    setState(() => _saving = true);
    try {
      await _repository.saveFieldPositions(
        templateId: templateId,
        positions: data.positions.values.toList(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حفظ أماكن الحقول.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  bool _isImagePath(String path) {
    final extension = p.extension(path).toLowerCase();
    return ['.png', '.jpg', '.jpeg', '.webp'].contains(extension);
  }
}

class _PlacementData {
  _PlacementData({required this.fields, required this.positions});

  final List<TemplateField> fields;
  final Map<int, TemplateFieldPosition> positions;
}

class _TopControls extends StatelessWidget {
  const _TopControls({
    required this.fields,
    required this.selectedFieldId,
    required this.fontSize,
    required this.onFieldChanged,
    required this.onFontChanged,
  });

  final List<TemplateField> fields;
  final int? selectedFieldId;
  final double fontSize;
  final ValueChanged<int?> onFieldChanged;
  final ValueChanged<double> onFontChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 16, 18, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'اختر الحقل، ثم اضغط فوق الصورة في المكان الذي تريد ظهور المعلومة فيه. يمكنك التكبير والتحريك بإصبعين.',
            style: TextStyle(color: AppColors.muted, height: 1.5),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            value: selectedFieldId,
            decoration: const InputDecoration(labelText: 'الحقل المحدد'),
            items: fields.where((field) => field.id != null).map((field) {
              return DropdownMenuItem<int>(
                value: field.id,
                child: Text(field.label),
              );
            }).toList(),
            onChanged: onFieldChanged,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('حجم النص'),
              Expanded(
                child: Slider(
                  min: 8,
                  max: 22,
                  divisions: 14,
                  value: fontSize,
                  label: fontSize.round().toString(),
                  onChanged: onFontChanged,
                ),
              ),
              Text(fontSize.round().toString()),
            ],
          ),
        ],
      ),
    );
  }
}

class _Marker extends StatelessWidget {
  const _Marker({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? AppColors.blue : AppColors.green,
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _UnsupportedTemplateBox extends StatelessWidget {
  const _UnsupportedTemplateBox({required this.filePath});

  final String filePath;

  @override
  Widget build(BuildContext context) {
    final fileName = filePath.isEmpty ? 'لا يوجد ملف' : p.basename(filePath);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.image_not_supported_outlined, size: 46, color: AppColors.red),
              const SizedBox(height: 12),
              const Text(
                'هذه المرحلة تعتمد على صورة النموذج',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(
                'الملف الحالي: $fileName\nاستعمل صورة واضحة بصيغة PNG أو JPG أو WEBP. دعم PDF سيكون بعد إضافة محول صفحة PDF إلى صورة داخل التطبيق.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted, height: 1.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
