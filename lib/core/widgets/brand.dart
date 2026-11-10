import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Official INTECHSYS ONE artwork (from one-front/public/marca), with its dark-background version:
/// the stacked mark with "one" when [large] (sign-in), the horizontal logo otherwise (headers).
class OneLogo extends StatelessWidget {
  const OneLogo({super.key, this.large = false});

  final bool large;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final asset = large
        ? (dark ? 'assets/brand/one_marca_oscuro.png' : 'assets/brand/one_marca.png')
        : (dark ? 'assets/brand/one_logo_oscuro.png' : 'assets/brand/one_logo.png');
    return Image.asset(
      asset,
      height: large ? 104 : 28,
      semanticLabel: 'INTECHSYS ONE',
    );
  }
}

/// Header lockup: logo, separator and "WorkLog / Bitácora de actividades".
class BrandLockup extends StatelessWidget {
  const BrandLockup({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.wl;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const OneLogo(),
        const SizedBox(width: 12),
        Container(width: 1, height: 28, color: c.borderCard),
        const SizedBox(width: 12),
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'WorkLog',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c.ink),
              ),
              const SizedBox(height: 1),
              Text(
                'Bitácora de actividades',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: c.inkMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
