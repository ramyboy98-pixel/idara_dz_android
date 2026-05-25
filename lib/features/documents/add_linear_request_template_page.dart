import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/repositories/custom_templates_repository.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_topbar.dart';

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
        subtitle: 'ارفع النموذج وأنشئ استمارة المعلومات الخاصة به',
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
            children: [
              const _InfoCard(),
              const SizedBox(height: 12),
              const _PlaceholderGuideCard(),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'معلومات النموذج',
                child: Column(
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'اسم النموذج',
                        hintText: 'مثال: طلب توظيف في مؤسسة',
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
                        hintText: 'اكتب ملاحظة تساعدك على تمييز هذا النموذج',
                      ),
                    ),
                    const SizedBox(height: 14),
                    _TemplateFileBox(
                      fileName: _templateName,
                      onPick: _pickTemplateFile,
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
                      'أضف الحقول التي سيملؤها المستخدم لاحقًا. لكل حقل سيظهر رمز خاص؛ ضع نفس الرمز داخل ملف النموذج في المكان الذي تريد أن تُملأ فيه المعلومة.',
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
                label: _saving ? 'جار الحفظ...' : 'حفظ النموذج',
                icon: Icons.save_rounded,
                onPressed: _saving ? () {} : _saveTemplate,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickTemplateFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt', 'md', 'pdf', 'doc', 'docx'],
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
      _showMessage('اختر ملف النموذج من الهاتف (الأفضل الآن TXT أو MD) أولًا.');
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
      await _repository.addTemplateWithFields(
        categoryName: 'طلب خطي',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        templateFilePath: _templatePath,
        fields: fields,
      );
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
          Text('🧩', style: TextStyle(fontSize: 32)),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'بناء نموذج قابل للتعبئة',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'اكتب داخل ملف النموذج رموزًا مثل {{الاسم_واللقب}} في أماكن المعلومات. حاليًا يتم استبدال الرموز مباشرة في ملفات TXT و MD ثم تصديرها PDF. ملفات PDF و DOCX تُحفظ كمرجع وسنضيف دعمها الكامل لاحقًا.',
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


class _PlaceholderGuideCard extends StatelessWidget {
  const _PlaceholderGuideCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_fix_high_rounded, color: AppColors.blue),
              SizedBox(width: 8),
              Text(
                'كيف يعرف التطبيق أماكن ملء المعلومات؟',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            'داخل ملف النموذج النصي TXT أو MD تضع رموزًا بين قوسين مزدوجين. مثال: {{الاسم_واللقب}} أو {{تاريخ_الطلب}}. عند ملء الاستمارة، سيبحث التطبيق عن هذه الرموز ويستبدلها تلقائيًا بالمعلومات.',
            style: TextStyle(color: AppColors.muted, height: 1.6),
          ),
          SizedBox(height: 10),
          Text(
            'مثال داخل النموذج: أنا الممضي أسفله {{الاسم_واللقب}} الساكن بـ {{العنوان}} أتقدم إلى سيادتكم بهذا الطلب.',
            style: TextStyle(
              color: AppColors.text,
              height: 1.6,
              fontWeight: FontWeight.w700,
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
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
    final hasFile = fileName != null;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onPick,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: hasFile ? const Color(0xFFEFF6FF) : AppColors.lightGray,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: hasFile ? AppColors.blue : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              hasFile ? Icons.check_circle_rounded : Icons.upload_file_rounded,
              color: hasFile ? AppColors.blue : AppColors.muted,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                hasFile ? fileName! : 'اختر ملف النموذج من الهاتف (الأفضل الآن TXT أو MD)',
                style: TextStyle(
                  color: hasFile ? AppColors.text : AppColors.muted,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
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
        border: Border.all(color: AppColors.border),
      ),
      child: const Text(
        'لا توجد حقول بعد. اضغط "إضافة حقل جديد" لإنشاء استمارة المعلومات.',
        style: TextStyle(color: AppColors.muted, height: 1.5),
      ),
    );
  }
}


class _PlaceholderPreview extends StatelessWidget {
  const _PlaceholderPreview({required this.placeholder});

  final String placeholder;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'الرمز الذي يجب وضعه داخل النموذج:',
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 4),
          SelectableText(
            placeholder,
            textDirection: TextDirection.ltr,
            style: const TextStyle(
              color: AppColors.blue,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
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
  void initState() {
    super.initState();
    widget.field.labelController.addListener(_onLabelChanged);
  }

  @override
  void dispose() {
    widget.field.labelController.removeListener(_onLabelChanged);
    super.dispose();
  }

  void _onLabelChanged() {
    if (mounted) setState(() {});
  }

  String _placeholderFor(String label) {
    final normalized = label
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'[^\u0600-\u06FFa-z0-9_]'), '');
    final key = normalized.isEmpty ? 'field_${widget.index + 1}' : normalized;
    return '{{$key}}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'حقل ${widget.index + 1}',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const Spacer(),
              IconButton(
                onPressed: widget.onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
                color: AppColors.red,
              ),
            ],
          ),
          TextFormField(
            controller: widget.field.labelController,
            decoration: const InputDecoration(
              labelText: 'اسم الحقل',
              hintText: 'مثال: الاسم واللقب',
            ),
          ),
          const SizedBox(height: 8),
          _PlaceholderPreview(placeholder: _placeholderFor(widget.field.labelController.text)),
          const SizedBox(height: 10),
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
