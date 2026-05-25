import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../widgets/app_search_field.dart';
import '../../widgets/app_topbar.dart';
import 'linear_requests_page.dart';

class DocumentsPage extends StatefulWidget {
  const DocumentsPage({super.key});

  @override
  State<DocumentsPage> createState() => _DocumentsPageState();
}

class _DocumentsPageState extends State<DocumentsPage> {
  String _query = '';

  final List<_DocumentSection> _sections = const [
    _DocumentSection(
      title: 'طلب خطي',
      subtitle: 'طلبات التوظيف، المسابقات، التحويلات والطلبات الإدارية.',
      icon: '📄',
      accentColor: Color(0xFF2563EB),
      nextStep: 'جاهز للفتح',
    ),
    _DocumentSection(
      title: 'تصريح شرفي',
      subtitle: 'تصريحات وتعهدات جاهزة للتعبئة والتصدير PDF.',
      icon: '📝',
      accentColor: Color(0xFF7C3AED),
      nextStep: 'قريبًا',
    ),
    _DocumentSection(
      title: 'سيرة ذاتية',
      subtitle: 'إنشاء سيرة ذاتية عربية بسيطة ومنظمة بصيغة PDF.',
      icon: '👤',
      accentColor: Color(0xFF059669),
      nextStep: 'قريبًا',
    ),
    _DocumentSection(
      title: 'فاتورة',
      subtitle: 'إنشاء فاتورة خدمات أو مبيعات مع المجموع والتاريخ.',
      icon: '🧾',
      accentColor: Color(0xFFF59E0B),
      nextStep: 'قريبًا',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final filteredSections = _sections.where((section) {
      final query = _query.trim();
      if (query.isEmpty) return true;
      return section.title.contains(query) || section.subtitle.contains(query);
    }).toList();

    return Scaffold(
      appBar: const AppTopbar(
        title: 'وثائق',
        subtitle: 'اختر نوع الوثيقة التي تريد إنشاءها',
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
          children: [
            const _DocumentsHero(),
            const SizedBox(height: 18),
            AppSearchField(
              hint: 'ابحث داخل أقسام الوثائق...',
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 18),
            if (filteredSections.isEmpty)
              const _EmptyState()
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 720;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredSections.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isWide ? 2 : 1,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      mainAxisExtent: 156,
                    ),
                    itemBuilder: (context, index) {
                      final section = filteredSections[index];
                      return _DocumentSectionCard(
                        section: section,
                        onTap: () => _openSection(context, section),
                      );
                    },
                  );
                },
              ),
            const SizedBox(height: 18),
            const _NextWorkCard(),
          ],
        ),
      ),
    );
  }

  void _openSection(BuildContext context, _DocumentSection section) {
    if (section.title == 'طلب خطي') {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const LinearRequestsPage(),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text('سيتم تجهيز قسم ${section.title} بعد إكمال طلب خطي.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}

class _DocumentSection {
  const _DocumentSection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.nextStep,
  });

  final String title;
  final String subtitle;
  final String icon;
  final Color accentColor;
  final String nextStep;
}

class _DocumentsHero extends StatelessWidget {
  const _DocumentsHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.sidebar,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('📁', style: TextStyle(fontSize: 34)),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'مركز الوثائق',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            'هذه الصفحة ستكون بوابة إنشاء الوثائق داخل IDARA DZ. نبدأ بالأقسام الرئيسية، ثم نضيف داخل كل قسم النماذج الخاصة به.',
            style: TextStyle(
              color: Color(0xFFD1D5DB),
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentSectionCard extends StatefulWidget {
  const _DocumentSectionCard({
    required this.section,
    required this.onTap,
  });

  final _DocumentSection section;
  final VoidCallback onTap;

  @override
  State<_DocumentSectionCard> createState() => _DocumentSectionCardState();
}

class _DocumentSectionCardState extends State<_DocumentSectionCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final section = widget.section;

    return AnimatedScale(
      scale: _pressed ? 0.985 : 1,
      duration: const Duration(milliseconds: 110),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: widget.onTap,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          child: Ink(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.045),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 62,
                  height: 62,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: section.accentColor.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(section.icon, style: const TextStyle(fontSize: 32)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              section.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.text,
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          _StatusBadge(
                            text: section.nextStep,
                            color: section.accentColor,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        section.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 13.5,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_left_rounded,
                  color: section.accentColor,
                  size: 28,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _NextWorkCard extends StatelessWidget {
  const _NextWorkCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: const Row(
        children: [
          Icon(Icons.route_rounded, color: AppColors.blue),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'قسم طلب خطي أصبح قابلًا للفتح الآن. اضغط على بطاقة طلب خطي للدخول إلى بطاقات النماذج، وبعدها نبدأ بإضافة نموذج الإدخال والتصدير PDF.',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 13.5,
                height: 1.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        children: [
          Icon(Icons.search_off_rounded, size: 42, color: AppColors.muted),
          SizedBox(height: 12),
          Text(
            'لا توجد نتائج مطابقة',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 6),
          Text(
            'جرّب البحث باسم قسم آخر.',
            style: TextStyle(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
