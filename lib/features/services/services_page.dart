import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/service_link.dart';
import '../../data/repositories/services_repository.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_search_field.dart';
import '../../widgets/app_topbar.dart';

class ServicesPage extends StatefulWidget {
  const ServicesPage({super.key});

  @override
  State<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends State<ServicesPage> {
  final ServicesRepository _repository = ServicesRepository();
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopbar(
        title: 'خدمات إلكترونية',
        subtitle: 'روابط الخدمات الرسمية والمواقع المهمة',
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            AppSearchField(
              hint: 'ابحث عن خدمة...',
              onChanged: (value) => setState(() => _query = value.trim()),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<ServiceLink>>(
                future: _repository.getLinks(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final items = snapshot.data!
                      .where((e) => e.title.contains(_query) || e.url.contains(_query))
                      .toList();
                  if (items.isEmpty) {
                    return const Center(child: Text('لا توجد خدمات بعد'));
                  }
                  return ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return AppCard(
                        onTap: () => _openUrl(item.url),
                        child: Row(
                          children: [
                            if (item.iconAsset != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.asset(
                                  item.iconAsset!,
                                  width: 46,
                                  height: 46,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.public_rounded),
                                ),
                              )
                            else
                              const Icon(Icons.public_rounded, size: 42, color: AppColors.green),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.url,
                                    style: const TextStyle(color: AppColors.muted, fontSize: 12),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.open_in_new_rounded),
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

  Future<void> _openUrl(String value) async {
    final uri = Uri.parse(value);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
