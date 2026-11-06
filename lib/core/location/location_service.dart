import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../features/sync/data/models/sync_models.dart';

/// A GPS reading.
class LocationFix {
  const LocationFix({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.capturedAt,
  });

  final double latitude;
  final double longitude;

  /// Meters.
  final double accuracy;
  final DateTime capturedAt;

  LocationInputDto toInput() =>
      LocationInputDto(latitude: latitude, longitude: longitude, accuracy: accuracy, capturedAt: capturedAt.toUtc());
}

enum LocationAvailability { ready, serviceDisabled, denied }

/// One-shot location reads. Kept behind an interface so tests and a future native service can
/// replace it.
abstract interface class LocationService {
  Future<LocationAvailability> availability();

  /// Best effort: a fresh fix within [timeout], else the last known one, else null.
  Future<LocationFix?> current({Duration timeout = const Duration(seconds: 8)});
}

class GeolocatorLocationService implements LocationService {
  @override
  Future<LocationAvailability> availability() async {
    if (!await Geolocator.isLocationServiceEnabled()) return LocationAvailability.serviceDisabled;
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.denied || permission == LocationPermission.deniedForever
        ? LocationAvailability.denied
        : LocationAvailability.ready;
  }

  @override
  Future<LocationFix?> current({Duration timeout = const Duration(seconds: 8)}) async {
    try {
      if (await availability() != LocationAvailability.ready) return null;
      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(accuracy: LocationAccuracy.high, timeLimit: timeout),
      );
      return _toFix(position);
    } on Exception {
      try {
        final last = await Geolocator.getLastKnownPosition();
        return last == null ? null : _toFix(last);
      } on Exception {
        return null;
      }
    }
  }

  LocationFix _toFix(Position p) =>
      LocationFix(latitude: p.latitude, longitude: p.longitude, accuracy: p.accuracy, capturedAt: p.timestamp.toUtc());
}

final locationServiceProvider = Provider<LocationService>((ref) => GeolocatorLocationService());
