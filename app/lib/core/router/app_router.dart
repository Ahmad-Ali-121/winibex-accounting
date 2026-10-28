import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../api/api_client.dart';
import '../theme/app_theme.dart';
import '../../features/accounts/presentation/accounts_screen.dart';
import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/presentation/change_password_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/flags/presentation/flags_screen.dart';
import '../../features/money/presentation/opening_entry_screen.dart';
import '../../features/people/presentation/people_screen.dart';
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
  static const changePassword = '/change-password';
  static const dashboard = '/';
  static const accounts = '/accounts';
  static const openingEntry = '/accounts/opening';
  static const transactions = '/transactions';
  static const newEntry = '/transactions/new';
  static const approvals = '/approvals';
  static const flags = '/flags';
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

      final user = auth.value;
      final signedIn = user != null;
      final atLogin = state.matchedLocation == Routes.login;
      final atChange = state.matchedLocation == Routes.changePassword;

      if (!signedIn && !atLogin) return Routes.login;
      if (signedIn && atLogin) return Routes.dashboard;

      // The owner is bootstrapped with a temporary password. Until it is
      // changed, the only screen reachable is the change-password one.
      if (signedIn && user.mustChangePassword && !atChange) {
        return Routes.changePassword;
      }
      // Once changed, nobody should sit on that screen.
      if (signedIn && !user.mustChangePassword && atChange) {
        return Routes.dashboard;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: Routes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: Routes.changePassword,
        builder: (context, state) => const ChangePasswordScreen(forced: true),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: Routes.dashboard,
            builder: (context, state) => const DashboardScreen(),
          ),
          // Declared before /accounts, so the longer path wins.
          GoRoute(
            path: Routes.openingEntry,
            builder: (context, state) => const _OpeningEntry(),
          ),
          GoRoute(
            path: Routes.accounts,
            builder: (context, state) => const _Accounts(),
          ),
          // Declared before /transactions, so the longer path wins.
          GoRoute(
            path: Routes.newEntry,
            builder: (context, state) => const _NewEntry(),
          ),
          GoRoute(
            path: Routes.transactions,
            builder: (context, state) => const _Ledger(),
          ),
          GoRoute(
            path: Routes.approvals,
            builder: (context, state) => const ApprovalsScreen(),
          ),
          GoRoute(
            path: Routes.flags,
            builder: (context, state) => const _Flags(),
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
            builder: (context, state) => const _Settings(),
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

/// Whether this person's own entry posts straight away decides what the final
/// button says and does: post it, or submit it for someone else. The server
/// decides for real; this keeps the app from offering what it would refuse.
///
/// It was "owner or admin", which offered "Save and post" to admins who may
/// not post their own entries. D4.
class _NewEntry extends ConsumerWidget {
  const _NewEntry();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    return EntryScreen(canPost: user?.canPostOwnEntries ?? false);
  }
}

/// Moving money and paying people back are for the owner and admins; the
/// opening balances are the owner's. The server checks again. Decision 065.
class _Accounts extends ConsumerWidget {
  const _Accounts();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    return AccountsScreen(
      canMoveMoney: user?.canApprove ?? false,
      onOpeningBalances: (user?.isOwner ?? false) ? () => context.go(Routes.openingEntry) : null,
    );
  }
}

class _OpeningEntry extends ConsumerWidget {
  const _OpeningEntry();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    return OpeningEntryScreen(isOwner: user?.isOwner ?? false);
  }
}

/// Only the owner and admins may reverse an entry. Decision 065.
class _Ledger extends ConsumerWidget {
  const _Ledger();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    return LedgerScreen(canReverse: user?.canApprove ?? false);
  }
}

/// Only the owner and admins may mark a flag reviewed, so only they see the
/// button. The server checks again. Decision 056.
class _Flags extends ConsumerWidget {
  const _Flags();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    return FlagsScreen(canReview: user?.canApprove ?? false);
  }
}

/// Settings opens on People for now. Only the owner adds people or changes
/// what they can do, so everyone else sees one line saying so. The server
/// refuses them anyway. Decision 063.
class _Settings extends ConsumerWidget {
  const _Settings();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    if (user?.isOwner ?? false) return const PeopleScreen();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Text(
          AppLocalizations.of(context).peopleOwnerOnly,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
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
