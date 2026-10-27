import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/settings/theme_controller.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/application/auth_controller.dart';
import 'l10n/generated/app_localizations.dart';

/// The root widget. One MaterialApp.router for the whole life of the app.
///
/// It used to swap in a second, plain MaterialApp as a splash whenever the
/// session was loading. That threw the whole app away twice: on launch, where
/// the plain MaterialApp received the browser's address instead of the router,
/// so a refresh or a typed address always ended on the dashboard (F4); and on
/// every sign-in, which also set the session to loading, so the sign-in
/// screen was destroyed before it could show "That email or password is not
/// right." (F1).
///
/// Now the router exists from the first frame and keeps the address. While the
/// session is being restored on launch, the router's redirect holds position
/// and [_Splash] is drawn in place of the page. That happens once: after the
/// first answer, a later "loading" never brings the splash back, so nothing a
/// screen is showing can be thrown away by it. Signing in no longer puts the
/// session into loading in the first place.
class WinibexApp extends ConsumerStatefulWidget {
  const WinibexApp({super.key});

  @override
  ConsumerState<WinibexApp> createState() => _WinibexAppState();
}

class _WinibexAppState extends ConsumerState<WinibexApp> {
  bool _restored = false;

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeControllerProvider);
    final loading = ref.watch(authControllerProvider.select((auth) => auth.isLoading));

    // A latch, set once and never cleared.
    if (!loading) _restored = true;
    final showSplash = !_restored;

    return MaterialApp.router(
      title: 'Winibex Accounting',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => showSplash ? const _Splash() : child ?? const _Splash(),
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
