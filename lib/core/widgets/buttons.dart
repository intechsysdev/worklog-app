import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Primary CTA: `#AF1839`, white text. Disabled uses `#5A5958` (or `#E8E8E7` with [mutedWhenDisabled]).
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.height = 56,
    this.fontSize = 17,
    this.loading = false,
    this.mutedWhenDisabled = false,
    this.radius = AppRadii.cta,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;
  final double fontSize;
  final bool loading;
  final bool mutedWhenDisabled;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final c = context.wl;
    final enabled = onPressed != null && !loading;
    final bg = enabled ? c.primary : (mutedWhenDisabled ? c.surfaceMuted : c.inkMuted);
    final fg = enabled || !mutedWhenDisabled ? Colors.white : c.inkMuted;
    return Semantics(
      button: true,
      enabled: enabled,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(radius),
          child: InkWell(
            borderRadius: BorderRadius.circular(radius),
            onTap: enabled ? onPressed : null,
            child: Center(
              child: loading
                  ? SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: fg))
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[Icon(icon, size: fontSize + 4, color: fg), const SizedBox(width: 10)],
                        Flexible(
                          child: Text(
                            label,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600, color: fg),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Secondary: white with `#C9C9C8` border.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.height = 52,
    this.fontSize = 15,
    this.foreground,
    this.borderColor,
    this.expand = true,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;
  final double fontSize;
  final Color? foreground;
  final Color? borderColor;
  final bool expand;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final c = context.wl;
    final fg = onPressed == null ? c.inkMuted : (foreground ?? c.ink);
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (loading)
          SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: fg))
        else if (icon != null)
          Icon(icon, size: fontSize + 3, color: fg),
        if (loading || icon != null) const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600, color: fg),
          ),
        ),
      ],
    );
    return SizedBox(
      height: height,
      width: expand ? double.infinity : null,
      child: Material(
        color: c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.button),
          side: BorderSide(color: borderColor ?? c.borderInput),
        ),
        child: InkWell(
          customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.button)),
          onTap: loading ? null : onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(child: content),
          ),
        ),
      ),
    );
  }
}

/// Tertiary: primary text, no background (`Cambiar actividad`, `Seguir trabajando`).
class TertiaryButton extends StatelessWidget {
  const TertiaryButton({super.key, required this.label, required this.onPressed, this.icon, this.height = 48});

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = context.wl;
    final fg = onPressed == null ? c.inkMuted : c.primary;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.button),
        onTap: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[Icon(icon, size: 18, color: fg), const SizedBox(width: 8)],
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: fg),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Inline link (`Leer la política completa`, `Solicitar ajuste`) with a 44 px target.
class LinkButton extends StatelessWidget {
  const LinkButton({super.key, required this.label, required this.onPressed, this.fontSize = 14});

  final String label;
  final VoidCallback? onPressed;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final c = context.wl;
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: kTouchTarget),
        child: Align(
          widthFactor: 1,
          alignment: Alignment.centerLeft,
          child: Text(
            label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: onPressed == null ? c.inkMuted : c.primary,
            ),
          ),
        ),
      ),
    );
  }
}
