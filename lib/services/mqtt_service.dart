import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttService {
  MqttService({
    required this.onTelemetry,
    required this.onConnectionChanged,
  });

  static const String broker = 'broker.emqx.io';
  static const int port = 1883;

  final void Function(Map<String, dynamic> data, String topicSiteId) onTelemetry;
  final void Function(bool connected) onConnectionChanged;

  late final MqttServerClient _client;
  StreamSubscription<List<MqttReceivedMessage<MqttMessage>>>? _subscription;

  bool get isConnected =>
      _client.connectionStatus?.state == MqttConnectionState.connected;

  Future<void> connect() async {
    final String myClientId = 'flutter_taipower_${DateTime.now().millisecondsSinceEpoch}';

    _client = MqttServerClient(broker, myClientId);
    _client.port = 1883;
    _client.logging(on: true);
    _client.keepAlivePeriod = 20;

    final connMess = MqttConnectMessage()
        .withClientIdentifier(myClientId)
        .startClean();
    _client.connectionMessage = connMess;

    try {
      await _client.connect();

      if (!isConnected) {
        _client.disconnect();
        onConnectionChanged(false);
        return;
      }

      _subscribeTopics(); // เรียกใช้ได้เลย
      _listenMessages();
      onConnectionChanged(true);
    } catch (error) {
      debugPrint('MQTT connect error: $error');
      _client.disconnect();
      onConnectionChanged(false);
    }
  }

  void _subscribeTopics() {
    // ใช้ '#' เพื่อรับทุก Topic ที่อยู่ภายใต้ coldchain1/ 
    // จะช่วยให้รองรับโครงสร้าง Topic ที่อาจจะส่งมาจำนวนชั้นไม่เท่ากันได้ (เช่น มีหรือไม่มี deviceId ใน topic)
    _client.subscribe('coldchain1/#', MqttQos.atLeastOnce);

    debugPrint('Subscribed to coldchain1/# (All sites and topics)');
  }

  void _listenMessages() {
    _subscription?.cancel();

    _subscription = _client.updates?.listen((events) {
      final received = events.first;
      final publishMessage = received.payload as MqttPublishMessage;

      final payload = MqttPublishPayload.bytesToStringAsString(
        publishMessage.payload.message,
      );

      // พิมพ์ Log เพื่อให้ตรวจสอบได้ง่ายในหน้าต่าง Run ของ Android Studio
      debugPrint('MQTT Received -> Topic: ${received.topic} | Payload: $payload');

      // ดึง siteId จาก topic (เช่น coldchain1/site-bkk-01/... -> parts[1] == 'site-bkk-01')
      String topicSiteId = 'unknown-site';
      final topicParts = received.topic.split('/');
      if (topicParts.length >= 2) {
        topicSiteId = topicParts[1];
      }

      // กรองเฉพาะ topic ที่เป็น telemetry หรือ alert
      if (received.topic.contains('/telemetry') || received.topic.contains('/alert')) {
        try {
          final data = jsonDecode(payload);
          if (data is Map<String, dynamic> && data.containsKey('device_id')) {
            onTelemetry(data, topicSiteId);
          }
        } catch (error) {
          debugPrint('Invalid MQTT JSON payload: $error');
        }
      }
    });
  }

  // ปรับให้รองรับการส่งคำสั่งข้าม Site และเข้ากับโค้ดของบอร์ด Pico W
  void publishCommand(String siteId, String deviceId, String command) {
    if (!isConnected) return;

    final builder = MqttClientPayloadBuilder();
    // ถ้าฝั่งบอร์ดตรวจสอบคำสั่งด้วยคำว่า "mute_buzzer" และ "unmute_buzzer"
    // เราจะปรับส่งข้อความให้แมตช์ตามเงื่อนไขของบอร์ด
    final finalCommand = command == 'MUTE' ? 'mute_buzzer' : 'unmute_buzzer';
    builder.addString(finalCommand);

    _client.publishMessage(
      'coldchain1/$siteId/$deviceId/command',
      MqttQos.atLeastOnce,
      builder.payload!,
    );
  }

  void disconnect() {
    _subscription?.cancel();
    _client.disconnect();
  }
}