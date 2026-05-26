import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/pdf/pdf_exporter.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/custom_document_template.dart';
import '../../data/models/template_field.dart';
import '../../data/repositories/archive_repository.dart';
import '../../data/repositories/custom_templates_repository.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_topbar.dart';
import 'document_result_page.dart';

class FillCustomTemplatePage extends StatefulWidget {
  const FillCustomTemplatePage({super.key, required this.template});

  final CustomDocumentTemplate template;

  @override
  State<FillCustomTemplatePage> createState() => _FillCustomTemplatePageState();
}

class _FillCustomTemplatePageState extends State<FillCustomTemplatePage> {
  final CustomTemplatesRepository _templatesRepository = const CustomTemplatesRepository();
  final ArchiveRepository _archiveRepository = ArchiveRepository();
  final Map<int, TextEditingController> _controllers = {};
  final Map<int, String> _fieldValues = {};
  late Future<_FillTemplateData> _dataFuture;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _dataFuture = _loadData();
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<_FillTemplateData> _loadData() async {
    final templateId = widget.template.id ?? 0;
    final fields = await _templatesRepository.getFields(templateId);
    final positions = await _templatesRepository.getFieldPositions(templateId);
    return _FillTemplateData(fields: fields, positionsCount: positions.length);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopbar(
        title: widget.template.title,
        subtitle: 'املأ الاستمارة وسيتم وضع البيانات فوق صورة النموذج',
      ),
      body: SafeArea(
        child: FutureBuilder<_FillTemplateData>(
          future: _dataFuture,
          builder: (context, snapshot) {
            final data = snapshot.data;
            final fields = data?.fields ?? [];

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
              children: [
                _TemplateInfoCard(template: widget.template),
                const SizedBox(height: 14),
                _PlaceholderInfoCard(fields: fields),
                const SizedBox(height: 16),
                if (fields.isEmpty)
                  const _EmptyFieldsBox()
                else ...[
                  ...fields.map(_buildFieldInput),
                  const SizedBox(height: 14),
                  AppButton(
                    label: _isExporting ? 'جار إنشاء PDF...' : 'إنشاء PDF من النموذج',
                    icon: Icons.picture_as_pdf_rounded,
                    onPressed: _isExporting ? null : () => _exportPdf(fields),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'سيتم وضع البيانات فوق صورة النموذج في الأماكن التي حددتها عند إضافة النموذج، ثم يحفظ التطبيق PDF في الأرشيف.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildFieldInput(TemplateField field) {
    final fieldId = field.id ?? field.sortOrder;
    final controller = _controllers.putIfAbsent(
      fieldId,
      () => TextEditingController(text: _fieldValues[fieldId] ?? ''),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  field.label,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _SmallPlaceholderChip(text: '{{${field.keyName}}}'),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            keyboardType: _keyboardTypeFor(field.fieldType),
            readOnly: field.fieldType == 'date',
            onTap: field.fieldType == 'date'
                ? () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(1950),
                      lastDate: DateTime(2100),
                      locale: const Locale('ar', 'DZ'),
                    );
                    if (picked == null) return;
                    final value = '${picked.year}/${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}';
                    controller.text = value;
                    _fieldValues[fieldId] = value;
                  }
                : null,
            onChanged: (value) => _fieldValues[fieldId] = value,
            decoration: InputDecoration(
              hintText: _hintFor(field),
              filled: true,
              fillColor: AppColors.lightGray,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              suffixIcon: field.fieldType == 'date'
                  ? const Icon(Icons.calendar_month_rounded)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  TextInputType _keyboardTypeFor(String type) {
    switch (type) {
      case 'phone':
        return TextInputType.phone;
      case 'number':
        return TextInputType.number;
      default:
        return TextInputType.text;
    }
  }

  String _hintFor(TemplateField field) {
    switch (field.fieldType) {
      case 'date':
        return 'اختر ${field.label}';
      case 'phone':
        return 'أدخل رقم الهاتف';
      case 'number':
        return 'أدخل رقمًا';
      default:
        return 'أدخل ${field.label}';
    }
  }

  Future<void> _exportPdf(List<TemplateField> fields) async {
    setState(() => _isExporting = true);

    try {
      final valuesByLabel = <String, String>{};
      for (final field in fields) {
        final fieldId = field.id ?? field.sortOrder;
        final value = _controllers[fieldId]?.text.trim() ?? '';
        valuesByLabel[field.label] = value;
      }

      final positions = await _templatesRepository.getFieldPositions(widget.template.id ?? 0);
      final valuesByFieldId = <int, String>{};
      for (final field in fields) {
        final fieldId = field.id ?? field.sortOrder;
        valuesByFieldId[fieldId] = _controllers[fieldId]?.text.trim() ?? '';
      }

      final filePath = await PdfExporter.exportImageTemplateDocument(
        title: widget.template.title,
        templateFilePath: widget.template.templateFilePath,
        fields: fields,
        positions: positions,
        valuesByFieldId: valuesByFieldId,
      );

      await _archiveRepository.addPdfItem(
        title: widget.template.title,
        filePath: filePath,
        customerName: _guessCustomerName(valuesByLabel),
      );

      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => DocumentResultPage(
            title: widget.template.title,
            filePath: filePath,
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text('تعذر إنشاء PDF: $error'),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  String? _guessCustomerName(Map<String, String> valuesByLabel) {
    for (final entry in valuesByLabel.entries) {
      final label = entry.key;
      if (label.contains('الاسم') || label.contains('اللقب')) {
        final value = entry.value.trim();
        if (value.isNotEmpty) return value;
      }
    }
    return null;
  }
}

class _FillTemplateData {
  const _FillTemplateData({required this.fields, required this.positionsCount});

  final List<TemplateField> fields;
  final int positionsCount;
}

class _TemplateInfoCard extends StatelessWidget {
  const _TemplateInfoCard({required this.template});

  final CustomDocumentTemplate template;

  @override
  Widget build(BuildContext context) {
    final filePath = template.templateFilePath ?? '';
    final fileName = filePath.isEmpty ? 'لم يتم اختيار ملف' : filePath.split(Platform.pathSeparator).last;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.sidebar,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📄', style: TextStyle(fontSize: 30)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  template.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          if ((template.description ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              template.description!,
              style: const TextStyle(
                color: Color(0xFFD1D5DB),
                height: 1.5,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.attach_file_rounded, color: Colors.white70, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceholderInfoCard extends StatelessWidget {
  const _PlaceholderInfoCard({required this.fields});

  final List<TemplateField> fields;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'حقول هذا النموذج',
            style: TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'سيتم وضع قيم هذه الحقول فوق صورة النموذج حسب الأماكن التي حددتها عند إضافة النموذج.',
            style: TextStyle(color: AppColors.muted, height: 1.5),
          ),
          const SizedBox(height: 10),
          if (fields.isEmpty)
            const Text('لا توجد حقول.', style: TextStyle(color: AppColors.muted))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: fields
                  .map((field) => _SmallPlaceholderChip(text: field.label))
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _SmallPlaceholderChip extends StatelessWidget {
  const _SmallPlaceholderChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        text,
        textDirection: TextDirection.ltr,
        style: const TextStyle(
          color: AppColors.blue,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _EmptyFieldsBox extends StatelessWidget {
  const _EmptyFieldsBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        children: [
          Text('⚠️', style: TextStyle(fontSize: 40)),
          SizedBox(height: 10),
          Text(
            'هذا النموذج لا يحتوي على حقول استمارة.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.text,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'احذف النموذج وأعد إضافته مع الحقول التي تريد ملأها داخل النموذج.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, height: 1.5),
          ),
        ],
      ),
    );
  }
}
