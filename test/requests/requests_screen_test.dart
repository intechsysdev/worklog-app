import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worklog_mobile/core/theme/app_theme.dart';
import 'package:worklog_mobile/features/requests/data/request_models.dart';
import 'package:worklog_mobile/features/requests/presentation/requests_controller.dart';
import 'package:worklog_mobile/features/requests/presentation/requests_screen.dart';

final _requests = [
  RequestDto(
    id: 'r1',
    type: RequestType.recordAdjustment,
    status: RequestStatus.pending,
    title: 'Instalación de equipo · 29 oct',
    detail: 'Fin 09:40 → 09:55. Olvidé finalizar al salir del sitio.',
    submittedAt: DateTime.utc(2026, 10, 29, 15, 5),
  ),
  RequestDto(
    id: 'r2',
    type: RequestType.overtime,
    status: RequestStatus.approved,
    title: 'Viernes 23 de octubre',
    detail: '1 h 30 m · cierre de obra en Bodega Sur',
    submittedAt: DateTime.utc(2026, 10, 23, 20),
    resolverName: 'Laura Gómez',
    resolvedAt: DateTime.utc(2026, 10, 23, 22),
  ),
  RequestDto(
    id: 'r3',
    type: RequestType.shiftChange,
    status: RequestStatus.rejected,
    title: 'Sábado 7 de noviembre',
    detail: '07:00 – 11:00',
    submittedAt: DateTime.utc(2026, 10, 30, 13),
    resolverName: 'Laura Gómez',
    resolverComment: 'la sede está cerrada ese día',
  ),
];

class _FakeRequests extends RequestsController {
  final cancelled = <String>[];

  @override
  Future<List<RequestDto>> build() async => _requests;

  @override
  Future<void> cancel(String id) async {
    cancelled.add(id);
    state = AsyncData([
      for (final r in state.value!)
        r.id == id
            ? RequestDto(
                id: r.id,
                type: r.type,
                status: RequestStatus.cancelled,
                title: r.title,
                detail: r.detail,
                submittedAt: r.submittedAt,
              )
            : r,
    ]);
  }
}

void main() {
  late _FakeRequests controller;

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [requestsControllerProvider.overrideWith(() => controller = _FakeRequests())],
        child: MaterialApp(theme: AppTheme.light(), home: const RequestsScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('tabs Todas / Pendientes / Resueltas', (tester) async {
    await pump(tester);

    expect(find.text('Mis solicitudes'), findsOneWidget);
    expect(find.text('AJUSTE DE REGISTRO'), findsOneWidget);
    expect(find.text('HORAS EXTRA'), findsOneWidget);
    expect(find.text('CAMBIO DE TURNO'), findsOneWidget);
    expect(find.text('Aprobada por Laura Gómez el 23 oct'), findsOneWidget);
    expect(find.text('Rechazada: la sede está cerrada ese día'), findsOneWidget);
    expect(find.text('Nueva solicitud'), findsOneWidget);

    await tester.tap(find.text('Pendientes'));
    await tester.pump();
    expect(find.text('Instalación de equipo · 29 oct'), findsOneWidget);
    expect(find.text('Viernes 23 de octubre'), findsNothing);

    await tester.tap(find.text('Resueltas'));
    await tester.pump();
    expect(find.text('Instalación de equipo · 29 oct'), findsNothing);
    expect(find.text('Viernes 23 de octubre'), findsOneWidget);
    expect(find.text('Sábado 7 de noviembre'), findsOneWidget);
  });

  testWidgets('only pending requests can be cancelled', (tester) async {
    await pump(tester);

    expect(find.text('Cancelar solicitud'), findsOneWidget);
    await tester.tap(find.text('Cancelar solicitud'));
    await tester.pumpAndSettle();
    expect(find.text('¿Cancelar la solicitud?'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Cancelar solicitud'));
    await tester.pumpAndSettle();

    expect(controller.cancelled, ['r1']);
    expect(find.text('Cancelada'), findsOneWidget);
    expect(find.text('Cancelar solicitud'), findsNothing);
  });

  testWidgets('"Nueva solicitud" offers the three forms', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Nueva solicitud'));
    await tester.pumpAndSettle();

    expect(find.text('Ajuste de registro'), findsOneWidget);
    expect(find.text('Horas extra'), findsOneWidget);
    expect(find.text('Cambio de turno'), findsOneWidget);
  });
}
