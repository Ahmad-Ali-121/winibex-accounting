import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/settings/theme_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/auth/application/auth_controller.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Left navigation by module on desktop, bottom bar on mobile, as the UI guide
/// specifies. The shell is built once and the child swaps, so moving between
/// modules does not rebuild the navigation.
class AppShell extends ConsumerWidget {
  const AppShell({required this.child, super.key});

  final Widget child;

  static const _mobileBreakpoint = 840.0;

  /// Order matters twice over. The rail reads top to bottom, and the bottom
  /// bar on mobile shows only the first five, so the five that earn their
  /// place on a phone are at the top.
  List<_Destination> _destinations(AppLocalizations l10n) => [
        _Destination(Routes.dashboard, l10n.navDashboard, Icons.dashboard_outlined),
        _Destination(Routes.accounts, l10n.navAccounts, Icons.account_balance_outlined),
        _Destination(Routes.newEntry, l10n.navNewEntry, Icons.add_circle_outline),
        _Destination(Routes.transactions, l10n.navTransactions, Icons.receipt_long_outlined),
        _Destination(Routes.approvals, l10n.navApprovals, Icons.fact_check_outlined),
        _Destination(Routes.clients, l10n.navClients, Icons.people_outline),
        _Destination(Routes.invoices, l10n.navInvoices, Icons.description_outlined),
        _Destination(Routes.payroll, l10n.navPayroll, Icons.payments_outlined),
        _Destination(Routes.recurring, l10n.navRecurring, Icons.autorenew),
        _Destination(Routes.reports, l10n.navReports, Icons.insert_chart_outlined),
        _Destination(Routes.settings, l10n.navSettings, Icons.settings_outlined),
      ];

  int _indexFor(String location, List<_Destination> destinations) {
    // Longest match first, so /transactions does not match / by accident.
    var best = 0;
    var bestLength = 0;
    for (var i = 0; i < destinations.length; i++) {
      final path = destinations[i].path;
      if (location == path || (path != '/' && location.startsWith(path))) {
        if (path.length > bestLength) {
          best = i;
          bestLength = path.length;
        }
      }
    }
    return best;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final destinations = _destinations(l10n);
    final location = GoRouterState.of(context).uri.path;
    final selected = _indexFor(location, destinations);

    final isNarrow = MediaQuery.sizeOf(context).width < _mobileBreakpoint;

    void go(int index) => context.go(destinations[index].path);

    if (isNarrow) {
      return Scaffold(
        appBar: _TopBar(title: destinations[selected].label),
        body: child,
        bottomNavigationBar: NavigationBar(
          selectedIndex: selected.clamp(0, 4),
          onDestinationSelected: go,
          destinations: [
            for (final d in destinations.take(5))
              NavigationDestination(icon: Icon(d.icon), label: d.label),
          ],
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          Container(
            width: AppSizes.navRailWidth,
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border(right: BorderSide(color: colors.rule)),
            ),
            child: _Rail(
              destinations: destinations,
              selected: selected,
              onSelected: go,
            ),
          ),
          Expanded(
            child: Column(
              children: [
                _TopBar(title: destinations[selected].label),
                Expanded(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: AppSizes.contentMaxWidth),
                      child: child,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Rail extends StatelessWidget {
  const _Rail({
    required this.destinations,
    required this.selected,
    required this.onSelected,
  });

  final List<_Destination> destinations;
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Text(
            l10n.appName,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            itemCount: destinations.length,
            itemBuilder: (context, index) {
              final d = destinations[index];
              final isSelected = index == selected;

              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
                child: Material(
                  color: isSelected ? colors.accentSoft : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadii.control),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadii.control),
                    onTap: () => onSelected(index),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.md,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            d.icon,
                            size: 18,
                            color: isSelected ? colors.accent : colors.textMuted,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Text(
                              d.label,
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: isSelected ? colors.accent : colors.text,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TopBar extends ConsumerWidget implements PreferredSizeWidget {
  const _TopBar({required this.title});

  final String title;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final mode = ref.watch(themeControllerProvider);

    final icon = switch (mode) {
      ThemeMode.system => Icons.brightness_auto_outlined,
      ThemeMode.light => Icons.light_mode_outlined,
      ThemeMode.dark => Icons.dark_mode_outlined,
    };

    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(bottom: BorderSide(color: colors.rule)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
          IconButton(
            onPressed: () => ref.read(themeControllerProvider.notifier).cycle(),
            icon: Icon(icon, size: 20),
            tooltip: l10n.a11yToggleTheme,
          ),
          IconButton(
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
            icon: const Icon(Icons.logout, size: 20),
            tooltip: l10n.actionSignOut,
          ),
        ],
      ),
    );
  }
}

class _Destination {
  const _Destination(this.path, this.label, this.icon);

  final String path;
  final String label;
  final IconData icon;
}
