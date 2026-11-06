import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// INTECHSYS ONE mark plus the "one" wordmark.
class OneLogo extends StatelessWidget {
  const OneLogo({super.key, this.large = false});

  final bool large;

  @override
  Widget build(BuildContext context) {
    final markWidth = large ? 56.0 : 30.0;
    return Semantics(
      label: 'INTECHSYS ONE',
      image: true,
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/brand/one_mark.png', width: markWidth, height: markWidth * 271 / 265),
            SizedBox(width: large ? 10 : 6),
            Text(
              'one',
              style: TextStyle(
                fontSize: large ? 50 : 27,
                fontWeight: FontWeight.w800,
                letterSpacing: (large ? 50 : 27) * -0.045,
                height: 1,
                color: context.wl.brandRed,
              ),
            ),
          ],
        ),
      ),
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
