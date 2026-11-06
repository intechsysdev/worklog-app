import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../core/theme/app_theme.dart';
import '../features/demo/presentation/demo_widgets.dart';
import 'router.dart';

class WorkLogApp extends ConsumerWidget {
  const WorkLogApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
    title: 'WorkLog',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light(),
    locale: const Locale('es', 'CO'),
    supportedLocales: const [Locale('es', 'CO'), Locale('es')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    routerConfig: ref.watch(routerProvider),
    builder: (context, child) =>
        ref.watch(appConfigProvider).isMock ? DemoBanner(child: child ?? const SizedBox.shrink()) : child!,
  );
}
