import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:iungo/core/routes/app_pages.dart';
import 'package:iungo/core/routes/app_routes.dart';
import 'package:iungo/core/services/session_service.dart';
import 'package:iungo/core/theme/app_theme.dart';
import 'package:iungo/core/translations/app_translations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load any persisted session/language before the first frame so the
  // splash screen and the initial locale are correct immediately —
  // no flash of the wrong language or an unwanted login screen.
  final session = await Get.putAsync<SessionService>(
    () => SessionService().init(),
    permanent: true,
  );

  runApp(
    IungoApp(initialLocale: session.savedLocale ?? const Locale('en', 'US')),
  );
}

class IungoApp extends StatelessWidget {
  const IungoApp({super.key, required this.initialLocale});

  final Locale initialLocale;

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Iungo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      translations: AppTranslations(),
      locale: initialLocale,
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
