import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/document_category.dart';
import '../../data/repositories/documents_repository.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_search_field.dart';
import '../../widgets/app_topbar.dart';

class DocumentsPage extends StatefulWidget {
  const DocumentsPage({super.key});

  @override
  State<DocumentsPage> createState() => _DocumentsPageState();
}

class _DocumentsPageState extends State<DocumentsPage> {
  final DocumentsRepository _repository = DocumentsRepository();
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopbar(
        title: 'وثائق',
        subtitle: 'الأقسام والنماذج الخاصة بالوثائق',
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            AppSearchField(
              hint: 'ابحث عن وثيقة أو قسم...',
              onChanged: (value) => setState(() => _query = value.trim()),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<DocumentCategory>>(
                future: _repository.getCategories(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final items = snapshot.data!
                      .where((e) => e.name.contains(_query))
                      .toList();
                  if (items.isEmpty) {
                    return const Center(child: Text('لا توجد نتائج'));
                  }
                  return ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return AppCard(
                        onTap: () {},
                        child: Row(
                          children: [
                            Text(item.icon ?? '📄', style: const TextStyle(fontSize: 34)),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'سيتم ربط هذا القسم بالنماذج في المرحلة القادمة.',
                                    style: TextStyle(color: AppColors.muted),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_left_rounded),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
