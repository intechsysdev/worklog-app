import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/clock/server_clock.dart';
import '../../../core/format/formatters.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/headers.dart';
import '../../../core/widgets/selectable.dart';
import '../data/models/activity_options_dto.dart';
import '../data/models/enums.dart';
import 'widgets/workday_widgets.dart';
import 'workday_commands.dart';
import 'workday_providers.dart';

/// "Nueva actividad": assigned work orders of today and the catalog.
class SelectActivityScreen extends ConsumerStatefulWidget {
  const SelectActivityScreen({super.key});

  @override
  ConsumerState<SelectActivityScreen> createState() => _SelectActivityScreenState();
}

class _SelectActivityScreenState extends ConsumerState<SelectActivityScreen> {
  final _search = TextEditingController();
  int _tab = 0;
  String? _picked;
  bool _busy = false;
  bool _tabChosen = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _matches(String query, List<String?> fields) {
    if (query.isEmpty) return true;
    final q = query.toLowerCase();
    return fields.any((f) => f != null && f.toLowerCase().contains(q));
  }

  Future<void> _start(ActivityOptionsDto options) async {
    final key = _picked;
    if (key == null) return;
    final ActivityChoice choice;
    if (key.startsWith('wo:')) {
      final order = options.assigned.firstWhere((o) => 'wo:${o.workOrderId}' == key);
      choice = ActivityChoice.assigned(order, options.catalogFor(order.activityTypeId));
    } else {
      choice = ActivityChoice.catalog(options.catalog.firstWhere((c) => 'at:${c.activityTypeId}' == key));
    }

    setState(() => _busy = true);
    try {
      final handle = await ref.read(workdayCommandsProvider).startActivity(choice);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      await reportCommand(messenger, handle);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.wl;
    final options = ref.watch(activityOptionsProvider);
    final current = ref.watch(dayViewProvider).value?.current;
    final query = _search.text.trim();

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const BackHeader(title: 'Nueva actividad'),
            Expanded(
              child: options.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => StateMessage(
                  icon: Icons.cloud_off_outlined,
                  message: ApiException.from(error).isNetwork
                      ? 'Sin conexión y sin catálogo guardado. Conéctate para descargar las actividades.'
                      : ApiException.from(error).message,
                  actionLabel: 'Reintentar',
                  onAction: () => ref.invalidate(activityOptionsProvider),
                ),
                data: (data) {
                  // Without assigned orders, open the catalog directly.
                  final tab = _tabChosen ? _tab : (data.assigned.isEmpty ? 1 : 0);
                  final assigned = data.assigned
                      .where((o) => _matches(query, [o.title, o.number, o.siteName]))
                      .toList();
                  final catalog = data.catalog.where((o) => _matches(query, [o.title, o.categoryName])).toList();

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(kScreenPadding, 4, kScreenPadding, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _search,
                          onChanged: (_) => setState(() {}),
                          textInputAction: TextInputAction.search,
                          style: TextStyle(fontSize: 15, color: c.ink),
                          decoration: InputDecoration(
                            hintText: 'Buscar actividad u orden',
                            prefixIcon: Icon(Icons.search_rounded, size: 20, color: c.inkMuted),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadii.button),
                              borderSide: BorderSide(color: c.borderInput),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadii.button),
                              borderSide: BorderSide(color: c.borderInput),
                            ),
                            constraints: const BoxConstraints(minHeight: 48),
                          ),
                        ),
                        const SizedBox(height: 14),
                        SegmentedTabs(
                          labels: const ['Asignadas hoy', 'Catálogo'],
                          index: tab,
                          onChanged: (i) => setState(() {
                            _tab = i;
                            _tabChosen = true;
                          }),
                        ),
                        const SizedBox(height: 14),
                        Expanded(
                          child: tab == 0
                              ? _OptionList(
                                  empty: query.isEmpty
                                      ? 'No tienes órdenes asignadas para hoy.'
                                      : 'Ninguna orden coincide con la búsqueda.',
                                  children: [
                                    for (final o in assigned)
                                      SelectableCard(
                                        title: o.title,
                                        meta: [
                                          o.siteName,
                                          o.number,
                                          if (o.scheduledTime != null) Fmt.timeOnly(o.scheduledTime),
                                        ].whereType<String>().join(' · '),
                                        selected: _picked == 'wo:${o.workOrderId}',
                                        onTap: () => setState(() => _picked = 'wo:${o.workOrderId}'),
                                      ),
                                  ],
                                )
                              : _OptionList(
                                  empty: query.isEmpty
                                      ? 'El catálogo está vacío.'
                                      : 'Ninguna actividad coincide con la búsqueda.',
                                  children: [
                                    for (final o in catalog)
                                      SelectableCard(
                                        title: o.title,
                                        meta: _categoryLabel(o),
                                        selected: _picked == 'at:${o.activityTypeId}',
                                        onTap: () => setState(() => _picked = 'at:${o.activityTypeId}'),
                                      ),
                                  ],
                                ),
                        ),
                        if (current != null) ...[
                          const SizedBox(height: 14),
                          AutoFinishNotice(activityName: current.name),
                        ],
                        const SizedBox(height: 14),
                        PrimaryButton(
                          label: 'Iniciar actividad',
                          icon: Icons.play_arrow_rounded,
                          loading: _busy,
                          onPressed: _picked == null ? null : () => _start(data),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _categoryLabel(CatalogOptionDto o) {
    final requirements = [if (o.requiresPhoto) 'foto', if (o.requiresSignature) 'firma'];
    return [
      o.categoryName,
      if (requirements.isNotEmpty) 'pide ${requirements.join(' y ')}',
      if (o.timeClass == TimeClass.unproductive) 'cuenta como sin actividad',
    ].join(' · ');
  }
}

class _OptionList extends StatelessWidget {
  const _OptionList({required this.children, required this.empty});

  final List<Widget> children;
  final String empty;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return Center(
        child: Text(
          empty,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: context.wl.inkMuted),
        ),
      );
    }
    return ListView.separated(
      itemCount: children.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, i) => children[i],
    );
  }
}

/// "Tienes X en curso. Al iniciar otra, se finalizará automáticamente a las 09:40."
class AutoFinishNotice extends ConsumerWidget {
  const AutoFinishNotice({super.key, required this.activityName});

  final String activityName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(serverTickerProvider).value ?? ref.read(serverClockProvider).now();
    return InfoBanner(
      child: Text.rich(
        TextSpan(
          children: [
            const TextSpan(text: 'Tienes '),
            TextSpan(
              text: activityName,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: ' en curso. Al iniciar otra, se finalizará automáticamente a las ${Fmt.time(now)}.'),
          ],
        ),
      ),
    );
  }
}
