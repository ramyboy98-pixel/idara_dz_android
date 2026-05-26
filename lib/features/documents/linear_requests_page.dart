import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../widgets/app_search_field.dart';
import '../../widgets/app_topbar.dart';
import 'fixed_substitution_request_page.dart';

class LinearRequestsPage extends StatefulWidget {
  const LinearRequestsPage({super.key});

  @override
  State<LinearRequestsPage> createState() => _LinearRequestsPageState();
}

class _LinearRequestsPageState extends State<LinearRequestsPage> {
  String _query = '';

  final List<_FixedRequestTemplate> _templates = const [
    _FixedRequestTemplate(
      title: 'طلب منصب استخلاف',
      subtitle: 'طلب خطي لمنصب أستاذ مستخلف حسب المادة والخبرة والشهادة.',
      icon: '📄',
      fieldsCount: 14,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final query = _query.trim();
    final filteredTemplates = _templates.where((template) {
      if (query.isEmpty) return true;
      return template.title.contains(query) || template.subtitle.contains(query);
    }).toList();

    return Scaffold(
      appBar: const AppTopbar(
        title: 'طلب خطي',
        subtitle: 'نماذج ثابتة مضبوطة داخل التطبيق',
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
          children: [
            const _LinearRequestsHero(),
            const SizedBox(height: 18),
            AppSearchField(
              hint: 'ابحث في نماذج الطلب الخطي...',
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 18),
            if (filteredTemplates.isEmpty)
              const _NoSearchResultsBox()
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 720;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredTemplates.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isWide ? 2 : 1,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      mainAxisExtent: 170,
                    ),
                    itemBuilder: (context, index) {
                      final template = filteredTemplates[index];
                      return _FixedTemplateCard(
                        template: template,
                        onTap: () => _openTemplate(template),
                      );
                    },
                  );
                },
              ),
            const SizedBox(height: 18),
            const _WorkflowCard(),
          ],
        ),
      ),
    );
  }

  void _openTemplate(_FixedRequestTemplate template) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const FixedSubstitutionRequestPage(),
      ),
    );
  }
}

class _FixedRequestTemplate {
  const _FixedRequestTemplate({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.fieldsCount,
  });

  final String title;
  final String subtitle;
  final String icon;
  final int fieldsCount;
}

class _LinearRequestsHero extends StatelessWidget {
  const _LinearRequestsHero();

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
              Text('📄', style: TextStyle(fontSize: 34)),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'نماذج الطلب الخطي',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            'هذه الصفحة تعتمد الآن على نماذج ثابتة داخل التطبيق. كل نموذج له استمارة معلومات وتصدير PDF مضبوط من الكود مباشرة.',
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

class _FixedTemplateCard extends StatefulWidget {
  const _FixedTemplateCard({required this.template, required this.onTap});

  final _FixedRequestTemplate template;
  final VoidCallback onTap;

  @override
  State<_FixedTemplateCard> createState() => _FixedTemplateCardState();
}

class _FixedTemplateCardState extends State<_FixedTemplateCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1,
        duration: const Duration(milliseconds: 120),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 18,
                offset: const Offset(0, 10),
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
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Center(
                      child: Text(widget.template.icon, style: const TextStyle(fontSize: 26)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.template.title,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.muted, size: 18),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                widget.template.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.muted, height: 1.5),
              ),
              const Spacer(),
              Row(
                children: [
                  const Icon(Icons.fact_check_outlined, size: 17, color: AppColors.blue),
                  const SizedBox(width: 6),
                  Text(
                    '${widget.template.fieldsCount} حقل معلومات',
                    style: const TextStyle(
                      color: AppColors.blue,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoSearchResultsBox extends StatelessWidget {
  const _NoSearchResultsBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        children: [
          Text('🔎', style: TextStyle(fontSize: 44)),
          SizedBox(height: 10),
          Text(
            'لا يوجد نموذج بهذا الاسم.',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkflowCard extends StatelessWidget {
  const _WorkflowCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.verified_rounded, color: AppColors.green),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'المسار الجديد: اختيار نموذج ثابت، ملء الاستمارة، إنشاء PDF، ثم حفظه أو مشاركته من الهاتف.',
              style: TextStyle(color: AppColors.text, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
