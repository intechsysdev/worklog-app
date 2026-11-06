import 'package:flutter/material.dart';

/// Raw palette of the design (ESPECIFICACION.md §6). Widgets read the semantic tokens of
/// [WlColors] through `context.wl`; these constants exist for the theme and for tests.
abstract final class AppPalette {
  static const primary = Color(0xFFAF1839);
  static const primaryDark = Color(0xFF751326);
  static const brandRed = Color(0xFFE51E49);
  static const pinkSoft = Color(0xFFFBE9EE);
  static const rowSelected = Color(0xFFFBF7F8);

  static const ink = Color(0xFF1E1F1D);
  static const inkStrong = Color(0xFF3C3C3B);
  static const inkMuted = Color(0xFF5A5958);
  static const iconSubtle = Color(0xFF868787);
  static const borderInput = Color(0xFFC9C9C8);
  static const borderCard = Color(0xFFE2E2E1);
  static const surfaceMuted = Color(0xFFE8E8E7);
  static const divider = Color(0xFFEFEFEE);
  static const background = Color(0xFFF5F5F4);
  static const surface = Color(0xFFFFFFFF);

  static const successBg = Color(0xFFE6F4EC);
  static const successFg = Color(0xFF1E6B3F);
  static const successDot = Color(0xFF1E7A46);

  static const warningBg = Color(0xFFFEF3DA);
  static const warningFg = Color(0xFF8A4105);
  static const warningDot = Color(0xFFDA830B);
  static const warningInk = Color(0xFF6E3504);

  static const overlay = Color(0x8C1E1F1D);
}

/// Semantic color tokens exposed as a [ThemeExtension].
@immutable
class WlColors extends ThemeExtension<WlColors> {
  const WlColors({
    required this.primary,
    required this.primaryDark,
    required this.brandRed,
    required this.pinkSoft,
    required this.ink,
    required this.inkStrong,
    required this.inkMuted,
    required this.iconSubtle,
    required this.borderInput,
    required this.borderCard,
    required this.surfaceMuted,
    required this.divider,
    required this.background,
    required this.surface,
    required this.successBg,
    required this.successFg,
    required this.successDot,
    required this.warningBg,
    required this.warningFg,
    required this.warningDot,
    required this.warningInk,
    required this.idle,
    required this.travel,
  });

  static const light = WlColors(
    primary: AppPalette.primary,
    primaryDark: AppPalette.primaryDark,
    brandRed: AppPalette.brandRed,
    pinkSoft: AppPalette.pinkSoft,
    ink: AppPalette.ink,
    inkStrong: AppPalette.inkStrong,
    inkMuted: AppPalette.inkMuted,
    iconSubtle: AppPalette.iconSubtle,
    borderInput: AppPalette.borderInput,
    borderCard: AppPalette.borderCard,
    surfaceMuted: AppPalette.surfaceMuted,
    divider: AppPalette.divider,
    background: AppPalette.background,
    surface: AppPalette.surface,
    successBg: AppPalette.successBg,
    successFg: AppPalette.successFg,
    successDot: AppPalette.successDot,
    warningBg: AppPalette.warningBg,
    warningFg: AppPalette.warningFg,
    warningDot: AppPalette.warningDot,
    warningInk: AppPalette.warningInk,
    idle: AppPalette.warningDot,
    travel: AppPalette.iconSubtle,
  );

  final Color primary;
  final Color primaryDark;
  final Color brandRed;
  final Color pinkSoft;
  final Color ink;
  final Color inkStrong;
  final Color inkMuted;
  final Color iconSubtle;
  final Color borderInput;
  final Color borderCard;
  final Color surfaceMuted;
  final Color divider;
  final Color background;
  final Color surface;
  final Color successBg;
  final Color successFg;
  final Color successDot;
  final Color warningBg;
  final Color warningFg;
  final Color warningDot;
  final Color warningInk;

  /// "Sin actividad" and unproductive time.
  final Color idle;

  /// Paid, non productive time (Traslado).
  final Color travel;

  @override
  WlColors copyWith({Color? primary}) => WlColors(
    primary: primary ?? this.primary,
    primaryDark: primaryDark,
    brandRed: brandRed,
    pinkSoft: pinkSoft,
    ink: ink,
    inkStrong: inkStrong,
    inkMuted: inkMuted,
    iconSubtle: iconSubtle,
    borderInput: borderInput,
    borderCard: borderCard,
    surfaceMuted: surfaceMuted,
    divider: divider,
    background: background,
    surface: surface,
    successBg: successBg,
    successFg: successFg,
    successDot: successDot,
    warningBg: warningBg,
    warningFg: warningFg,
    warningDot: warningDot,
    warningInk: warningInk,
    idle: idle,
    travel: travel,
  );

  @override
  WlColors lerp(ThemeExtension<WlColors>? other, double t) => this;
}

extension WlColorsContext on BuildContext {
  WlColors get wl => Theme.of(this).extension<WlColors>() ?? WlColors.light;
}

/// Parses `#RRGGBB` colors that come from the API (categories, timeline).
Color parseHexColor(String? hex, {Color fallback = AppPalette.primary}) {
  if (hex == null) return fallback;
  final clean = hex.replaceFirst('#', '');
  if (clean.length != 6) return fallback;
  final value = int.tryParse(clean, radix: 16);
  return value == null ? fallback : Color(0xFF000000 | value);
}
