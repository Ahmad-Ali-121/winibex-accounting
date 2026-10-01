// Winibex Accounting: single source of truth for colours, type, spacing,
// radii and component themes.
//
// Rules:
// - Feature code never declares a Color, font size, padding or radius.
//   It reads from AppColors (via context.colors), AppSpacing, AppRadii,
//   AppText, or Theme.of(context).
// - Light and dark are designed separately from the same token names.
// - To rebrand, change the palette constants below. Nothing else.
//
// Status: Confirmed. Onest typeface, Graphite and petrol palette.

import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Palette. Raw values. Only this section changes on a rebrand.
// ---------------------------------------------------------------------------

abstract final class _Palette {
  // Graphite and petrol. Near-monochrome, one petrol accent, red ink for
  // negatives by accounting convention.

  // Light
  static const paper = Color(0xFFF4F5F5);        // page background
  static const paperRaised = Color(0xFFFFFFFF);  // tables, forms, dialogs
  static const paperSunken = Color(0xFFECEEEF);  // table header, input fill
  static const graphite = Color(0xFF1D2124);     // primary text
  static const graphiteMuted = Color(0xFF62696E);// secondary text
  static const rule = Color(0xFFDADDDE);         // ledger lines, borders
  static const ruleStrong = Color(0xFFBFC4C6);

  static const petrol = Color(0xFF0E5A6B);       // accent, primary actions, money in
  static const petrolSoft = Color(0xFFDCEDF0);
  static const redInk = Color(0xFFA6322B);       // negatives, errors
  static const redInkSoft = Color(0xFFF6E1DF);
  static const amber = Color(0xFF8A5A00);        // pending, warnings
  static const amberSoft = Color(0xFFF7EBD3);
  static const stone = Color(0xFF737A80);        // reversed, cancelled
  static const stoneSoft = Color(0xFFE7E9EA);

  // Dark
  static const nightPaper = Color(0xFF121415);
  static const nightRaised = Color(0xFF1A1D1F);
  static const nightSunken = Color(0xFF222628);
  static const nightGraphite = Color(0xFFE7EAEB);
  static const nightGraphiteMuted = Color(0xFF9BA3A7);
  static const nightRule = Color(0xFF2C3134);
  static const nightRuleStrong = Color(0xFF3B4246);

  static const nightPetrol = Color(0xFF6FC1D3);
  static const nightPetrolSoft = Color(0xFF17343B);
  static const nightRed = Color(0xFFF08A80);
  static const nightRedSoft = Color(0xFF3D2220);
  static const nightAmber = Color(0xFFE5B65A);
  static const nightAmberSoft = Color(0xFF3A2F17);
  static const nightStone = Color(0xFFA0A7AB);
  static const nightStoneSoft = Color(0xFF262A2C);
}

// ---------------------------------------------------------------------------
// Semantic colours. What feature code actually uses.
// ---------------------------------------------------------------------------

@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.background,
    required this.surface,
    required this.surfaceSunken,
    required this.text,
    required this.textMuted,
    required this.rule,
    required this.ruleStrong,
    required this.accent,
    required this.accentSoft,
    required this.moneyIn,
    required this.moneyOut,
    required this.negative,
    required this.negativeSoft,
    required this.pending,
    required this.pendingSoft,
    required this.info,
    required this.infoSoft,
    required this.reversed,
    required this.reversedSoft,
  });

  final Color background;
  final Color surface;
  final Color surfaceSunken;
  final Color text;
  final Color textMuted;
  final Color rule;
  final Color ruleStrong;
  final Color accent;
  final Color accentSoft;
  final Color moneyIn;      // debit to cash, income received
  final Color moneyOut;     // credit to cash, spending
  final Color negative;     // negative balances, errors
  final Color negativeSoft;
  final Color pending;      // draft, pending approval, warnings
  final Color pendingSoft;
  final Color info;         // links, informational flags
  final Color infoSoft;
  final Color reversed;     // reversed and cancelled entries
  final Color reversedSoft;

  static const light = AppColors(
    background: _Palette.paper,
    surface: _Palette.paperRaised,
    surfaceSunken: _Palette.paperSunken,
    text: _Palette.graphite,
    textMuted: _Palette.graphiteMuted,
    rule: _Palette.rule,
    ruleStrong: _Palette.ruleStrong,
    accent: _Palette.petrol,
    accentSoft: _Palette.petrolSoft,
    moneyIn: _Palette.petrol,
    moneyOut: _Palette.graphite,
    negative: _Palette.redInk,
    negativeSoft: _Palette.redInkSoft,
    pending: _Palette.amber,
    pendingSoft: _Palette.amberSoft,
    info: _Palette.petrol,
    infoSoft: _Palette.petrolSoft,
    reversed: _Palette.stone,
    reversedSoft: _Palette.stoneSoft,
  );

  static const dark = AppColors(
    background: _Palette.nightPaper,
    surface: _Palette.nightRaised,
    surfaceSunken: _Palette.nightSunken,
    text: _Palette.nightGraphite,
    textMuted: _Palette.nightGraphiteMuted,
    rule: _Palette.nightRule,
    ruleStrong: _Palette.nightRuleStrong,
    accent: _Palette.nightPetrol,
    accentSoft: _Palette.nightPetrolSoft,
    moneyIn: _Palette.nightPetrol,
    moneyOut: _Palette.nightGraphite,
    negative: _Palette.nightRed,
    negativeSoft: _Palette.nightRedSoft,
    pending: _Palette.nightAmber,
    pendingSoft: _Palette.nightAmberSoft,
    info: _Palette.nightPetrol,
    infoSoft: _Palette.nightPetrolSoft,
    reversed: _Palette.nightStone,
    reversedSoft: _Palette.nightStoneSoft,
  );

  @override
  AppColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceSunken,
    Color? text,
    Color? textMuted,
    Color? rule,
    Color? ruleStrong,
    Color? accent,
    Color? accentSoft,
    Color? moneyIn,
    Color? moneyOut,
    Color? negative,
    Color? negativeSoft,
    Color? pending,
    Color? pendingSoft,
    Color? info,
    Color? infoSoft,
    Color? reversed,
    Color? reversedSoft,
  }) {
    return AppColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceSunken: surfaceSunken ?? this.surfaceSunken,
      text: text ?? this.text,
      textMuted: textMuted ?? this.textMuted,
      rule: rule ?? this.rule,
      ruleStrong: ruleStrong ?? this.ruleStrong,
      accent: accent ?? this.accent,
      accentSoft: accentSoft ?? this.accentSoft,
      moneyIn: moneyIn ?? this.moneyIn,
      moneyOut: moneyOut ?? this.moneyOut,
      negative: negative ?? this.negative,
      negativeSoft: negativeSoft ?? this.negativeSoft,
      pending: pending ?? this.pending,
      pendingSoft: pendingSoft ?? this.pendingSoft,
      info: info ?? this.info,
      infoSoft: infoSoft ?? this.infoSoft,
      reversed: reversed ?? this.reversed,
      reversedSoft: reversedSoft ?? this.reversedSoft,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      background: l(background, other.background),
      surface: l(surface, other.surface),
      surfaceSunken: l(surfaceSunken, other.surfaceSunken),
      text: l(text, other.text),
      textMuted: l(textMuted, other.textMuted),
      rule: l(rule, other.rule),
      ruleStrong: l(ruleStrong, other.ruleStrong),
      accent: l(accent, other.accent),
      accentSoft: l(accentSoft, other.accentSoft),
      moneyIn: l(moneyIn, other.moneyIn),
      moneyOut: l(moneyOut, other.moneyOut),
      negative: l(negative, other.negative),
      negativeSoft: l(negativeSoft, other.negativeSoft),
      pending: l(pending, other.pending),
      pendingSoft: l(pendingSoft, other.pendingSoft),
      info: l(info, other.info),
      infoSoft: l(infoSoft, other.infoSoft),
      reversed: l(reversed, other.reversed),
      reversedSoft: l(reversedSoft, other.reversedSoft),
    );
  }
}

extension AppColorsContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}

// ---------------------------------------------------------------------------
// Spacing, radii, sizes.
// ---------------------------------------------------------------------------

abstract final class AppSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
}

/// Radius follows hierarchy. Small controls are tight, containers softer.
/// Tables have no radius: they are ruled, like a ledger.
abstract final class AppRadii {
  static const double none = 0;
  static const double control = 6;   // inputs, buttons, chips
  static const double container = 10; // dialogs, sheets, menus
}

abstract final class AppSizes {
  static const double rowComfortable = 48;
  static const double rowCompact = 36;
  static const double controlHeight = 40;
  static const double navRailWidth = 232;
  static const double contentMaxWidth = 1280;
  static const double formMaxWidth = 640;
}

// ---------------------------------------------------------------------------
// Typography. One family, tabular figures wherever numbers appear.
// Font files are bundled as assets, not fetched at runtime, so the app works
// under the COEP header and loads without a network round trip.
// ---------------------------------------------------------------------------

/// Onest's default digits are proportional, so every number MUST use
/// AppText.amount or AppFonts.tabular. Otherwise columns will not align.
abstract final class AppFonts {
  static const family = 'Onest';
  static const List<FontFeature> tabular = [FontFeature.tabularFigures()];
}

abstract final class AppText {
  static TextTheme _base(Color body, Color muted) {
    const f = AppFonts.family;
    return TextTheme(
      displaySmall: const TextStyle(fontFamily: f, fontSize: 32, height: 1.2, fontWeight: FontWeight.w600, letterSpacing: -0.4),
      headlineMedium: const TextStyle(fontFamily: f, fontSize: 24, height: 1.25, fontWeight: FontWeight.w600, letterSpacing: -0.2),
      headlineSmall: const TextStyle(fontFamily: f, fontSize: 20, height: 1.3, fontWeight: FontWeight.w600),
      titleMedium: const TextStyle(fontFamily: f, fontSize: 16, height: 1.4, fontWeight: FontWeight.w600),
      titleSmall: const TextStyle(fontFamily: f, fontSize: 14, height: 1.4, fontWeight: FontWeight.w600),
      bodyLarge: const TextStyle(fontFamily: f, fontSize: 15, height: 1.5),
      bodyMedium: const TextStyle(fontFamily: f, fontSize: 14, height: 1.45),
      bodySmall: TextStyle(fontFamily: f, fontSize: 12.5, height: 1.4, color: muted),
      labelLarge: const TextStyle(fontFamily: f, fontSize: 14, height: 1.2, fontWeight: FontWeight.w500),
      labelMedium: const TextStyle(fontFamily: f, fontSize: 13, height: 1.2, fontWeight: FontWeight.w500),
      labelSmall: TextStyle(fontFamily: f, fontSize: 12, height: 1.2, fontWeight: FontWeight.w500, color: muted),
    ).apply(bodyColor: body, displayColor: body);
  }

  /// Any amount, in tables, forms, dashboards. Always tabular.
  static TextStyle amount(BuildContext context, {double size = 14, FontWeight weight = FontWeight.w500}) {
    return TextStyle(
      fontFamily: AppFonts.family,
      fontSize: size,
      fontWeight: weight,
      fontFeatures: AppFonts.tabular,
      color: context.colors.text,
    );
  }

  /// Large figures on the dashboard: cash, runway.
  static TextStyle figure(BuildContext context) =>
      amount(context, size: 28, weight: FontWeight.w600).copyWith(letterSpacing: -0.3);
}

// ---------------------------------------------------------------------------
// ThemeData builders.
// ---------------------------------------------------------------------------

abstract final class AppTheme {
  static ThemeData get light => _build(Brightness.light, AppColors.light);
  static ThemeData get dark => _build(Brightness.dark, AppColors.dark);

  static ThemeData _build(Brightness brightness, AppColors c) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: c.accent,
      onPrimary: brightness == Brightness.light ? Colors.white : c.background,
      primaryContainer: c.accentSoft,
      onPrimaryContainer: c.text,
      secondary: c.info,
      onSecondary: brightness == Brightness.light ? Colors.white : c.background,
      error: c.negative,
      onError: brightness == Brightness.light ? Colors.white : c.background,
      errorContainer: c.negativeSoft,
      onErrorContainer: c.text,
      surface: c.surface,
      onSurface: c.text,
      onSurfaceVariant: c.textMuted,
      surfaceContainerLowest: c.surface,
      surfaceContainerLow: c.background,
      surfaceContainer: c.surfaceSunken,
      outline: c.ruleStrong,
      outlineVariant: c.rule,
    );

    final text = AppText._base(c.text, c.textMuted);

    final controlShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.control),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: AppFonts.family,
      textTheme: text,
      scaffoldBackgroundColor: c.background,
      visualDensity: VisualDensity.standard,
      extensions: [c],

      dividerTheme: DividerThemeData(color: c.rule, thickness: 1, space: 1),

      tooltipTheme: TooltipThemeData(
        waitDuration: const Duration(milliseconds: 400),
        showDuration: const Duration(seconds: 6),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: c.text,
          borderRadius: BorderRadius.circular(AppRadii.control),
        ),
        textStyle: text.bodySmall?.copyWith(color: c.surface, height: 1.45),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.control),
          borderSide: BorderSide(color: c.ruleStrong),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.control),
          borderSide: BorderSide(color: c.ruleStrong),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.control),
          borderSide: BorderSide(color: c.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.control),
          borderSide: BorderSide(color: c.negative),
        ),
        labelStyle: text.bodyMedium?.copyWith(color: c.textMuted),
        helperStyle: text.bodySmall,
        errorStyle: text.bodySmall?.copyWith(color: c.negative),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, AppSizes.controlHeight),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          shape: controlShape,
          textStyle: text.labelLarge,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, AppSizes.controlHeight),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          shape: controlShape,
          side: BorderSide(color: c.ruleStrong),
          foregroundColor: c.text,
          textStyle: text.labelLarge,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: controlShape,
          foregroundColor: c.info,
          textStyle: text.labelLarge,
        ),
      ),
    );
  }
}
