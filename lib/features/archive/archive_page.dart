import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/archive_item.dart';
import '../../data/repositories/archive_repository.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_topbar.dart';

class ArchivePage extends StatelessWidget {
  const ArchivePage({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = ArchiveRepository();
    return Scaffold(
      appBar: const AppTopbar(
        title: 'أرشيف',
        subtitle: 'كل الوثائق والعمليات المحفوظة',
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: FutureBuilder<List<ArchiveItem>>(
          future: repository.getItems(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final items = snapshot.data!;
            if (items.isEmpty) {
              return const Center(
                child: Text(
                  'الأرشيف فارغ حاليًا',
                  style: TextStyle(color: AppColors.muted, fontSize: 16),
                ),
              );
            }
            return ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                return AppCard(
                  child: Row(
                    children: [
                      const Icon(Icons.archive_rounded, color: AppColors.warning, size: 38),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.createdAt,
                              style: const TextStyle(color: AppColors.muted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
