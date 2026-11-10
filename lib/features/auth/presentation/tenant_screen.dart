import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/headers.dart';
import '../../../core/widgets/selectable.dart';
import '../../profile/data/models/profile_models.dart';
import 'auth_controller.dart';

/// Company selector, shown when the user has WorkLog in more than one company.
class TenantScreen extends ConsumerStatefulWidget {
  const TenantScreen({super.key});

  @override
  ConsumerState<TenantScreen> createState() => _TenantScreenState();
}

class _TenantScreenState extends ConsumerState<TenantScreen> {
  String? _selected;
  bool _busy = false;
  String? _error;

  Future<void> _continue(List<TenantDto> tenants) async {
    final tenant = tenants.where((t) => t.tenantId == _selected).firstOrNull;
    if (tenant == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authControllerProvider.notifier).selectTenant(tenant);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.wl;
    final auth = ref.watch(authControllerProvider);
    final tenants = switch (auth) {
      SignedIn() => auth.tenants,
      PendingTenant() => auth.tenants,
      _ => const <TenantDto>[],
    };

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            BackHeader(title: 'Elige la empresa', onBack: () => ref.read(authControllerProvider.notifier).signOut()),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(kScreenPadding, 4, kScreenPadding, 16),
                children: [
                  Text(
                    'Tu usuario tiene WorkLog en varias empresas. ¿Con cuál vas a registrar tu jornada?',
                    style: TextStyle(fontSize: 15, height: 22 / 15, color: c.inkStrong),
                  ),
                  const SizedBox(height: 14),
                  for (final t in tenants) ...[
                    _TenantTile(
                      tenant: t,
                      selected: t.tenantId == _selected,
                      onTap: () => setState(() => _selected = t.tenantId),
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (_error != null) InfoBanner(icon: Icons.error_outline, child: Text(_error!)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(kScreenPadding, 0, kScreenPadding, 20),
              child: PrimaryButton(
                label: 'Continuar',
                loading: _busy,
                onPressed: _selected == null ? null : () => _continue(tenants),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TenantTile extends StatelessWidget {
  const _TenantTile({required this.tenant, required this.selected, required this.onTap});

  final TenantDto tenant;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) =>
      SelectableCard(title: tenant.name, meta: tenant.role, selected: selected, selectedBackground: true, onTap: onTap);
}
