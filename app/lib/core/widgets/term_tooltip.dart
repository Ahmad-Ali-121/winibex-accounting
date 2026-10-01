import 'package:flutter/material.dart';

import '../glossary/glossary.dart';
import '../theme/app_theme.dart';
import '../../l10n/generated/app_localizations.dart';

/// Wraps anything that names an accounting term.
///
/// The UI guide's rule: the interface uses the real word, Debit, Credit,
/// Journal Entry, and the tooltip explains it in this company's terms. One
/// definition per term, from the glossary, so the same word never gets two
/// different explanations on two screens.
///
/// Works on hover and on long press, which is what Tooltip already does, and
/// carries a semantics label so a screen reader gets the explanation too.
class TermTooltip extends StatelessWidget {
  const TermTooltip({
    required this.term,
    required this.child,
    this.showIcon = false,
    super.key,
  });

  final Term term;
  final Widget child;

  /// A question mark icon, only where hovering is not discoverable. Never on
  /// every label: the UI guide is explicit about that.
  final bool showIcon;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;

    final content = showIcon
        ? Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        child,
        const SizedBox(width: AppSpacing.xs),
        Icon(
          Icons.help_outline,
          size: 14,
          color: colors.textMuted,
        ),
      ],
    ): child;

    return Semantics(
      tooltip: '${term.label(l10n)}. ${term.tip(l10n)}',
      child: Tooltip(
        message: term.tip(l10n),
        triggerMode: TooltipTriggerMode.longPress,
        excludeFromSemantics: true,
        child: content,
      ),
    );
  }
}

/// The common case: the term's own label, explained.
class TermLabel extends StatelessWidget {
  const TermLabel({
    required this.term,
    this.style,
    this.showIcon = false,
    super.key,
  });

  final Term term;
  final TextStyle? style;
  final bool showIcon;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return TermTooltip(
      term: term,
      showIcon: showIcon,
      child: Text(
        term.label(l10n),
        style: style ?? Theme.of(context).textTheme.labelMedium,
      ),
    );
  }
}
