import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/env_config.dart';
import 'providers/settings_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/storage/hive_storage.dart';
import 'l10n/app_localizations.dart';
import 'router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set environment via --dart-define=ENV=prod (defaults to dev)
  const envName = String.fromEnvironment('ENV', defaultValue: 'dev');
  final env = Environment.values.firstWhere(
    (e) => e.name == envName,
    orElse: () => Environment.dev,
  );
  EnvConfig.setEnvironment(env);

  // Initialize Hive storage
  await HiveStorage.init();

  // Set preferred orientations (not supported on web)
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Set status bar to transparent (nav bar color set dynamically in app builder)
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
    );
  }

  runApp(const ProviderScope(child: HoangLamApp()));
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
      themeMode: ref.watch(themeModeProvider),

      // Localization
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: ref.watch(localeProvider),

      // Router
      routerConfig: router,

      // Builder for text scaling (accessibility) and system UI styling
      builder: (context, child) {
        // Get saved text scale from settings (default 1.0)
        final textScale = ref.watch(textScaleFactorProvider);

        // Set system nav bar color based on current theme brightness
        if (!kIsWeb) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          SystemChrome.setSystemUIOverlayStyle(
            SystemUiOverlayStyle(
              statusBarIconBrightness:
                  isDark ? Brightness.light : Brightness.dark,
              systemNavigationBarColor: isDark ? Colors.black : Colors.white,
              systemNavigationBarIconBrightness:
                  isDark ? Brightness.light : Brightness.dark,
            ),
          );
        }

        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
