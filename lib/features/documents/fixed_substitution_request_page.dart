import 'package:flutter/material.dart';

import '../../core/pdf/pdf_exporter.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/archive_repository.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_topbar.dart';
import 'document_result_page.dart';

class FixedSubstitutionRequestPage extends StatefulWidget {
  const FixedSubstitutionRequestPage({super.key});

  @override
  State<FixedSubstitutionRequestPage> createState() => _FixedSubstitutionRequestPageState();
}

class _FixedSubstitutionRequestPageState extends State<FixedSubstitutionRequestPage> {
  final _formKey = GlobalKey<FormState>();
  final ArchiveRepository _archiveRepository = ArchiveRepository();
  final Map<String, TextEditingController> _controllers = {
    'requestDate': TextEditingController(),
    'firstName': TextEditingController(),
    'lastName': TextEditingController(),
    'fullAddress': TextEditingController(),
    'city': TextEditingController(),
    'phone': TextEditingController(),
    'nationalId': TextEditingController(),
    'recipient': TextEditingController(),
    'subjectMatter': TextEditingController(),
    'experienceYears': TextEditingController(),
    'degree': TextEditingController(),
    'specialization': TextEditingController(),
    'university': TextEditingController(),
    'graduationYear': TextEditingController(),
  };

  bool _isExporting = false;

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopbar(
        title: 'طلب منصب استخلاف',
        subtitle: 'استمارة معلومات النموذج الثابت',
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
            children: [
              const _InfoHeader(),
              const SizedBox(height: 16),
              _DateField(
                controller: _controllers['requestDate']!,
                label: 'تاريخ الطلب',
              ),
              _InputField(
                controller: _controllers['firstName']!,
                label: 'الاسم',
                requiredField: true,
              ),
              _InputField(
                controller: _controllers['lastName']!,
                label: 'اللقب',
                requiredField: true,
              ),
              _InputField(
                controller: _controllers['fullAddress']!,
                label: 'العنوان الكامل',
                maxLines: 2,
              ),
              _InputField(
                controller: _controllers['city']!,
                label: 'المدينة',
              ),
              _InputField(
                controller: _controllers['phone']!,
                label: 'رقم الهاتف',
                keyboardType: TextInputType.phone,
              ),
              _InputField(
                controller: _controllers['nationalId']!,
                label: 'رقم بطاقة التعريف الوطنية',
                keyboardType: TextInputType.number,
              ),
              _InputField(
                controller: _controllers['recipient']!,
                label: 'السيد / الجهة المستقبلة',
                requiredField: true,
              ),
              _InputField(
                controller: _controllers['subjectMatter']!,
                label: 'أستاذ مستخلف لمادة',
                requiredField: true,
              ),
              _InputField(
                controller: _controllers['experienceYears']!,
                label: 'عدد سنوات الخبرة',
                keyboardType: TextInputType.number,
              ),
              _InputField(
                controller: _controllers['degree']!,
                label: 'الشهادة المتحصل عليها أو المستوى الدراسي',
              ),
              _InputField(
                controller: _controllers['specialization']!,
                label: 'التخصص',
              ),
              _InputField(
                controller: _controllers['university']!,
                label: 'الجامعة / المعهد',
              ),
              _InputField(
                controller: _controllers['graduationYear']!,
                label: 'سنة التخرج',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 14),
              AppButton(
                label: _isExporting ? 'جار إنشاء PDF...' : 'إنشاء PDF',
                icon: Icons.picture_as_pdf_rounded,
                onPressed: _isExporting ? null : _exportPdf,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _exportPdf() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isExporting = true);
    try {
      final filePath = await PdfExporter.exportSubstitutionRequest(
        requestDate: _value('requestDate'),
        firstName: _value('firstName'),
        lastName: _value('lastName'),
        fullAddress: _value('fullAddress'),
        city: _value('city'),
        phone: _value('phone'),
        nationalId: _value('nationalId'),
        recipient: _value('recipient'),
        subjectMatter: _value('subjectMatter'),
        experienceYears: _value('experienceYears'),
        degree: _value('degree'),
        specialization: _value('specialization'),
        university: _value('university'),
        graduationYear: _value('graduationYear'),
      );

      final fullName = '${_value('lastName')} ${_value('firstName')}'.trim();
      await _archiveRepository.addPdfItem(
        title: 'طلب منصب استخلاف',
        filePath: filePath,
        customerName: fullName.isEmpty ? null : fullName,
      );

      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => DocumentResultPage(
            title: 'طلب منصب استخلاف',
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

  String _value(String key) => _controllers[key]?.text.trim() ?? '';
}

class _InfoHeader extends StatelessWidget {
  const _InfoHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.sidebar,
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('📄', style: TextStyle(fontSize: 30)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'طلب منصب استخلاف',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            'املأ المعلومات التالية، وسيقوم التطبيق بإنشاء وثيقة PDF ثابتة بتنسيق عربي مضبوط مع التفاف الأسطر الطويلة تلقائيًا.',
            style: TextStyle(
              color: Color(0xFFD1D5DB),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.label,
    this.keyboardType,
    this.maxLines = 1,
    this.requiredField = false,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final int maxLines;
  final bool requiredField;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: requiredField
            ? (value) {
                if ((value ?? '').trim().isEmpty) return 'هذا الحقل مطلوب';
                return null;
              }
            : null,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: AppColors.lightGray,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(1950),
            lastDate: DateTime(2100),
            locale: const Locale('ar', 'DZ'),
          );
          if (picked == null) return;
          controller.text = '${picked.day}/${picked.month}/${picked.year}';
        },
        validator: (value) {
          if ((value ?? '').trim().isEmpty) return 'هذا الحقل مطلوب';
          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: AppColors.lightGray,
          suffixIcon: const Icon(Icons.calendar_month_rounded),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
