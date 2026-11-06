/// Static data of the demo: categories, activity catalog, outcomes and the work orders of the day.
library;

class MockCategory {
  const MockCategory(this.name, this.color, this.timeClass);

  final String name;
  final String color;

  /// Wire value: Productive, PaidNonProductive, Unproductive.
  final String timeClass;
}

class MockActivityType {
  const MockActivityType({
    required this.id,
    required this.name,
    required this.category,
    this.photo = false,
    this.signature = false,
    this.observationAlways = false,
  });

  final String id;
  final String name;
  final MockCategory category;
  final bool photo;
  final bool signature;
  final bool observationAlways;
}

class MockOrderSeed {
  const MockOrderSeed({
    required this.id,
    required this.number,
    required this.typeId,
    required this.site,
    required this.offsetMinutes,
  });

  final String id;
  final String number;
  final String typeId;
  final String site;

  /// Scheduled time, in minutes after the start of the shift.
  final int offsetMinutes;
}

abstract final class MockCatalog {
  static const productive = MockCategory('Productivo', '#AF1839', 'Productive');
  static const travel = MockCategory('Traslado', '#868787', 'PaidNonProductive');
  static const internal = MockCategory('Interna', '#3C3C3B', 'PaidNonProductive');
  static const unproductive = MockCategory('Improductivo', '#DA830B', 'Unproductive');

  static const categories = [productive, travel, internal, unproductive];

  static const installation = MockActivityType(
    id: '0a000000-0000-4000-8000-000000000001',
    name: 'Instalación de equipo',
    category: productive,
    photo: true,
    signature: true,
  );
  static const maintenance = MockActivityType(
    id: '0a000000-0000-4000-8000-000000000002',
    name: 'Mantenimiento preventivo',
    category: productive,
    photo: true,
  );
  static const visit = MockActivityType(
    id: '0a000000-0000-4000-8000-000000000003',
    name: 'Visita técnica',
    category: productive,
    signature: true,
  );
  static const warranty = MockActivityType(
    id: '0a000000-0000-4000-8000-000000000004',
    name: 'Revisión de garantía',
    category: productive,
  );
  static const transfer = MockActivityType(
    id: '0a000000-0000-4000-8000-000000000005',
    name: 'Traslado entre sitios',
    category: travel,
  );
  static const admin = MockActivityType(
    id: '0a000000-0000-4000-8000-000000000006',
    name: 'Labores administrativas',
    category: internal,
  );
  static const training = MockActivityType(
    id: '0a000000-0000-4000-8000-000000000007',
    name: 'Capacitación',
    category: internal,
  );
  static const waiting = MockActivityType(
    id: '0a000000-0000-4000-8000-000000000008',
    name: 'Espera de materiales',
    category: unproductive,
  );

  static const types = [installation, maintenance, visit, warranty, transfer, admin, training, waiting];

  static MockActivityType? type(String? id) {
    for (final t in types) {
      if (t.id == id) return t;
    }
    return null;
  }

  static const orders = [
    MockOrderSeed(
      id: '0b000000-0000-4000-8000-000000001042',
      number: 'OT-1042',
      typeId: '0a000000-0000-4000-8000-000000000001',
      site: 'Almacén Norte',
      offsetMinutes: 60,
    ),
    MockOrderSeed(
      id: '0b000000-0000-4000-8000-000000001043',
      number: 'OT-1043',
      typeId: '0a000000-0000-4000-8000-000000000002',
      site: 'Bodega Sur',
      offsetMinutes: 180,
    ),
    MockOrderSeed(
      id: '0b000000-0000-4000-8000-000000001047',
      number: 'OT-1047',
      typeId: '0a000000-0000-4000-8000-000000000003',
      site: 'Oficina Centro',
      offsetMinutes: 390,
    ),
  ];

  static MockOrderSeed? order(String? id) {
    for (final o in orders) {
      if (o.id == id) return o;
    }
    return null;
  }

  /// (wire, label, description, requiresObservation).
  static const outcomes = [
    ('Completed', 'Completada', 'La actividad terminó.', false),
    ('Incomplete', 'Incompleta', 'Quedó trabajo pendiente.', true),
    ('Rescheduled', 'Reprogramar', 'Se mueve a otra fecha.', true),
  ];

  static const memberId = '0c000000-0000-4000-8000-000000000001';
  static const tenantId = '0d000000-0000-4000-8000-000000000001';
  static const tenantName = 'INTECHSYS';
  static const memberName = 'Andrés Mora';
  static const branchName = 'Sede Bogotá Norte';
  static const mainSite = 'Sede Bogotá Norte';
  static const supervisor = 'Laura Gómez';
  static const deviceModel = 'Samsung Galaxy XCover7';

  static const policySummary = [
    'Ubicación solo en jornada: al iniciar, cambiar y finalizar actividades, y cada 15 minutos mientras trabajas.',
    'Horas y actividades: para calcular tu jornada, horas extra y recargos.',
    'Fotos y firma: como evidencia del trabajo realizado.',
    'Tus derechos: conocer, actualizar, rectificar y revocar la autorización (Ley 1581 de 2012).',
  ];

  static const corporateApps = ['Correo', 'Órdenes de trabajo', 'Inventario', 'Chat del equipo'];
  static const alwaysAvailableApps = ['Teléfono', 'WorkLog'];
}
