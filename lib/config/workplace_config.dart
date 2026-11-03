class WorkplaceConfig {
  const WorkplaceConfig._();

  static const String name = 'SENAI - Local de trabalho';
  static const double radiusMeters = 100;

  // Preencha com as coordenadas reais do local antes de usar o aplicativo.
  static const double? latitude = null;
  static const double? longitude = null;

  static bool get isConfigured =>
      latitude != null &&
      longitude != null &&
      latitude! >= -90 &&
      latitude! <= 90 &&
      longitude! >= -180 &&
      longitude! <= 180;
}
