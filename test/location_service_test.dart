import 'package:flutter_test/flutter_test.dart';
import 'package:senai_ponto/services/location_service.dart';

void main() {
  group('AttendanceLocation', () {
    test('permite registro exatamente no limite de 100 metros', () {
      const location = AttendanceLocation(
        latitude: 0,
        longitude: 0,
        distanceMeters: 100,
      );

      expect(location.isWithinWorkplace, isTrue);
    });

    test('bloqueia registro acima de 100 metros', () {
      const location = AttendanceLocation(
        latitude: 0,
        longitude: 0,
        distanceMeters: 100.01,
      );

      expect(location.isWithinWorkplace, isFalse);
    });
  });
}
