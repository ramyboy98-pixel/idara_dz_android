import 'package:flutter/material.dart';

import '../../widgets/app_topbar.dart';

class AddLinearRequestTemplatePage extends StatelessWidget {
  const AddLinearRequestTemplatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: AppTopbar(
        title: 'إضافة نموذج',
        subtitle: 'تم تعطيل إنشاء النماذج من داخل التطبيق حالياً',
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'تم اعتماد النماذج الثابتة داخل التطبيق. سيتم إضافة النماذج الجديدة من خلال تحديثات الكود.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, height: 1.6),
          ),
        ),
      ),
    );
  }
}
