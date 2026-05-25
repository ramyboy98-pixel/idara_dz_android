import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme/app_theme.dart';
import 'features/dashboard/dashboard_page.dart';

class IdaraDzApp extends StatelessWidget {
  const IdaraDzApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IDARA DZ',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      locale: const Locale('ar', 'DZ'),
      supportedLocales: const [Locale('ar', 'DZ'), Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const DashboardPage(),
    );
  }
}
