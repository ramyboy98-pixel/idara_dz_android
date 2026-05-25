import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/custom_document_template.dart';
import '../../data/repositories/custom_templates_repository.dart';
import '../../widgets/app_search_field.dart';
import '../../widgets/app_topbar.dart';
import 'add_linear_request_template_page.dart';

class LinearRequestsPage extends StatefulWidget {
  const LinearRequestsPage({super.key});

  @override
  State<LinearRequestsPage> createState() => _LinearRequestsPageState();
}

class _LinearRequestsPageState extends State<LinearRequestsPage> {
  final CustomTemplatesRepository _repository = const CustomTemplatesRepository();
  String _query = '';
  late Future<List<CustomDocumentTemplate>> _templatesFuture;

  @override
  void initState() {
    super.initState();
    _templatesFuture = _repository.getTemplates('طلب خطي');
  }

  void _refresh() {
    setState(() {
      _templatesFuture = _repository.getTemplates('طلب خطي');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopbar(
        title: 'طلب خطي',
        subtitle: 'أضف نماذجك الخاصة واستعملها لاحقًا للتعبئة الآلية',
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddTemplatePage,
        backgroundColor: AppColors.blue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('إضافة نموذج'),
      ),
      body: SafeArea(
        child: FutureBuilder<List<CustomDocumentTemplate>>(
          future: _templatesFuture,
          builder: (context, snapshot) {
            final templates = snapshot.data ?? [];
            final filteredTemplates = templates.where((template) {
              final query = _query.trim();
              if (query.isEmpty) return true;
              return template.title.contains(query) ||
                  (template.description ?? '').contains(query);
            }).toList();

            return RefreshIndicator(
              onRefresh: () async => _refresh(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 96),
                children: [
                  const _LinearRequestsHero(),
                  const SizedBox(height: 18),
                  AppSearchField(
                    hint: 'ابحث في النماذج المحفوظة...',
                    onChanged: (value) => setState(() => _query = value),
                  ),
                  const SizedBox(height: 18),
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const _LoadingBox()
                  else if (templates.isEmpty)
                    _EmptyTemplatesBox(onAdd: _openAddTemplatePage)
                  else if (filteredTemplates.isEmpty)
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
                            mainAxisExtent: 172,
                          ),
                          itemBuilder: (context, index) {
                            final template = filteredTemplates[index];
                            return _SavedTemplateCard(
                              template: template,
                              onTap: () => _showUseTemplateMessage(template),
                              onDelete: () => _deleteTemplate(template),
                            );
                          },
                        );
                      },
                    ),
                  const SizedBox(height: 18),
                  const _WorkflowCard(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _openAddTemplatePage() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => const AddLinearRequestTemplatePage(),
      ),
    );
    if (changed == true) {
      _refresh();
      _showMessage('تم حفظ النموذج بنجاح.');
    }
  }

  void _showUseTemplateMessage(CustomDocumentTemplate template) {
    _showMessage('المرحلة القادمة: فتح استمارة "${template.title}" وملؤها ثم توليد PDF.');
  }

  Future<void> _deleteTemplate(CustomDocumentTemplate template) async {
    final id = template.id;
    if (id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف النموذج'),
        content: Text('هل تريد حذف "${template.title}" من صفحة طلب خطي؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await _repository.deleteTemplate(id);
    _refresh();
    _showMessage('تم حذف النموذج.');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
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
                  'نماذج الطلب الخطي الخاصة بك',
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
            'هذه الصفحة لا تحتوي على نماذج ثابتة. أضف النموذج من الهاتف، ثم أنشئ استمارة معلوماته، وسيظهر هنا لاستعماله لاحقًا.',
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

class _SavedTemplateCard extends StatefulWidget {
  const _SavedTemplateCard({
    required this.template,
    required this.onTap,
    required this.onDelete,
  });

  final CustomDocumentTemplate template;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  State<_SavedTemplateCard> createState() => _SavedTemplateCardState();
}

class _SavedTemplateCardState extends State<_SavedTemplateCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final template = widget.template;
    final hasFile = (template.templateFilePath ?? '').isNotEmpty;

    return AnimatedScale(
      scale: _pressed ? 0.985 : 1,
      duration: const Duration(milliseconds: 110),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: widget.onTap,
          onHighlightChanged: (value) => setState(() => _pressed = value),
          child: Ink(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 18,
                  offset: const Offset(0, 9),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Text('📄', style: TextStyle(fontSize: 25)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          template.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: widget.onDelete,
                        icon: const Icon(Icons.delete_outline_rounded),
                        color: AppColors.red,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    (template.description ?? '').isEmpty
                        ? 'نموذج مضاف من الهاتف وجاهز لإعداد الاستمارة.'
                        : template.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      _ChipLabel(
                        icon: Icons.list_alt_rounded,
                        label: '${template.fieldsCount} حقول',
                      ),
                      const SizedBox(width: 8),
                      _ChipLabel(
                        icon: hasFile ? Icons.attach_file_rounded : Icons.error_outline_rounded,
                        label: hasFile ? 'ملف محفوظ' : 'دون ملف',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChipLabel extends StatelessWidget {
  const _ChipLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.muted),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyTemplatesBox extends StatelessWidget {
  const _EmptyTemplatesBox({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Text('📂', style: TextStyle(fontSize: 44)),
          const SizedBox(height: 10),
          const Text(
            'لا توجد نماذج طلب خطي بعد',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'اضغط على إضافة نموذج، اختر ملف النموذج من الهاتف، ثم أنشئ استمارة المعلومات الخاصة به.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.muted,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('إضافة نموذج الآن'),
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
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'طريقة العمل النهائية',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'إضافة نموذج من الهاتف ← إعداد استمارة معلومات ← حفظ النموذج في هذه الصفحة ← ملء الاستمارة لاحقًا ← توليد PDF وأرشفته.',
            style: TextStyle(
              color: AppColors.muted,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingBox extends StatelessWidget {
  const _LoadingBox();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _NoSearchResultsBox extends StatelessWidget {
  const _NoSearchResultsBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: const Text(
        'لا توجد نتائج مطابقة للبحث.',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.muted),
      ),
    );
  }
}
