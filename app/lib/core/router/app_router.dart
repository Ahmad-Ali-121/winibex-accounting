import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../api/api_client.dart';
import '../../features/accounts/presentation/accounts_screen.dart';
import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/transactions/presentation/approvals_screen.dart';
import '../../features/transactions/presentation/entry_screen.dart';
import '../../features/transactions/presentation/ledger_screen.dart';
import '../../features/shell/presentation/app_shell.dart';
import '../../l10n/generated/app_localizations.dart';

part 'app_router.g.dart';

/// Route paths in one place. A typo in a path string is a runtime failure,
/// so nothing anywhere else writes one.
abstract final class Routes {
  static const login = '/login';
  static const dashboard = '/';
  static const accounts = '/accounts';
  static const transactions = '/transactions';
  static const newEntry = '/transactions/new';
  static const approvals = '/approvals';
  static const clients = '/clients';
  static const invoices = '/invoices';
  static const payroll = '/payroll';
  static const recurring = '/recurring';
  static const reports = '/reports';
  static const settings = '/settings';
}

/// Bridges a Riverpod provider to a Listenable, which is what go_router's
/// refreshListenable expects. Without it the redirect only runs on navigation,
/// not when the session changes, so signing in or out would not move the user.
class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(Ref ref) {
    ref.listen(authControllerProvider, (_, __) => notifyListeners());
    ref.listen(sessionExpiredProvider, (_, expired) {
      if (expired) notifyListeners();
    });
  }
}

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  final refresh = _AuthRefresh(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: Routes.dashboard,
    debugLogDiagnostics: false,
    refreshListenable: refresh,
    redirect: (context, state) {
      // A dropped session forces the login screen regardless of where the
      // failed request came from.
      if (ref.read(sessionExpiredProvider)) {
        return state.matchedLocation == Routes.login ? null : Routes.login;
      }

      final auth = ref.read(authControllerProvider);

      // While the session is being restored on launch, hold position. main()
      // shows a splash, so the login screen never flashes before the restore
      // finishes.
      if (auth.isLoading) return null;

      final signedIn = auth.value != null;
      final atLogin = state.matchedLocation == Routes.login;

      if (!signedIn && !atLogin) return Routes.login;
      if (signedIn && atLogin) return Routes.dashboard;
      return null;
    },
    routes: [
      GoRoute(
        path: Routes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: Routes.dashboard,
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: Routes.accounts,
            builder: (context, state) => const AccountsScreen(),
          ),
          // Declared before /transactions, so the longer path wins.
          GoRoute(
            path: Routes.newEntry,
            builder: (context, state) => const _NewEntry(),
          ),
          GoRoute(
            path: Routes.transactions,
            builder: (context, state) => const LedgerScreen(),
          ),
          GoRoute(
            path: Routes.approvals,
            builder: (context, state) => const ApprovalsScreen(),
          ),
          GoRoute(
            path: Routes.clients,
            builder: (context, state) => const _ComingSoon(module: 'clients'),
          ),
          GoRoute(
            path: Routes.invoices,
            builder: (context, state) => const _ComingSoon(module: 'invoices'),
          ),
          GoRoute(
            path: Routes.payroll,
            builder: (context, state) => const _ComingSoon(module: 'payroll'),
          ),
          GoRoute(
            path: Routes.recurring,
            builder: (context, state) => const _ComingSoon(module: 'recurring'),
          ),
          GoRoute(
            path: Routes.reports,
            builder: (context, state) => const _ComingSoon(module: 'reports'),
          ),
          GoRoute(
            path: Routes.settings,
            builder: (context, state) => const _ComingSoon(module: 'settings'),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text(AppLocalizations.of(context).errServer),
      ),
    ),
  );
}

/// Whether this person may post rather than submit for approval decides what
/// the final button says. The server decides for real: a staff login pressing
/// a button labelled "Save and post" would still get a 403, which is why the
/// label is the only thing this changes.
class _NewEntry extends ConsumerWidget {
  const _NewEntry();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(authControllerProvider).value?.role;
    return EntryScreen(canPost: role == 'owner' || role == 'admin');
  }
}

/// Placeholder until each module arrives in its phase. Deliberately plain:
/// a designed empty state belongs to the real screen, not to a stub.
class _ComingSoon extends StatelessWidget {
  const _ComingSoon({required this.module});

  final String module;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        module,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}
