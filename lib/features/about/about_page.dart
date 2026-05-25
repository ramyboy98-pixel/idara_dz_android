import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_topbar.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: AppTopbar(
        title: 'حول البرنامج',
        subtitle: 'معلومات IDARA DZ',
      ),
      body: Padding(
        padding: EdgeInsets.all(18),
        child: AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('IDARA DZ', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
              SizedBox(height: 10),
              Text(
                'تطبيق أندرويد لإدارة الوثائق والخدمات الإلكترونية والأرشيف. هذه نسخة أولية مبنية للحفاظ على نفس روح برنامج سطح المكتب مع واجهة عربية حديثة.',
                style: TextStyle(color: AppColors.muted, height: 1.7),
              ),
              SizedBox(height: 18),
              Text('الإصدار: 1.0.0', style: TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}
