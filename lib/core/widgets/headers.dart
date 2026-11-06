import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'brand.dart';

/// 44 px round avatar with initials.
class AvatarButton extends StatelessWidget {
  const AvatarButton({super.key, required this.initials, required this.onTap, this.label, this.size = 44});

  final String initials;
  final VoidCallback? onTap;
  final String? label;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.wl;
    return Semantics(
      button: onTap != null,
      label: label,
      child: Material(
        color: c.primary,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: size,
            height: size,
            child: Center(
              child: ExcludeSemantics(
                child: Text(
                  initials,
                  style: TextStyle(fontSize: size * 14 / 44, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Header of the home screens: logo lockup and avatar.
class BrandHeader extends StatelessWidget {
  const BrandHeader({super.key, required this.initials, required this.onAvatar, this.name});

  final String initials;
  final String? name;
  final VoidCallback onAvatar;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(kScreenPadding, 20, kScreenPadding, 12),
    child: Row(
      children: [
        const Expanded(
          child: Align(alignment: Alignment.centerLeft, child: BrandLockup()),
        ),
        AvatarButton(initials: initials, onTap: onAvatar, label: name == null ? 'Perfil' : 'Perfil de $name'),
      ],
    ),
  );
}

/// Header with a back button and a title (`Nueva actividad`, `Finalizar actividad`…).
class BackHeader extends StatelessWidget {
  const BackHeader({super.key, required this.title, this.onBack, this.trailing});

  final String title;
  final VoidCallback? onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.wl;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
      child: Row(
        children: [
          SizedBox(
            width: kTouchTarget,
            height: kTouchTarget,
            child: IconButton(
              tooltip: 'Volver',
              onPressed: onBack ?? () => Navigator.of(context).maybePop(),
              icon: Icon(Icons.chevron_left_rounded, size: 28, color: c.ink),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: c.ink),
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

enum NavTab { activity, history, workday }

/// Bottom navigation: Actividad · Historial · Jornada.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.current, required this.onSelect});

  /// Null when the screen is not one of the tabs (Perfil).
  final NavTab? current;
  final ValueChanged<NavTab> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.wl;
    Widget item(NavTab tab, IconData icon, String label) {
      final active = tab == current;
      final color = active ? c.primary : c.inkMuted;
      return Expanded(
        child: Semantics(
          selected: active,
          button: true,
          label: label,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => onSelect(tab),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: kTouchTarget),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: ExcludeSemantics(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 22, color: color),
                      const SizedBox(height: 4),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.borderCard)),
      ),
      padding: EdgeInsets.fromLTRB(8, 8, 8, 16 + MediaQuery.paddingOf(context).bottom * 0.5),
      child: Row(
        children: [
          item(NavTab.activity, Icons.schedule_rounded, 'Actividad'),
          item(NavTab.history, Icons.format_list_bulleted_rounded, 'Historial'),
          item(NavTab.workday, Icons.person_outline_rounded, 'Jornada'),
        ],
      ),
    );
  }
}
