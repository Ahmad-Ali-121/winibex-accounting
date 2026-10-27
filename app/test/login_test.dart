import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:winibex_accounting/app.dart';
import 'package:winibex_accounting/core/api/api_exception.dart';
import 'package:winibex_accounting/core/settings/preferences.dart';
import 'package:winibex_accounting/core/theme/app_theme.dart';
import 'package:winibex_accounting/features/auth/application/auth_controller.dart';
import 'package:winibex_accounting/features/auth/domain/auth_user.dart';
import 'package:winibex_accounting/features/auth/presentation/login_screen.dart';
import 'package:winibex_accounting/l10n/generated/app_localizations.dart';

/// A stand-in for AuthController, so the login screen is tested without a real
/// network. Overriding the controller rather than the Dio client keeps the
/// test about the screen's behaviour, not about HTTP.
///
/// Its login still puts the session into loading, as the real one did before
/// F1. The real-app test at the bottom relies on that: it proves the app
/// itself no longer throws the sign-in screen away when the session loads.
class FakeAuthController extends AuthController {
  FakeAuthController(this._behaviour);

  final Future<AuthUser?> Function(String email, String password) _behaviour;

  @override
  Future<AuthUser?> build() async => null;

  @override
  Future<Object?> login({required String email, required String password}) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() => _behaviour(email, password));
    state = result;
    return result.hasError ? result.error : null;
  }
}

Widget harness(AuthController controller) {
  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(() => controller,),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const LoginScreen(),
    ),
  );
}

void main() {
  testWidgets('empty fields are caught before any request', (tester) async {
    var called = false;
    await tester.pumpWidget(harness(FakeAuthController((e, p) async {
      called = true;
      return null;
    }),),);

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));

    await tester.tap(find.widgetWithText(FilledButton, l10n.actionSignIn));
    await tester.pump();

    expect(find.text(l10n.loginEmailRequired), findsOneWidget);
    expect(find.text(l10n.loginPasswordRequired), findsOneWidget);
    expect(called, isFalse, reason: 'a request was sent despite empty fields');
  });

  testWidgets('a wrong password shows the sign-in error, not a raw code', (tester) async {
    await tester.pumpWidget(harness(FakeAuthController((e, p) async {
      throw const ApiException(
        code: 'INVALID_CREDENTIALS',
        message: 'That email or password is not right.',
        status: 401,
      );
    }),),);

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));

    await tester.enterText(find.byType(TextFormField).first, 'owner@test.local');
    await tester.enterText(find.byType(TextFormField).last, 'wrong-password');
    await tester.tap(find.widgetWithText(FilledButton, l10n.actionSignIn));
    await tester.pumpAndSettle();

    expect(find.text(l10n.errSignIn), findsOneWidget);
    expect(find.textContaining('INVALID_CREDENTIALS'), findsNothing);
  });

  testWidgets('being rate limited shows the throttle message', (tester) async {
    await tester.pumpWidget(harness(FakeAuthController((e, p) async {
      throw const ApiException(code: 'RATE_LIMITED', message: 'x', status: 429);
    }),),);

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));

    await tester.enterText(find.byType(TextFormField).first, 'staff@test.local');
    await tester.enterText(find.byType(TextFormField).last, 'password');
    await tester.tap(find.widgetWithText(FilledButton, l10n.actionSignIn));
    await tester.pumpAndSettle();

    expect(find.text(l10n.errTooManyAttempts), findsOneWidget);
  });

  testWidgets('a network failure tells the user to check their connection', (tester) async {
    await tester.pumpWidget(harness(FakeAuthController((e, p) async {
      throw const ApiException(code: 'NETWORK', message: 'x');
    }),),);

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));

    await tester.enterText(find.byType(TextFormField).first, 'owner@test.local');
    await tester.enterText(find.byType(TextFormField).last, 'password');
    await tester.tap(find.widgetWithText(FilledButton, l10n.actionSignIn));
    await tester.pumpAndSettle();

    expect(find.text(l10n.errNetwork), findsOneWidget);
  });

  // Defect F1. The tests above pump the sign-in screen on its own, which is why
  // none of them noticed that inside the real app a sign-in attempt replaced
  // the whole app with a splash and the error was lost with the old screen.
  testWidgets('inside the real app, a wrong password still shows its message', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          authControllerProvider.overrideWith(
            () => FakeAuthController((e, p) async {
              throw const ApiException(
                code: 'INVALID_CREDENTIALS',
                message: 'That email or password is not right.',
                status: 401,
              );
            }),
          ),
        ],
        child: const WinibexApp(),
      ),
    );
    await tester.pumpAndSettle();

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(find.widgetWithText(FilledButton, l10n.actionSignIn), findsOneWidget,
        reason: 'signed out, so the router shows the sign-in screen',
    );

    await tester.enterText(find.byType(TextFormField).first, 'owner@test.local');
    await tester.enterText(find.byType(TextFormField).last, 'wrong-password');
    await tester.tap(find.widgetWithText(FilledButton, l10n.actionSignIn));
    await tester.pumpAndSettle();

    expect(find.text(l10n.errSignIn), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing, reason: 'the splash came back');
  });

  testWidgets('a successful sign-in leaves the controller holding the user', (tester) async {
    const user = AuthUser(
      id: 1,
      name: 'Winibex office',
      email: 'owner@test.local',
      role: 'owner',
      mustChangePassword: true,
    );

    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(
              () => FakeAuthController((e, p) async => user),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(authControllerProvider.notifier).login(
      email: 'owner@test.local',
      password: 'Winibex123#',
    );

    final result = container.read(authControllerProvider).value;
    expect(result, isNotNull);
    expect(result!.role, 'owner');
    expect(result.mustChangePassword, isTrue);
  });
}
