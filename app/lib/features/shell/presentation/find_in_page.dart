import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Find on this screen: Ctrl+F (Cmd+F on a Mac) inside the app. Decision 068.
///
/// Flutter web paints text onto a canvas, so the browser's own Ctrl+F finds
/// nothing in the app. This does the same job for what is on screen: it reads
/// the text the page is showing, highlights every match, and steps through
/// them. It does not search the database; the search box on Transactions
/// does that, across every entry.
///
/// [FindScope] holds the state and listens for the keys. [FindTarget] marks
/// the part of the screen that is searched, and draws the highlights and the
/// find bar over it. The menu and the top bar are outside it, so their words
/// are never matches.
class FindScope extends StatefulWidget {
  const FindScope({super.key, required this.location, required this.child});

  /// The page's address. A new page means new text, so the matches are found
  /// again.
  final String location;
  final Widget child;

  /// For widgets that only call [FindScopeState.open], such as the top bar's
  /// button. Does not rebuild them when matches change.
  static FindScopeState? read(BuildContext context) => context.getInheritedWidgetOfExactType<_FindInherited>()?.state;

  static FindScopeState? _watch(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_FindInherited>()?.state;

  @override
  State<FindScope> createState() => FindScopeState();
}

/// Every place [query] appears in [text], ignoring case, as offsets.
/// Matches do not overlap, as in a browser.
List<int> matchOffsets(String text, String query) {
  final needle = query.toLowerCase();
  if (needle.isEmpty) return const [];
  final haystack = text.toLowerCase();
  final found = <int>[];
  var from = 0;
  while (true) {
    final at = haystack.indexOf(needle, from);
    if (at < 0) break;
    found.add(at);
    from = at + needle.length;
  }
  return found;
}

class _Match {
  const _Match(this.element, this.paragraph, this.start, this.end, this.anchor);

  final Element element;
  final RenderParagraph paragraph;
  final int start;
  final int end;

  /// Where it was when found, for ordering top to bottom, left to right.
  final Offset anchor;

  TextSelection get selection => TextSelection(baseOffset: start, extentOffset: end);

  bool sameAs(_Match other) => identical(paragraph, other.paragraph) && start == other.start;
}

class _Repaint extends ChangeNotifier {
  void tick() => notifyListeners();
}

class FindScopeState extends State<FindScope> {
  final _contentKey = GlobalKey(debugLabel: 'find-content');
  final _paintKey = GlobalKey(debugLabel: 'find-paint');
  final _repaint = _Repaint();
  final query = TextEditingController();
  final fieldFocus = FocusNode(debugLabel: 'find-field');

  bool isOpen = false;
  List<_Match> _matches = const [];
  int _current = -1;
  int _version = 0;
  String _lastQuery = '';

  int get matchCount => _matches.length;

  /// Which match is current, counting from 1. Zero when there is none.
  int get currentNumber => _current + 1;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
    query.addListener(_onQueryChanged);
  }

  @override
  void didUpdateWidget(FindScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.location != widget.location && isOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _rescan(reveal: false);
      });
    }
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    query.removeListener(_onQueryChanged);
    query.dispose();
    fieldFocus.dispose();
    _repaint.dispose();
    super.dispose();
  }

  void _update(VoidCallback change) {
    setState(() {
      change();
      _version++;
    });
    _repaint.tick();
  }

  /// Ctrl+F or Cmd+F opens the bar; Escape closes it. Not while a dialog is
  /// on top: the keys are left to the dialog and the browser then.
  bool _onKey(KeyEvent event) {
    if (event is! KeyDownEvent || !mounted) return false;
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) return false;

    final keyboard = HardwareKeyboard.instance;
    if (event.logicalKey == LogicalKeyboardKey.keyF && (keyboard.isControlPressed || keyboard.isMetaPressed)) {
      open();
      return true;
    }
    if (isOpen && event.logicalKey == LogicalKeyboardKey.escape) {
      close();
      return true;
    }
    return false;
  }

  void open() {
    if (!isOpen) _update(() => isOpen = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !isOpen) return;
      fieldFocus.requestFocus();
      query.selection = TextSelection(baseOffset: 0, extentOffset: query.text.length);
      _rescan(reveal: true);
    });
  }

  void close() {
    if (!isOpen) return;
    _update(() {
      isOpen = false;
      _matches = const [];
      _current = -1;
    });
  }

  void _onQueryChanged() {
    if (query.text == _lastQuery) return;
    _lastQuery = query.text;
    _rescan(reveal: true, fromStart: true);
  }

  /// The next match, or the previous one for a negative [delta]. Looks again
  /// first, because the page may have changed since the last look.
  void step(int delta) {
    _rescan(reveal: false);
    if (_matches.isEmpty) return;
    _update(() => _current = (_current + delta) % _matches.length);
    _reveal(_matches[_current]);
  }

  void _rescan({required bool reveal, bool fromStart = false}) {
    if (!mounted) return;
    final text = query.text.trim();
    final found = !isOpen || text.isEmpty ? <_Match>[] : _collect(text);

    var current = found.isEmpty ? -1 : 0;
    if (!fromStart && _current >= 0 && _current < _matches.length) {
      final before = _matches[_current];
      final same = found.indexWhere((match) => match.sameAs(before));
      if (same >= 0) current = same;
    }
    _update(() {
      _matches = found;
      _current = current;
    });
    if (reveal && current >= 0) _reveal(found[current]);
  }

  void _reveal(_Match match) {
    if (!match.element.mounted) return;
    Scrollable.ensureVisible(match.element, alignment: 0.3);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _repaint.tick();
    });
  }

  /// Walks the page's widgets for text that contains [text]. Text inside a
  /// hidden widget, or on a tab or page that is not showing, is left out.
  List<_Match> _collect(String text) {
    final root = _contentKey.currentContext;
    final area = _paintKey.currentContext?.findRenderObject();
    if (root is! Element || area is! RenderBox || !area.hasSize) return const [];
    final origin = area.localToGlobal(Offset.zero);
    final width = area.size.width;
    final found = <_Match>[];

    void visit(Element element) {
      if (element is RenderObjectElement) {
        final object = element.renderObject;
        if (object is RenderOffstage && object.offstage) return;
        if (object is RenderParagraph && object.attached && object.hasSize) {
          final plain = object.text.toPlainText();
          for (final start in matchOffsets(plain, text)) {
            final selection = TextSelection(baseOffset: start, extentOffset: start + text.length);
            final rects = _globalRects(object, selection);
            if (rects.isEmpty) continue;
            final first = rects.first.shift(-origin);
            if (first.right <= 0 || first.left >= width) continue;
            if (!_inHorizontalView(object, rects.first)) continue;
            found.add(_Match(element, object, start, start + text.length, first.topLeft));
          }
        }
      }
      element.visitChildren(visit);
    }

    visit(root);
    found.sort((a, b) {
      final down = a.anchor.dy - b.anchor.dy;
      if (down.abs() > 1) return down.sign.toInt();
      return (a.anchor.dx - b.anchor.dx).sign.toInt();
    });
    return found;
  }

  /// The match's boxes on screen, one per line it covers, cut to the text's
  /// own bounds so an ellipsis never shows a highlight past it.
  List<Rect> _globalRects(RenderParagraph paragraph, TextSelection selection) {
    if (selection.end > paragraph.text.toPlainText().length) return const [];
    final bounds = Offset.zero & paragraph.size;
    final transform = paragraph.getTransformTo(null);
    final rects = <Rect>[];
    for (final box in paragraph.getBoxesForSelection(selection)) {
      final local = box.toRect().intersect(bounds);
      if (local.width <= 0 || local.height <= 0) continue;
      rects.add(MatrixUtils.transformRect(transform, local));
    }
    return rects;
  }

  /// False when a sideways scroller, such as a tab view, has it off to one
  /// side. Up and down are fine: stepping to it scrolls it into view.
  bool _inHorizontalView(RenderObject object, Rect rect) {
    for (var node = object.parent; node != null; node = node.parent) {
      if (node is RenderViewportBase && node.axis == Axis.horizontal && node.hasSize) {
        final view = MatrixUtils.transformRect(node.getTransformTo(null), Offset.zero & node.size);
        if (rect.right <= view.left || rect.left >= view.right) return false;
      }
    }
    return true;
  }

  /// What of the match can be seen: inside every scroller around it.
  Rect _visibleArea(RenderObject object, Rect within) {
    var area = within;
    for (var node = object.parent; node != null; node = node.parent) {
      if (node is RenderViewportBase && node.hasSize) {
        area = area.intersect(MatrixUtils.transformRect(node.getTransformTo(null), Offset.zero & node.size));
      }
    }
    return area;
  }

  void _paint(Canvas canvas, Size size, AppColors colors) {
    if (!isOpen || _matches.isEmpty) return;
    final area = _paintKey.currentContext?.findRenderObject();
    if (area is! RenderBox || !area.attached) return;
    final origin = area.localToGlobal(Offset.zero);
    final whole = origin & size;
    final text = query.text.trim().toLowerCase();

    for (var i = 0; i < _matches.length; i++) {
      final match = _matches[i];
      final paragraph = match.paragraph;
      if (!paragraph.attached || !paragraph.hasSize) continue;
      final plain = paragraph.text.toPlainText();
      if (match.end > plain.length || plain.substring(match.start, match.end).toLowerCase() != text) continue;

      final visible = _visibleArea(paragraph, whole);
      if (visible.width <= 0 || visible.height <= 0) continue;

      final paint = Paint()..color = i == _current ? colors.findCurrent : colors.findMatch;
      canvas.save();
      canvas.clipRect(visible.shift(-origin));
      for (final rect in _globalRects(paragraph, match.selection)) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            rect.shift(-origin).inflate(AppSizes.findHighlightPadding),
            const Radius.circular(AppRadii.highlight),
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  bool _onScroll(ScrollNotification notification) {
    _repaint.tick();
    if (notification is ScrollEndNotification && isOpen) {
      // Rows that were not built before the scroll may hold matches now.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && isOpen) _rescan(reveal: false);
      });
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return _FindInherited(state: this, version: _version, child: widget.child);
  }
}

class _FindInherited extends InheritedWidget {
  const _FindInherited({required this.state, required this.version, required super.child});

  final FindScopeState state;
  final int version;

  @override
  bool updateShouldNotify(_FindInherited oldWidget) => version != oldWidget.version;
}

/// The part of the screen that is searched. The highlights and the find bar
/// are drawn over it; the page itself is laid out exactly as before.
class FindTarget extends StatelessWidget {
  const FindTarget({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scope = FindScope._watch(context);
    if (scope == null) return child;
    final colors = context.colors;

    return NotificationListener<ScrollNotification>(
      onNotification: scope._onScroll,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          KeyedSubtree(key: scope._contentKey, child: child),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                key: scope._paintKey,
                painter: _HighlightPainter(scope: scope, colors: colors, repaint: scope._repaint),
              ),
            ),
          ),
          if (scope.isOpen)
            Positioned(
              top: AppSpacing.sm,
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              child: Align(
                alignment: Alignment.topRight,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: AppSizes.findBarMaxWidth),
                  child: _FindBar(scope: scope),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HighlightPainter extends CustomPainter {
  _HighlightPainter({required this.scope, required this.colors, required Listenable repaint}) : super(repaint: repaint);

  final FindScopeState scope;
  final AppColors colors;

  @override
  void paint(Canvas canvas, Size size) => scope._paint(canvas, size, colors);

  @override
  bool shouldRepaint(covariant _HighlightPainter oldDelegate) => true;
}

class _FindBar extends StatelessWidget {
  const _FindBar({required this.scope});

  final FindScopeState scope;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final hasQuery = scope.query.text.trim().isNotEmpty;
    final count = scope.matchCount == 0
        ? (hasQuery ? l10n.findNoMatches : '')
        : l10n.findCount(scope.currentNumber, scope.matchCount);

    return Material(
      elevation: 3,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colors.rule),
        borderRadius: BorderRadius.circular(AppRadii.container),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.xs, AppSpacing.sm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: CallbackShortcuts(
                    bindings: {const SingleActivator(LogicalKeyboardKey.enter, shift: true): () => scope.step(-1)},
                    child: TextField(
                      key: const ValueKey('find-field'),
                      controller: scope.query,
                      focusNode: scope.fieldFocus,
                      textInputAction: TextInputAction.search,
                      // Enter steps to the next match and keeps the box
                      // focused, so Enter again moves on again.
                      onSubmitted: (_) => scope.step(1),
                      onEditingComplete: () {},
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: l10n.findHint,
                        prefixIcon: const Icon(Icons.search, size: AppSizes.iconMedium),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  count,
                  key: const ValueKey('find-count'),
                  style: text.bodySmall?.copyWith(
                    color: hasQuery && scope.matchCount == 0 ? colors.negative : colors.textMuted,
                    fontFeatures: AppFonts.tabular,
                  ),
                ),
                IconButton(
                  tooltip: l10n.findPrevious,
                  onPressed: scope.matchCount == 0 ? null : () => scope.step(-1),
                  icon: const Icon(Icons.keyboard_arrow_up, size: AppSizes.iconMedium),
                ),
                IconButton(
                  tooltip: l10n.findNext,
                  onPressed: scope.matchCount == 0 ? null : () => scope.step(1),
                  icon: const Icon(Icons.keyboard_arrow_down, size: AppSizes.iconMedium),
                ),
                IconButton(
                  key: const ValueKey('find-close'),
                  tooltip: l10n.findClose,
                  onPressed: scope.close,
                  icon: const Icon(Icons.close, size: AppSizes.iconMedium),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(l10n.findScopeNote, style: text.bodySmall?.copyWith(color: colors.textMuted)),
          ],
        ),
      ),
    );
  }
}
