import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// White card with the `#E2E2E1` border.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = AppRadii.card,
    this.borderColor,
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? borderColor;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.wl;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? c.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? c.borderCard),
      ),
      child: child,
    );
  }
}

/// `RESUMEN DEL DÍA`: 12, 700, primary, uppercase, letter-spacing 0.1em.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.color, this.fontSize = 12});

  final String text;
  final Color? color;
  final double fontSize;

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      letterSpacing: fontSize * 0.1,
      color: color ?? context.wl.primary,
    ),
  );
}

/// Status pill, with an optional 8 px dot.
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
    this.dot,
    this.icon,
    this.fontSize = 13,
    this.fontWeight = FontWeight.w600,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  });

  factory StatusChip.success(String label, {IconData? icon, FontWeight weight = FontWeight.w500}) => StatusChip(
    label: label,
    background: AppPalette.successBg,
    foreground: AppPalette.successFg,
    icon: icon,
    fontWeight: weight,
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  );

  factory StatusChip.warning(String label, {IconData? icon, FontWeight weight = FontWeight.w500}) => StatusChip(
    label: label,
    background: AppPalette.warningBg,
    foreground: AppPalette.warningFg,
    icon: icon,
    fontWeight: weight,
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  );

  final String label;
  final Color background;
  final Color foreground;
  final Color? dot;
  final IconData? icon;
  final double fontSize;
  final FontWeight fontWeight;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(AppRadii.pill)),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (dot != null) ...[
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
        ],
        if (icon != null) ...[Icon(icon, size: 14, color: foreground), const SizedBox(width: 6)],
        Text(
          label,
          style: TextStyle(fontSize: fontSize, fontWeight: fontWeight, color: foreground),
        ),
      ],
    ),
  );
}

/// Segmented control: `#E8E8E7` container, white active tab.
class SegmentedTabs extends StatelessWidget {
  const SegmentedTabs({super.key, required this.labels, required this.index, required this.onChanged});

  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.wl;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: c.surfaceMuted, borderRadius: BorderRadius.circular(AppRadii.segmented)),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(
              child: Semantics(
                selected: i == index,
                button: true,
                child: Material(
                  color: i == index ? c.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadii.segmentedTab),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadii.segmentedTab),
                    onTap: () => onChanged(i),
                    child: SizedBox(
                      height: 40,
                      child: Center(
                        child: Text(
                          labels[i],
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: i == index ? FontWeight.w600 : FontWeight.w500,
                            color: i == index ? c.ink : c.inkStrong,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

enum BannerTone { warning, success, neutral }

/// Inline message box (`#FEF3DA` warning, `#E6F4EC` success, `#F5F5F4` neutral).
class InfoBanner extends StatelessWidget {
  const InfoBanner({
    super.key,
    required this.child,
    this.tone = BannerTone.warning,
    this.icon = Icons.info_outline,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    this.radius = AppRadii.segmented,
  });

  final Widget child;
  final BannerTone tone;
  final IconData? icon;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final c = context.wl;
    final (bg, fg) = switch (tone) {
      BannerTone.warning => (c.warningBg, c.warningInk),
      BannerTone.success => (c.successBg, c.successFg),
      BannerTone.neutral => (c.background, c.inkStrong),
    };
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(radius)),
        child: DefaultTextStyle.merge(
          style: TextStyle(fontSize: 13, height: 18 / 13, color: fg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (icon != null) ...[Icon(icon, size: 18, color: fg), const SizedBox(width: 10)],
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

/// One line with a pin icon: `Ubicación capturada · precisión 8 m · 09:40`.
class LocationLine extends StatelessWidget {
  const LocationLine({super.key, required this.text, this.ok = true, this.busy = false});

  final String text;
  final bool ok;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final c = context.wl;
    return Row(
      children: [
        if (busy)
          SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: c.iconSubtle))
        else
          Icon(Icons.place_outlined, size: 16, color: ok ? c.successDot : c.warningDot),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: TextStyle(fontSize: 13, color: c.inkStrong)),
        ),
      ],
    );
  }
}

/// Stacked bar of time distribution.
class DistributionBar extends StatelessWidget {
  const DistributionBar({super.key, required this.parts, this.height = 14, this.semanticsLabel});

  /// (weight, color). Zero weights are skipped.
  final List<(int, Color)> parts;
  final double height;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final visible = parts.where((p) => p.$1 > 0).toList();
    return Semantics(
      label: semanticsLabel,
      image: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(height / 2),
        child: SizedBox(
          height: height,
          child: visible.isEmpty
              ? ColoredBox(color: context.wl.surfaceMuted, child: const SizedBox.expand())
              : Row(
                  children: [
                    for (var i = 0; i < visible.length; i++) ...[
                      if (i > 0) const SizedBox(width: 2),
                      Expanded(
                        flex: visible[i].$1,
                        child: ColoredBox(color: visible[i].$2, child: const SizedBox.expand()),
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

/// Legend item: 10 px square and label.
class LegendItem extends StatelessWidget {
  const LegendItem({super.key, required this.color, required this.label, this.outlined = false, this.fontSize = 12});

  final Color color;
  final String label;
  final bool outlined;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final c = context.wl;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            border: outlined ? Border.all(color: c.borderInput) : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(fontSize: fontSize, color: c.inkStrong),
        ),
      ],
    );
  }
}

/// Multi-line text field with the design style (radius 12, `#C9C9C8`).
class AppTextArea extends StatelessWidget {
  const AppTextArea({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.optional = true,
    this.errorText,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool optional;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.wl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: label,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.ink),
            children: [
              TextSpan(
                text: optional ? ' (opcional)' : ' (obligatoria)',
                style: TextStyle(fontWeight: FontWeight.w400, color: optional ? c.inkMuted : c.primaryDark),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          minLines: 3,
          maxLines: 5,
          maxLength: 1000,
          onChanged: onChanged,
          textCapitalization: TextCapitalization.sentences,
          style: TextStyle(fontSize: 15, color: c.ink),
          decoration: InputDecoration(hintText: hint, errorText: errorText, counterText: ''),
        ),
      ],
    );
  }
}

/// Centered loading or error placeholder for a whole screen body.
class StateMessage extends StatelessWidget {
  const StateMessage({super.key, required this.message, this.actionLabel, this.onAction, this.icon});

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.wl;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(kScreenPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, size: 36, color: c.iconSubtle), const SizedBox(height: 12)],
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, height: 22 / 15, color: c.inkStrong),
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: 220,
                child: OutlinedButton(
                  onPressed: onAction,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, kTouchTarget),
                    foregroundColor: c.primary,
                    side: BorderSide(color: c.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.input)),
                  ),
                  child: Text(actionLabel!, style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Shows a floating message.
void showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
