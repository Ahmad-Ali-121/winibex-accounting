import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/settings/theme_controller.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/application/auth_controller.dart';
import 'l10n/generated/app_localizations.dart';

class WinibexApp extends ConsumerWidget {
  const WinibexApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Resolve the session once before handing over to the router, so the first
    // frame is a splash rather than a flash of the login screen on every launch.
    final auth = ref.watch(authControllerProvider);

    if (auth.isLoading) {
      final themeMode = ref.watch(themeControllerProvider);
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: themeMode,
        home: const Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return const _RoutedApp();
  }
}

class _RoutedApp extends ConsumerWidget {
  const _RoutedApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeControllerProvider);

    return MaterialApp.router(
      title: 'Winibex Accounting',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
