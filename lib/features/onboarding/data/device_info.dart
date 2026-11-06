import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Model shown in the device card. Serial number and MobiControl group would come from the
/// managed app configuration, which is not read yet; Android does not expose the serial to apps.
class DeviceSummary {
  const DeviceSummary({required this.model, required this.os});

  final String model;
  final String os;
}

final deviceInfoProvider = FutureProvider<DeviceSummary>((ref) async {
  final plugin = DeviceInfoPlugin();
  try {
    if (Platform.isAndroid) {
      final info = await plugin.androidInfo;
      final brand = info.manufacturer.isEmpty ? '' : '${_capitalize(info.manufacturer)} ';
      return DeviceSummary(model: '$brand${info.model}', os: 'Android ${info.version.release}');
    }
    if (Platform.isIOS) {
      final info = await plugin.iosInfo;
      return DeviceSummary(model: info.utsname.machine, os: '${info.systemName} ${info.systemVersion}');
    }
  } on Object {
    // Fall through.
  }
  return DeviceSummary(model: 'Dispositivo', os: Platform.operatingSystem);
});

String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
