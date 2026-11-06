import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// 22 px radio ring of the selectable cards.
class RadioDot extends StatelessWidget {
  const RadioDot({super.key, required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final c = context.wl;
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: selected ? c.primary : c.iconSubtle, width: 2),
      ),
      alignment: Alignment.center,
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(shape: BoxShape.circle, color: selected ? c.primary : Colors.transparent),
      ),
    );
  }
}

/// Card with title, meta line and radio: selected = 2 px `#AF1839` border.
class SelectableCard extends StatelessWidget {
  const SelectableCard({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
    this.meta,
    this.selectedBackground = false,
  });

  final String title;
  final String? meta;
  final bool selected;
  final VoidCallback onTap;

  /// Pink background when selected (cards); the activity list keeps white.
  final bool selectedBackground;

  @override
  Widget build(BuildContext context) {
    final c = context.wl;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected && selectedBackground ? c.pinkSoft : c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.button),
          side: BorderSide(color: selected ? c.primary : c.borderCard, width: selected ? 2 : 1),
        ),
        child: InkWell(
          customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.button)),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 72),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c.ink),
                        ),
                        if (meta != null && meta!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(meta!, style: TextStyle(fontSize: 13, color: c.inkMuted)),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  RadioDot(selected: selected),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
