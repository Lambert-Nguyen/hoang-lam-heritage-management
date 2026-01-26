import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/env_config.dart';
import 'core/theme/app_theme.dart';
import 'core/storage/hive_storage.dart';
import 'l10n/app_localizations.dart';
import 'router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set environment (can be changed via build flavors)
  EnvConfig.setEnvironment(Environment.dev);

  // Initialize Hive storage
  await HiveStorage.init();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    const ProviderScope(
      child: HoangLamApp(),
    ),
  );
}

/// Main application widget
class HoangLamApp extends ConsumerWidget {
  const HoangLamApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      // App info
      title: EnvConfig.current.appName,
      debugShowCheckedModeBanner: !EnvConfig.current.isProd,

      // Theme
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,

      // Localization
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('vi'), // Default to Vietnamese

      // Router
      routerConfig: router,

      // Builder for text scaling (accessibility)
      builder: (context, child) {
        // Get saved text scale from settings (default 1.0)
        // final textScale = ref.watch(textScaleProvider);

        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            // textScaleFactor: textScale,
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
