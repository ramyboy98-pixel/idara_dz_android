import 'package:flutter/material.dart';

import '../../core/pdf/pdf_exporter.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_topbar.dart';

class DocumentResultPage extends StatefulWidget {
  const DocumentResultPage({
    super.key,
    required this.title,
    required this.filePath,
  });

  final String title;
  final String filePath;

  @override
  State<DocumentResultPage> createState() => _DocumentResultPageState();
}

class _DocumentResultPageState extends State<DocumentResultPage> {
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTopbar(title: widget.title),
              const SizedBox(height: 20),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.picture_as_pdf_rounded, size: 56),
                    const SizedBox(height: 12),
                    const Text(
                      'تم تصدير ملف PDF بنجاح',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.filePath,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            label: 'مشاركة',
                            icon: Icons.share_rounded,
                            onPressed: () => PdfExporter.sharePdf(widget.filePath),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: AppButton(
                            label: _saving ? 'جار الحفظ...' : 'حفظ في الهاتف',
                            icon: Icons.save_alt_rounded,
                            color: AppColors.green,
                            onPressed: _saving ? null : _saveToPhone,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'زر الحفظ يفتح نافذة اختيار مكان حفظ ملف PDF داخل الهاتف.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveToPhone() async {
    setState(() => _saving = true);
    try {
      final savedPath = await PdfExporter.savePdfToPhone(
        sourcePath: widget.filePath,
        title: widget.title,
      );

      if (!mounted) return;
      final message = savedPath == null
          ? 'تم إلغاء الحفظ.'
          : 'تم حفظ ملف PDF في الهاتف.';
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(message),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text('تعذر حفظ الملف: $error'),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
