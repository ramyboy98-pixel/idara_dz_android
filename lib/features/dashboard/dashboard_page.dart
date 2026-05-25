import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../widgets/app_card.dart';
import '../about/about_page.dart';
import '../archive/archive_page.dart';
import '../documents/documents_page.dart';
import '../services/services_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width >= 900 ? 4 : width >= 600 ? 3 : 2;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: _HomeHeader()),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
              sliver: SliverToBoxAdapter(
                child: _SectionTitle(
                  title: 'الأقسام الرئيسية',
                  subtitle: 'اختر القسم الذي تريد العمل عليه',
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              sliver: SliverGrid(
                delegate: SliverChildListDelegate.fixed([
                  _MainFeatureCard(
                    icon: Icons.description_rounded,
                    title: 'وثائق',
                    subtitle: 'إنشاء وتعبئة الوثائق',
                    accent: AppColors.blue,
                    onTap: () => _open(context, const DocumentsPage()),
                  ),
                  _MainFeatureCard(
                    icon: Icons.public_rounded,
                    title: 'خدمات إلكترونية',
                    subtitle: 'روابط وخدمات رسمية',
                    accent: AppColors.green,
                    onTap: () => _open(context, const ServicesPage()),
                  ),
                  _MainFeatureCard(
                    icon: Icons.archive_rounded,
                    title: 'أرشيف',
                    subtitle: 'الملفات المحفوظة',
                    accent: AppColors.warning,
                    onTap: () => _open(context, const ArchivePage()),
                  ),
                  _MainFeatureCard(
                    icon: Icons.info_rounded,
                    title: 'حول البرنامج',
                    subtitle: 'معلومات التطبيق',
                    accent: AppColors.sidebar,
                    onTap: () => _open(context, const AboutPage()),
                  ),
                ]),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: width < 390 ? .95 : 1.05,
                ),
              ),
            ),
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(18, 22, 18, 8),
              sliver: SliverToBoxAdapter(
                child: _SectionTitle(
                  title: 'نظرة سريعة',
                  subtitle: 'ملخص أولي لحالة التطبيق',
                ),
              ),
            ),
            const SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 18),
              sliver: SliverToBoxAdapter(child: _QuickOverview()),
            ),
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(18, 22, 18, 24),
              sliver: SliverToBoxAdapter(child: _NextStepCard()),
            ),
          ],
        ),
      ),
    );
  }

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 18, 18, 0),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.sidebar,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.10),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.12),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withOpacity(.14)),
                ),
                child: const Icon(
                  Icons.admin_panel_settings_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'IDARA DZ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .3,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'إدارة الوثائق والخدمات الإلكترونية',
                      style: TextStyle(color: Color(0xFFD1D5DB), fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'واجهة Android أولية بنفس روح نسخة سطح المكتب: بسيطة، عربية، سريعة، وموجهة للعمل اليومي.',
            style: TextStyle(
              color: Color(0xFFE5E7EB),
              height: 1.65,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              _HeaderPill(text: 'Android'),
              _HeaderPill(text: 'PDF فقط'),
              _HeaderPill(text: 'GitHub Actions'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderPill extends StatelessWidget {
  const _HeaderPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(.12)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(color: AppColors.muted, fontSize: 13),
        ),
      ],
    );
  }
}

class _MainFeatureCard extends StatefulWidget {
  const _MainFeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  @override
  State<_MainFeatureCard> createState() => _MainFeatureCardState();
}

class _MainFeatureCardState extends State<_MainFeatureCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? .97 : 1,
        duration: const Duration(milliseconds: 120),
        child: AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: widget.accent.withOpacity(.10),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(widget.icon, color: widget.accent, size: 31),
              ),
              const Spacer(),
              Text(
                widget.title,
                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                widget.subtitle,
                style: const TextStyle(color: AppColors.muted, fontSize: 12.5),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'فتح القسم',
                    style: TextStyle(
                      color: widget.accent,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_back_rounded, size: 17, color: widget.accent),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickOverview extends StatelessWidget {
  const _QuickOverview();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 650;
        final cards = const [
          _OverviewCard(
            icon: Icons.description_outlined,
            value: '4',
            label: 'أقسام رئيسية',
            color: AppColors.blue,
          ),
          _OverviewCard(
            icon: Icons.picture_as_pdf_outlined,
            value: 'PDF',
            label: 'نظام التصدير',
            color: AppColors.red,
          ),
          _OverviewCard(
            icon: Icons.cloud_done_outlined,
            value: 'CI',
            label: 'بناء عبر GitHub',
            color: AppColors.green,
          ),
        ];

        if (isWide) {
          return Row(
            children: cards
                .map((card) => Expanded(
                      child: Padding(
                        padding: const EdgeInsetsDirectional.only(end: 10),
                        child: card,
                      ),
                    ))
                .toList(),
          );
        }

        return Column(
          children: cards
              .map((card) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: card,
                  ))
              .toList(),
        );
      },
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(.10),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NextStepCard extends StatelessWidget {
  const _NextStepCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.blue.withOpacity(.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: AppColors.blue),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الخطوة القادمة',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 6),
                Text(
                  'بعد تثبيت هذه الواجهة سننتقل إلى صفحة وثائق، ثم طلب خطي، ثم أول نموذج PDF حقيقي.',
                  style: TextStyle(color: AppColors.muted, height: 1.6),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
