import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Radii of the design (ESPECIFICACION.md §6 · Radios).
abstract final class AppRadii {
  static const input = 12.0;
  static const segmented = 12.0;
  static const segmentedTab = 9.0;
  static const button = 14.0;
  static const card = 16.0;
  static const cta = 16.0;
  static const activityCard = 20.0;
  static const sheet = 24.0;
  static const pill = 999.0;
}

/// Minimum touch target.
const double kTouchTarget = 44;

/// Horizontal padding of the mobile screens.
const double kScreenPadding = 20;

abstract final class AppTheme {
  static const fontFamily = 'Inter';

  static ThemeData light() {
    const c = WlColors.light;
    final base = ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      colorScheme: ColorScheme.fromSeed(
        seedColor: c.primary,
        primary: c.primary,
        onPrimary: Colors.white,
        surface: c.surface,
        onSurface: c.ink,
        error: c.primaryDark,
      ),
      scaffoldBackgroundColor: c.background,
      extensions: const [c],
    );

    final text = base.textTheme.apply(bodyColor: c.ink, displayColor: c.ink, fontFamily: fontFamily);

    return base.copyWith(
      textTheme: text.copyWith(
        headlineMedium: text.headlineMedium?.copyWith(fontSize: 26, fontWeight: FontWeight.w700, height: 32 / 26),
        titleLarge: text.titleLarge?.copyWith(fontSize: 20, fontWeight: FontWeight.w700),
        titleMedium: text.titleMedium?.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
        bodyLarge: text.bodyLarge?.copyWith(fontSize: 15),
        bodyMedium: text.bodyMedium?.copyWith(fontSize: 14),
        bodySmall: text.bodySmall?.copyWith(fontSize: 13, color: c.inkMuted),
        labelSmall: text.labelSmall?.copyWith(fontSize: 12),
      ),
      materialTapTargetSize: MaterialTapTargetSize.padded,
      splashFactory: InkSparkle.splashFactory,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        hintStyle: TextStyle(color: c.inkMuted, fontSize: 15),
        border: _inputBorder(c.borderInput),
        enabledBorder: _inputBorder(c.borderInput),
        focusedBorder: _inputBorder(c.primary, width: 2),
        errorBorder: _inputBorder(c.primaryDark),
        focusedErrorBorder: _inputBorder(c.primaryDark, width: 2),
        errorStyle: TextStyle(color: c.primaryDark, fontSize: 13),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? c.primary : c.surface,
        ),
        side: BorderSide(color: c.borderInput, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? c.primary : c.borderInput,
        ),
        thumbColor: const WidgetStatePropertyAll(Colors.white),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.ink,
        contentTextStyle: const TextStyle(fontFamily: fontFamily, fontSize: 14, color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.activityCard)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        modalBarrierColor: AppPalette.overlay,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.sheet))),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: c.primary),
      textSelectionTheme: TextSelectionThemeData(cursorColor: c.primary),
      dividerTheme: DividerThemeData(color: c.divider, thickness: 1, space: 1),
    );
  }

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppRadii.input),
    borderSide: BorderSide(color: color, width: width),
  );
}
