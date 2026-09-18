import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/fridge_telemetry.dart';

class FirebaseService {
  // เปลี่ยนให้เป็น getter เพื่อเรียกใช้ FirebaseFirestore.instance 
  // หลังจากที่ Firebase.initializeApp() รันเสร็จสิ้นแล้วเท่านั้น ป้องกันการพังตอนเริ่มต้นสร้างแอป
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  Future<void> logTelemetry(FridgeTelemetry telemetry) async {
    try {
      await _firestore.collection('coldchain_history').add({
        'site_id': telemetry.siteId,
        'device_id': telemetry.deviceId,
        'temperature_c': telemetry.temperature,
        'humidity_pct': telemetry.humidity,
        'status': telemetry.displayStatus,
        'alarm_active': telemetry.alarmActive,
        'alarm_muted': telemetry.alarmMuted,
        'timestamp': FieldValue.serverTimestamp(),
      });
      debugPrint('Successfully logged telemetry to Firebase for ${telemetry.deviceId} (${telemetry.siteId})');
    } catch (e) {
      debugPrint('Error logging telemetry to Firebase: $e');
    }
  }
}
