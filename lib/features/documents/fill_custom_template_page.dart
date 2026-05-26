import 'package:flutter/material.dart';

import '../../data/models/custom_document_template.dart';
import '../../widgets/app_topbar.dart';

class FillCustomTemplatePage extends StatelessWidget {
  const FillCustomTemplatePage({super.key, required this.template});

  final CustomDocumentTemplate template;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopbar(
        title: template.title,
        subtitle: 'تم تعطيل النماذج الديناميكية حالياً',
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'هذا المسار قديم. النسخة الحالية تعتمد على نماذج ثابتة داخل التطبيق للحصول على PDF مضبوط.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, height: 1.6),
          ),
        ),
      ),
    );
  }
}
