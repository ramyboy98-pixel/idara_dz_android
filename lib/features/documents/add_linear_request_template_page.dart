import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/custom_document_template.dart';
import '../../data/repositories/custom_templates_repository.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_topbar.dart';
import 'place_template_fields_page.dart';

class AddLinearRequestTemplatePage extends StatefulWidget {
  const AddLinearRequestTemplatePage({super.key});

  @override
  State<AddLinearRequestTemplatePage> createState() => _AddLinearRequestTemplatePageState();
}

class _AddLinearRequestTemplatePageState extends State<AddLinearRequestTemplatePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<_FieldDraft> _fields = [];
  final CustomTemplatesRepository _repository = const CustomTemplatesRepository();

  String? _templatePath;
  String? _templateName;
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    for (final field in _fields) {
      field.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopbar(
        title: 'إضافة نموذج طلب خطي',
        subtitle: 'استعمل صورة النموذج كخلفية ثم حدد أماكن الحقول فوقها',
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
            children: [
              const _InfoCard(),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'معلومات النموذج',
                child: Column(
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'اسم النموذج',
                        hintText: 'مثال: طلب تركيب عداد كهربائي',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'اكتب اسم النموذج';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descriptionController,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'وصف مختصر',
                        hintText: 'ملاحظة تساعدك على تمييز هذا النموذج',
                      ),
                    ),
                    const SizedBox(height: 14),
                    _TemplateFileBox(
                      fileName: _templateName,
                      onPick: _pickTemplateImage,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'استمارة المعلومات',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'أضف الحقول التي سيملؤها المستخدم لاحقًا. بعد حفظ النموذج ستظهر صفحة تحديد الأماكن، تختار الحقل ثم تضغط على مكانه فوق صورة النموذج.',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 13,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (_fields.isEmpty)
                      const _NoFieldsBox()
                    else
                      ..._fields.asMap().entries.map((entry) {
                        return _FieldEditor(
                          index: entry.key,
                          field: entry.value,
                          onDelete: () => _removeField(entry.key),
                        );
                      }),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _addField,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('إضافة حقل جديد'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              AppButton(
                label: _saving ? 'جار الحفظ...' : 'حفظ النموذج وتحديد الأماكن',
                icon: Icons.save_rounded,
                onPressed: _saving ? null : _saveTemplate,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickTemplateImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg', 'webp'],
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;
    setState(() {
      _templatePath = file.path;
      _templateName = file.name;
    });
  }

  void _addField() {
    setState(() {
      _fields.add(_FieldDraft());
    });
  }

  void _removeField(int index) {
    setState(() {
      final field = _fields.removeAt(index);
      field.dispose();
    });
  }

  Future<void> _saveTemplate() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    if (_templatePath == null) {
      _showMessage('اختر صورة النموذج من الهاتف أولًا.');
      return;
    }

    final fields = <NewTemplateField>[];
    for (final field in _fields) {
      final label = field.labelController.text.trim();
      if (label.isNotEmpty) {
        fields.add(NewTemplateField(label: label, fieldType: field.fieldType));
      }
    }

    if (fields.isEmpty) {
      _showMessage('أضف حقلًا واحدًا على الأقل في استمارة المعلومات.');
      return;
    }

    setState(() => _saving = true);
    try {
      final templateId = await _repository.addTemplateWithFields(
        categoryName: 'طلب خطي',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        templateFilePath: _templatePath,
        fields: fields,
      );

      final template = await _repository.getTemplate(templateId);
      if (!mounted) return;

      if (template != null) {
        await Navigator.of(context).push<bool>(
          MaterialPageRoute<bool>(
            builder: (_) => PlaceTemplateFieldsPage(template: template),
          ),
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      _showMessage('حدث خطأ أثناء حفظ النموذج.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}

class _FieldDraft {
  final TextEditingController labelController = TextEditingController();
  String fieldType = 'text';

  void dispose() {
    labelController.dispose();
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.sidebar,
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('🖼️', style: TextStyle(fontSize: 32)),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'النموذج كصورة ثابتة',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'ارفع صورة واضحة للنموذج، ثم حدد أماكن المعلومات فوق الصورة مرة واحدة. بعد ذلك سيضع التطبيق بيانات الاستمارة فوق نفس الأماكن ويصدر PDF بنفس شكل النموذج.',
                  style: TextStyle(
                    color: Color(0xFFD1D5DB),
                    height: 1.6,
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _TemplateFileBox extends StatelessWidget {
  const _TemplateFileBox({required this.fileName, required this.onPick});

  final String? fileName;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onPick,
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFBFDBFE)),
        ),
        child: Row(
          children: [
            const Icon(Icons.image_rounded, color: AppColors.blue),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                fileName == null ? 'اختر صورة النموذج PNG / JPG / WEBP' : fileName!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.text,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const Icon(Icons.upload_file_rounded, color: AppColors.blue),
          ],
        ),
      ),
    );
  }
}

class _NoFieldsBox extends StatelessWidget {
  const _NoFieldsBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Text(
        'لم تضف أي حقل بعد. أضف مثلًا: الاسم واللقب، العنوان، رقم الهاتف، التاريخ.',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.muted, height: 1.5),
      ),
    );
  }
}

class _FieldEditor extends StatefulWidget {
  const _FieldEditor({
    required this.index,
    required this.field,
    required this.onDelete,
  });

  final int index;
  final _FieldDraft field;
  final VoidCallback onDelete;

  @override
  State<_FieldEditor> createState() => _FieldEditorState();
}

class _FieldEditorState extends State<_FieldEditor> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 15,
                backgroundColor: AppColors.blue,
                foregroundColor: Colors.white,
                child: Text('${widget.index + 1}'),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'حقل في الاستمارة',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              IconButton(
                onPressed: widget.onDelete,
                icon: const Icon(Icons.close_rounded),
                color: AppColors.red,
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: widget.field.labelController,
            decoration: const InputDecoration(
              labelText: 'اسم الحقل',
              hintText: 'مثال: الاسم واللقب',
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: widget.field.fieldType,
            decoration: const InputDecoration(labelText: 'نوع الحقل'),
            items: const [
              DropdownMenuItem(value: 'text', child: Text('نص')),
              DropdownMenuItem(value: 'date', child: Text('تاريخ')),
              DropdownMenuItem(value: 'phone', child: Text('رقم هاتف')),
              DropdownMenuItem(value: 'number', child: Text('رقم')),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() => widget.field.fieldType = value);
            },
          ),
        ],
      ),
    );
  }
}
