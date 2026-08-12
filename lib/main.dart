import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:iungo/core/routes/app_pages.dart';
import 'package:iungo/core/routes/app_routes.dart';
import 'package:iungo/core/services/session_service.dart';
import 'package:iungo/core/theme/app_theme.dart';
import 'package:iungo/core/translations/app_translations.dart';

void main() {
  Get.put<SessionService>(SessionService(), permanent: true);
  runApp(const IungoApp());
}

class IungoApp extends StatelessWidget {
  const IungoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Iungo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      translations: AppTranslations(),
      locale: const Locale('en', 'US'),
      fallbackLocale: const Locale('en', 'US'),
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('ar', 'SA'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      initialRoute: AppRoutes.splash,
      getPages: AppPages.pages,
    );
  }
}