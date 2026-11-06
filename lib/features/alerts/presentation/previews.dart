import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/common.dart';
import '../../../core/widgets/headers.dart';
import '../../kiosk/presentation/kiosk_view.dart';
import '../../workday/presentation/workday_providers.dart';
import 'shift_end_notice.dart';

/// Kiosk with the data of today, to check it from the profile (development) on a device that
/// has no app control.
class KioskPreviewScreen extends ConsumerWidget {
  const KioskPreviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final day = ref.watch(dayViewProvider).value;
    if (day == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return KioskView(day: day);
  }
}

/// Shift end notice as a page, to review its texts without waiting for the end of the shift.
class ShiftEndPreviewScreen extends StatefulWidget {
  const ShiftEndPreviewScreen({super.key});

  @override
  State<ShiftEndPreviewScreen> createState() => _ShiftEndPreviewScreenState();
}

class _ShiftEndPreviewScreenState extends State<ShiftEndPreviewScreen> {
  int _minutes = 15;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: ListView(
        children: [
          const BackHeader(title: 'Aviso de fin de turno'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SegmentedTabs(
              labels: const ['15 min', '5 min', 'Cierre'],
              index: switch (_minutes) {
                15 => 0,
                5 => 1,
                _ => 2,
              },
              onChanged: (i) => setState(() => _minutes = const [15, 5, 0][i]),
            ),
          ),
          const SizedBox(height: 12),
          ShiftEndNoticeSheet(minutes: _minutes, embedded: true),
        ],
      ),
    ),
  );
}
