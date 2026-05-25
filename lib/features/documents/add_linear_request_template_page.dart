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
  final _editorController = TextEditingController(text: _defaultTemplateText);
  final List<_FieldDraft> _fields = [];
  final CustomTemplatesRepository _repository = const CustomTemplatesRepository();

  String? _referencePath;
  String? _referenceName;
  bool _saving = false;
  String _pageSize = 'A4';
  String _orientation = 'portrait';
  String _textDirection = 'rtl';
  double _marginTop = 32;
  double _marginRight = 32;
  double _marginBottom = 32;
  double _marginLeft = 32;
  double _baseFontSize = 14;
  double _lineSpacing = 6;

  static const String _defaultTemplateText = '''السيد: {{الاسم_واللقب}}
العنوان: {{العنوان}}
رقم الهاتف: {{رقم_الهاتف}}

[CENTER]إلى السيد:[/CENTER]
[CENTER]مدير المؤسسة[/CENTER]

[CENTER]الموضوع: طلب خطي[/CENTER]

لي الشرف أن أتقدم إلى سيادتكم المحترمة بطلبي هذا والمتمثل في {{موضوع_الطلب}}.

وفي الأخير أرجو منكم أن تأخذوا طلبي هذا بعين الاعتبار وشكرا.

إمضاء المعني''';

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _editorController.dispose();
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
        subtitle: 'أنشئ نموذجًا احترافيًا داخل التطبيق مع إعدادات صفحة ورموز تعبئة',
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
                        hintText: 'اكتب ملاحظة تساعدك على تمييز هذا النموذج',
                      ),
                    ),
                    const SizedBox(height: 14),
                    _ReferenceFileBox(
                      fileName: _referenceName,
                      onPick: _pickReferenceFile,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'إعدادات الصفحة',
                child: _PageSettingsEditor(
                  pageSize: _pageSize,
                  orientation: _orientation,
                  textDirection: _textDirection,
                  marginTop: _marginTop,
                  marginRight: _marginRight,
                  marginBottom: _marginBottom,
                  marginLeft: _marginLeft,
                  baseFontSize: _baseFontSize,
                  lineSpacing: _lineSpacing,
                  onPageSizeChanged: (value) => setState(() => _pageSize = value),
                  onOrientationChanged: (value) => setState(() => _orientation = value),
                  onDirectionChanged: (value) => setState(() => _textDirection = value),
                  onMarginTopChanged: (value) => setState(() => _marginTop = value),
                  onMarginRightChanged: (value) => setState(() => _marginRight = value),
                  onMarginBottomChanged: (value) => setState(() => _marginBottom = value),
                  onMarginLeftChanged: (value) => setState(() => _marginLeft = value),
                  onFontSizeChanged: (value) => setState(() => _baseFontSize = value),
                  onLineSpacingChanged: (value) => setState(() => _lineSpacing = value),
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'استمارة المعلومات',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'أضف الحقول التي سيملؤها المستخدم لاحقًا. اضغط زر إدراج الرمز لوضعه في مكان المؤشر داخل محرر النموذج.',
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
                          onInsertPlaceholder: () => _insertText(_placeholderFor(entry.value.labelController.text, entry.key)),
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
              const SizedBox(height: 16),
              _SectionCard(
                title: 'محرر النموذج',
                child: _TemplateEditor(
                  controller: _editorController,
                  textDirection: _textDirection,
                  baseFontSize: _baseFontSize,
                  onInsert: _insertText,
                ),
              ),
              const SizedBox(height: 18),
              AppButton(
                label: _saving ? 'جار الحفظ...' : 'حفظ النموذج',
                icon: Icons.save_rounded,
                onPressed: _saving ? null : _saveTemplate,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickReferenceFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'md'],
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;
    setState(() {
      _referencePath = file.path;
      _referenceName = file.name;
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

  String _placeholderFor(String label, int index) {
    final normalized = label
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'[^\u0600-\u06FFa-z0-9_]'), '');
    final key = normalized.isEmpty ? 'field_${index + 1}' : normalized;
    return '{{$key}}';
  }

  void _insertText(String value) {
    final selection = _editorController.selection;
    final currentText = _editorController.text;
    final start = selection.start < 0 ? currentText.length : selection.start;
    final end = selection.end < 0 ? currentText.length : selection.end;
    final newText = currentText.replaceRange(start, end, value);
    _editorController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + value.length),
    );
  }

  Future<void> _saveTemplate() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    final editorContent = _editorController.text.trim();
    if (editorContent.isEmpty) {
      _showMessage('اكتب نص النموذج داخل المحرر أولًا.');
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
        templateFilePath: _referencePath,
        editorContent: editorContent,
        pageSettings: TemplatePageSettings(
          pageSize: _pageSize,
          orientation: _orientation,
          marginTop: _marginTop,
          marginRight: _marginRight,
          marginBottom: _marginBottom,
          marginLeft: _marginLeft,
          textDirection: _textDirection,
          baseFontSize: _baseFontSize,
          lineSpacing: _lineSpacing,
        ),
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
          Text('📝', style: TextStyle(fontSize: 32)),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'محرر قوالب IDARA DZ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'هذه النسخة تستبدل الاعتماد على DOCX بمحرر داخلي مضبوط: صفحة A4، هوامش، اتجاه كتابة، حجم خط، محاذاة، ورموز تعبئة. ملف Word يمكن رفعه كمرجع فقط وليس كمصدر PDF.',
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
              Expanded(
                child: Text(
                  'كيف يعمل الملء الآلي؟',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            'أنشئ حقول الاستمارة ثم ضع رموزها داخل محرر النموذج. مثال: {{الاسم_واللقب}}. عند إنشاء PDF سيستبدل التطبيق هذه الرموز بالقيم المدخلة.',
            style: TextStyle(color: AppColors.muted, height: 1.6),
          ),
          SizedBox(height: 10),
          Text(
            'للمحاذاة استعمل الأزرار في شريط المحرر. يمكنك أيضًا كتابة سطر بين [CENTER] و [/CENTER] لجعله في الوسط.',
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

class _ReferenceFileBox extends StatelessWidget {
  const _ReferenceFileBox({required this.fileName, required this.onPick});

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
              hasFile ? Icons.attach_file_rounded : Icons.description_outlined,
              color: hasFile ? AppColors.blue : AppColors.muted,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                hasFile ? 'ملف مرجعي: $fileName' : 'اختياري: أرفق ملف Word/PDF كمرجع بصري فقط',
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

class _PageSettingsEditor extends StatelessWidget {
  const _PageSettingsEditor({
    required this.pageSize,
    required this.orientation,
    required this.textDirection,
    required this.marginTop,
    required this.marginRight,
    required this.marginBottom,
    required this.marginLeft,
    required this.baseFontSize,
    required this.lineSpacing,
    required this.onPageSizeChanged,
    required this.onOrientationChanged,
    required this.onDirectionChanged,
    required this.onMarginTopChanged,
    required this.onMarginRightChanged,
    required this.onMarginBottomChanged,
    required this.onMarginLeftChanged,
    required this.onFontSizeChanged,
    required this.onLineSpacingChanged,
  });

  final String pageSize;
  final String orientation;
  final String textDirection;
  final double marginTop;
  final double marginRight;
  final double marginBottom;
  final double marginLeft;
  final double baseFontSize;
  final double lineSpacing;
  final ValueChanged<String> onPageSizeChanged;
  final ValueChanged<String> onOrientationChanged;
  final ValueChanged<String> onDirectionChanged;
  final ValueChanged<double> onMarginTopChanged;
  final ValueChanged<double> onMarginRightChanged;
  final ValueChanged<double> onMarginBottomChanged;
  final ValueChanged<double> onMarginLeftChanged;
  final ValueChanged<double> onFontSizeChanged;
  final ValueChanged<double> onLineSpacingChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: pageSize,
                decoration: const InputDecoration(labelText: 'حجم الورقة'),
                items: const [
                  DropdownMenuItem(value: 'A4', child: Text('A4')),
                  DropdownMenuItem(value: 'A5', child: Text('A5')),
                ],
                onChanged: (value) {
                  if (value != null) onPageSizeChanged(value);
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: orientation,
                decoration: const InputDecoration(labelText: 'اتجاه الصفحة'),
                items: const [
                  DropdownMenuItem(value: 'portrait', child: Text('عمودي')),
                  DropdownMenuItem(value: 'landscape', child: Text('أفقي')),
                ],
                onChanged: (value) {
                  if (value != null) onOrientationChanged(value);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: textDirection,
          decoration: const InputDecoration(labelText: 'اتجاه الكتابة'),
          items: const [
            DropdownMenuItem(value: 'rtl', child: Text('من اليمين إلى اليسار')),
            DropdownMenuItem(value: 'ltr', child: Text('من اليسار إلى اليمين')),
          ],
          onChanged: (value) {
            if (value != null) onDirectionChanged(value);
          },
        ),
        const SizedBox(height: 12),
        _SliderSetting(label: 'الهامش العلوي', value: marginTop, min: 16, max: 72, onChanged: onMarginTopChanged),
        _SliderSetting(label: 'الهامش الأيمن', value: marginRight, min: 16, max: 72, onChanged: onMarginRightChanged),
        _SliderSetting(label: 'الهامش السفلي', value: marginBottom, min: 16, max: 72, onChanged: onMarginBottomChanged),
        _SliderSetting(label: 'الهامش الأيسر', value: marginLeft, min: 16, max: 72, onChanged: onMarginLeftChanged),
        _SliderSetting(label: 'حجم الخط الأساسي', value: baseFontSize, min: 10, max: 22, onChanged: onFontSizeChanged),
        _SliderSetting(label: 'تباعد الأسطر', value: lineSpacing, min: 2, max: 14, onChanged: onLineSpacingChanged),
      ],
    );
  }
}

class _SliderSetting extends StatelessWidget {
  const _SliderSetting({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
            Text(value.toStringAsFixed(0), style: const TextStyle(color: AppColors.muted)),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: (max - min).round(),
          onChanged: onChanged,
        ),
      ],
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
            'رمز الحقل:',
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
    required this.onInsertPlaceholder,
  });

  final int index;
  final _FieldDraft field;
  final VoidCallback onDelete;
  final VoidCallback onInsertPlaceholder;

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
              Text('حقل ${widget.index + 1}', style: const TextStyle(fontWeight: FontWeight.w900)),
              const Spacer(),
              TextButton.icon(
                onPressed: widget.onInsertPlaceholder,
                icon: const Icon(Icons.input_rounded, size: 18),
                label: const Text('إدراج الرمز'),
              ),
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

class _TemplateEditor extends StatelessWidget {
  const _TemplateEditor({
    required this.controller,
    required this.textDirection,
    required this.baseFontSize,
    required this.onInsert,
  });

  final TextEditingController controller;
  final String textDirection;
  final double baseFontSize;
  final ValueChanged<String> onInsert;

  @override
  Widget build(BuildContext context) {
    final direction = textDirection == 'rtl' ? TextDirection.rtl : TextDirection.ltr;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _ToolButton(label: 'وسط', icon: Icons.format_align_center_rounded, onTap: () => onInsert('[CENTER][/CENTER]')),
            _ToolButton(label: 'يمين', icon: Icons.format_align_right_rounded, onTap: () => onInsert('[RIGHT][/RIGHT]')),
            _ToolButton(label: 'يسار', icon: Icons.format_align_left_rounded, onTap: () => onInsert('[LEFT][/LEFT]')),
            _ToolButton(label: 'عنوان', icon: Icons.title_rounded, onTap: () => onInsert('[TITLE][/TITLE]')),
            _ToolButton(label: 'عريض', icon: Icons.format_bold_rounded, onTap: () => onInsert('[B][/B]')),
            _ToolButton(label: 'سطر', icon: Icons.horizontal_rule_rounded, onTap: () => onInsert('\n[LINE]\n')),
            _ToolButton(label: 'فراغ', icon: Icons.keyboard_return_rounded, onTap: () => onInsert('\n')),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: TextFormField(
            controller: controller,
            textDirection: direction,
            textAlign: direction == TextDirection.rtl ? TextAlign.right : TextAlign.left,
            minLines: 16,
            maxLines: null,
            style: TextStyle(
              fontSize: baseFontSize,
              height: 1.7,
              color: AppColors.text,
            ),
            decoration: const InputDecoration(
              hintText: 'اكتب نص النموذج هنا وضع الرموز في أماكنها...',
              border: InputBorder.none,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'اكتب نص النموذج';
              }
              return null;
            },
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'V1: هذه محرر قوالب مضبوط للتصدير PDF. التنسيقات تعمل عبر أزرار وسوم بسيطة مثل [CENTER] و [TITLE]. سنضيف لاحقًا الجداول وتنسيق النص المحدد.',
          style: TextStyle(color: AppColors.muted, fontSize: 12, height: 1.5),
        ),
      ],
    );
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({required this.label, required this.icon, required this.onTap});

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }
}
