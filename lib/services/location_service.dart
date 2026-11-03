import 'package:geolocator/geolocator.dart';

import '../config/workplace_config.dart';

class AttendanceLocation {
  const AttendanceLocation({
    required this.latitude,
    required this.longitude,
    required this.distanceMeters,
  });

  final double latitude;
  final double longitude;
  final double distanceMeters;

  bool get isWithinWorkplace =>
      distanceMeters <= WorkplaceConfig.radiusMeters;
}

class LocationService {
  Future<AttendanceLocation> getAttendanceLocation() async {
    if (!WorkplaceConfig.isConfigured) {
      throw StateError(
        'Configure as coordenadas reais do local em '
        'lib/config/workplace_config.dart.',
      );
    }

    if (!await Geolocator.isLocationServiceEnabled()) {
      throw StateError('Ative o GPS para registrar o ponto.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw StateError(
        'A permissão de localização é necessária para registrar o ponto.',
      );
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 20),
      ),
    );
    final distance = Geolocator.distanceBetween(
      WorkplaceConfig.latitude!,
      WorkplaceConfig.longitude!,
      position.latitude,
      position.longitude,
    );

    return AttendanceLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      distanceMeters: distance,
    );
  }
}
