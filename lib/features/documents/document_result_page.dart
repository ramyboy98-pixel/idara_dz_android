import 'package:flutter/material.dart';

import '../../core/pdf/pdf_exporter.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_topbar.dart';

class DocumentResultPage extends StatelessWidget {
  const DocumentResultPage({
    super.key,
    required this.title,
    required this.filePath,
  });

  final String title;
  final String filePath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTopbar(title: title),
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
                      filePath,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 18),
                    AppButton(
                      label: 'مشاركة ملف PDF',
                      icon: Icons.share_rounded,
                      onPressed: () => PdfExporter.sharePdf(filePath),
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
}
