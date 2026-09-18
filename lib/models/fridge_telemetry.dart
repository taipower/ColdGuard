class FridgeTelemetry {
  final String siteId;
  final String deviceId;
  final double? temperature;
  final double? humidity;
  final String status;
  final bool alarmActive;
  final bool alarmMuted;
  final bool mqttConnected;
  final DateTime receivedAt;

  const FridgeTelemetry({
    required this.siteId,
    required this.deviceId,
    required this.temperature,
    required this.humidity,
    required this.status,
    required this.alarmActive,
    required this.alarmMuted,
    required this.mqttConnected,
    required this.receivedAt,
  });

  factory FridgeTelemetry.fromJson(Map<String, dynamic> json, {String? fallbackSiteId}) {
    return FridgeTelemetry(
      siteId: json['site_id']?.toString() ?? fallbackSiteId ?? 'unknown-site',
      deviceId: json['device_id']?.toString() ?? 'unknown-device',
      temperature: (json['temperature_c'] as num?)?.toDouble(),
      humidity: (json['humidity_pct'] as num?)?.toDouble(),
      status: json['status']?.toString().toUpperCase() ?? 'UNKNOWN',
      alarmActive: json['alarm_active'] == true,
      alarmMuted: json['alarm_muted'] == true,
      mqttConnected: json['mqtt_connected'] == true,
      receivedAt: DateTime.now(),
    );
  }

  FridgeTelemetry copyWith({
    String? status,
    DateTime? receivedAt,
  }) {
    return FridgeTelemetry(
      siteId: siteId,
      deviceId: deviceId,
      temperature: temperature,
      humidity: humidity,
      status: status ?? this.status,
      alarmActive: alarmActive,
      alarmMuted: alarmMuted,
      mqttConnected: mqttConnected,
      receivedAt: receivedAt ?? this.receivedAt,
    );
  }

  bool get isOffline {
    return DateTime.now().difference(receivedAt).inSeconds > 60;
  }

  String get displayStatus {
    if (isOffline) return 'OFFLINE';
    return status;
  }
}