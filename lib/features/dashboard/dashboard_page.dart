import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_topbar.dart';
import '../about/about_page.dart';
import '../archive/archive_page.dart';
import '../documents/documents_page.dart';
import '../services/services_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopbar(
        title: 'IDARA DZ',
        subtitle: 'إدارة الوثائق والخدمات الإلكترونية',
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'الرئيسية',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              const Text(
                'اختر القسم الذي تريد العمل عليه.',
                style: TextStyle(color: AppColors.muted, fontSize: 15),
              ),
              const SizedBox(height: 22),
              Expanded(
                child: GridView.count(
                  crossAxisCount: MediaQuery.of(context).size.width > 700 ? 4 : 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  children: [
                    _HomeTile(
                      icon: Icons.description_rounded,
                      title: 'وثائق',
                      subtitle: 'إنشاء وتعبئة الوثائق',
                      color: AppColors.blue,
                      onTap: () => _open(context, const DocumentsPage()),
                    ),
                    _HomeTile(
                      icon: Icons.public_rounded,
                      title: 'خدمات إلكترونية',
                      subtitle: 'روابط وخدمات رسمية',
                      color: AppColors.green,
                      onTap: () => _open(context, const ServicesPage()),
                    ),
                    _HomeTile(
                      icon: Icons.archive_rounded,
                      title: 'أرشيف',
                      subtitle: 'الملفات المحفوظة',
                      color: AppColors.warning,
                      onTap: () => _open(context, const ArchivePage()),
                    ),
                    _HomeTile(
                      icon: Icons.info_rounded,
                      title: 'حول البرنامج',
                      subtitle: 'معلومات التطبيق',
                      color: AppColors.sidebar,
                      onTap: () => _open(context, const AboutPage()),
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

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }
}

class _HomeTile extends StatelessWidget {
  const _HomeTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withOpacity(.10),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
