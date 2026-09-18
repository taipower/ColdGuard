import 'dart:async';

import 'package:flutter/material.dart';

import '../models/fridge_telemetry.dart';
import '../services/mqtt_service.dart';
import '../services/firebase_service.dart';

class ColdChainProvider extends ChangeNotifier {
  ColdChainProvider() {
    _mqttService = MqttService(
      onTelemetry: _handleTelemetry,
      onConnectionChanged: _handleConnectionChanged,
    );

    // ทำให้ UI ตรวจ OFFLINE ทุก 10 วินาที แม้ไม่มี message ใหม่
    _offlineCheckTimer = Timer.periodic(
      const Duration(seconds: 10),
          (_) => notifyListeners(),
    );

    // ตั้งเวลาให้นำข้อมูลของทุกตู้แช่ขึ้น Firebase ทุกๆ 1 นาที (60 วินาที)
    _firebaseLogTimer = Timer.periodic(
      const Duration(minutes: 1),
          (_) => _logAllFridgesToFirebase(),
    );
  }

  late final MqttService _mqttService;
  late final Timer _offlineCheckTimer;
  late final Timer _firebaseLogTimer;
  final FirebaseService _firebaseService = FirebaseService();

  final Map<String, FridgeTelemetry> _fridges = {};

  bool _mqttConnected = false;
  bool _isConnecting = false;

  bool get mqttConnected => _mqttConnected;
  bool get isConnecting => _isConnecting;

  // คืนค่ารายการตู้แช่ทั้งหมดที่ถูกเรียงลำดับความสำคัญแล้ว
  List<FridgeTelemetry> get fridges {
    final result = _fridges.values.toList();
    _sortFridges(result);
    return result;
  }

  // คืนค่ารายการ Site ทั้งหมดที่มี
  List<String> get uniqueSites {
    final sites = _fridges.values.map((f) => f.siteId).toSet().toList();
    sites.sort();
    return sites;
  }

  // ดึงรายการตู้แช่แยกตาม Site
  List<FridgeTelemetry> getFridgesBySite(String siteId) {
    final result = _fridges.values.where((f) => f.siteId == siteId).toList();
    _sortFridges(result);
    return result;
  }

  void _sortFridges(List<FridgeTelemetry> list) {
    list.sort((a, b) {
      const priority = {
        'ALARM': 1,
        'CRITICAL': 1,
        'WARNING': 2,
        'NORMAL': 3,
        'OFFLINE': 4,
      };

      final aPriority = priority[a.displayStatus] ?? 5;
      final bPriority = priority[b.displayStatus] ?? 5;

      return aPriority.compareTo(bPriority);
    });
  }

  Future<void> connect() async {
    if (_isConnecting || _mqttConnected) return;

    _isConnecting = true;
    notifyListeners();

    await _mqttService.connect();

    _isConnecting = false;
    notifyListeners();
  }

  void _handleConnectionChanged(bool connected) {
    _mqttConnected = connected;
    notifyListeners();
  }

  void _handleTelemetry(Map<String, dynamic> data, String topicSiteId) {
    final telemetry = FridgeTelemetry.fromJson(data, fallbackSiteId: topicSiteId);
    // ใช้ combination ของ siteId และ deviceId เป็นคีย์ เพื่อป้องกันกรณีต่าง site แต่ id ซ้ำกัน
    final uniqueKey = '${telemetry.siteId}_${telemetry.deviceId}';
    _fridges[uniqueKey] = telemetry;
    notifyListeners();
  }

  void _logAllFridgesToFirebase() {
    if (_fridges.isEmpty) return;
    
    debugPrint('--- Starting scheduled 1-minute Firebase log for all devices ---');
    for (final telemetry in _fridges.values) {
      _firebaseService.logTelemetry(telemetry);
    }
  }

  void muteBuzzer(String siteId, String deviceId) {
    _mqttService.publishCommand(siteId, deviceId, 'MUTE');
  }

  void unmuteBuzzer(String siteId, String deviceId) {
    _mqttService.publishCommand(siteId, deviceId, 'UNMUTE');
  }

  @override
  void dispose() {
    _offlineCheckTimer.cancel();
    _firebaseLogTimer.cancel();
    _mqttService.disconnect();
    super.dispose();
  }
}