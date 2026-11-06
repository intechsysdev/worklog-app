import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

/// Permissions WorkLog needs on the device. On managed devices MobiControl grants them by policy.
enum DevicePermission {
  locationAlways('Ubicación siempre', 'Validar el sitio y registrar la jornada'),
  notifications('Notificaciones', 'Avisos de inactividad y fin de turno'),
  camera('Cámara', 'Fotos de evidencia'),
  battery('Sin optimización de batería', 'Que el sistema no cierre WorkLog');

  const DevicePermission(this.title, this.why);

  final String title;
  final String why;
}

abstract interface class DevicePermissions {
  Future<Map<DevicePermission, bool>> check();

  /// Asks the OS for the missing ones (on unmanaged devices) and checks again.
  Future<Map<DevicePermission, bool>> requestMissing();
}

class HandlerDevicePermissions implements DevicePermissions {
  @override
  Future<Map<DevicePermission, bool>> check() async => {for (final p in DevicePermission.values) p: await _granted(p)};

  @override
  Future<Map<DevicePermission, bool>> requestMissing() async {
    final current = await check();
    try {
      if (current[DevicePermission.locationAlways] != true) {
        // Android only offers "always" after "while in use" was granted.
        if (await Permission.locationWhenInUse.request().isGranted) await Permission.locationAlways.request();
      }
      if (current[DevicePermission.notifications] != true) await Permission.notification.request();
      if (current[DevicePermission.camera] != true) await Permission.camera.request();
      if (current[DevicePermission.battery] != true && Platform.isAndroid) {
        await Permission.ignoreBatteryOptimizations.request();
      }
    } on Object {
      // A permission dialog already open, or a platform without that permission.
    }
    return check();
  }

  Future<bool> _granted(DevicePermission permission) async {
    try {
      return switch (permission) {
        DevicePermission.locationAlways => await Permission.locationAlways.isGranted,
        DevicePermission.notifications => await Permission.notification.isGranted,
        DevicePermission.camera => await Permission.camera.isGranted,
        DevicePermission.battery => !Platform.isAndroid || await Permission.ignoreBatteryOptimizations.isGranted,
      };
    } on Object {
      return false;
    }
  }
}

final devicePermissionsProvider = Provider<DevicePermissions>((ref) => HandlerDevicePermissions());
