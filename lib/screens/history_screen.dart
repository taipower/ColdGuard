import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String? _selectedSite;
  String _selectedMetric = 'Temperature'; // 'Temperature' or 'Humidity'

  @override
  void initState() {
    super.initState();
    // บังคับล็อกหน้าจอเป็นแนวนอน (Landscape) เมื่อเปิดหน้านี้
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    // คืนค่าหน้าจอกลับมาเป็นแนวตั้งปกติ (หรือทุกแนว) เมื่อปิดหน้านี้ออกไป
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historical Data Charts'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('coldchain_history')
            .orderBy('timestamp', descending: true)
            .limit(100)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Text('No historical data found in Firebase yet.'),
            );
          }

          // สกัดรายการ Site ทั้งหมดที่มีในประวัติข้อมูล
          final sites = docs
              .map((doc) => doc['site_id']?.toString() ?? 'unknown-site')
              .toSet()
              .toList();
          sites.sort();

          // ถ้ายังไม่ได้เลือก Site ให้เลือกตัวแรกเป็นค่าเริ่มต้น
          if (_selectedSite == null && sites.isNotEmpty) {
            _selectedSite = sites.first;
          }

          // กรองข้อมูลเฉพาะ Site ที่เลือก และเรียงจากเก่าไปใหม่เพื่อแสดงกราฟเส้น
          final filteredDocs = docs.where((doc) {
            final sId = doc['site_id']?.toString() ?? 'unknown-site';
            return sId == _selectedSite;
          }).toList().reversed.toList();

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ส่วนควบคุม: เลือก Site และประเภทข้อมูล
                LayoutBuilder(
                  builder: (context, constraints) {
                    // หากหน้าจอแคบ ให้แสดงแยกบรรทัดกันแทนเพื่อป้องกัน Overflow
                    if (constraints.maxWidth < 360) {
                      return Column(
                        children: [
                          DropdownButtonFormField<String>(
                            value: _selectedSite,
                            decoration: const InputDecoration(
                              labelText: 'Select Site',
                              border: OutlineInputBorder(),
                            ),
                            items: sites.map((site) {
                              return DropdownMenuItem(value: site, child: Text(site));
                            }).toList(),
                            onChanged: (val) => setState(() => _selectedSite = val),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _selectedMetric,
                            decoration: const InputDecoration(
                              labelText: 'Metric',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'Temperature', child: Text('Temperature (°C)')),
                              DropdownMenuItem(value: 'Humidity', child: Text('Humidity (%)')),
                            ],
                            onChanged: (val) => setState(() => _selectedMetric = val ?? 'Temperature'),
                          ),
                        ],
                      );
                    }
                    
                    // หากหน้าจอปกติ ให้ใช้ Row พร้อมทำการลดขนาดฟอนต์หรือใช้ไอคอนสั้นลงเพื่อความกระชับ
                    return Row(
                      children: [
                        Expanded(
                          flex: 11,
                          child: DropdownButtonFormField<String>(
                            value: _selectedSite,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Select Site',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                            items: sites.map((site) {
                              return DropdownMenuItem(value: site, child: Text(site, style: const TextStyle(fontSize: 13)));
                            }).toList(),
                            onChanged: (val) => setState(() => _selectedSite = val),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 12,
                          child: DropdownButtonFormField<String>(
                            value: _selectedMetric,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Metric',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'Temperature', child: Text('Temp (°C)', style: TextStyle(fontSize: 13))),
                              DropdownMenuItem(value: 'Humidity', child: Text('Humidity (%)', style: TextStyle(fontSize: 13))),
                            ],
                            onChanged: (val) => setState(() => _selectedMetric = val ?? 'Temperature'),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),

                // ส่วนแสดงผลกราฟเส้น
                Expanded(
                  child: filteredDocs.isEmpty
                      ? const Center(child: Text('No data for this site.'))
                      : _buildChart(filteredDocs),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildChart(List<QueryDocumentSnapshot> docs) {
    final isTemp = _selectedMetric == 'Temperature';
    List<FlSpot> spots = [];

    for (int i = 0; i < docs.length; i++) {
      final doc = docs[i];
      final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      
      double? val;
      if (isTemp) {
        val = (data['temperature_c'] as num?)?.toDouble();
      } else {
        val = (data['humidity_pct'] as num?)?.toDouble();
      }

      if (val != null) {
        spots.add(FlSpot(i.toDouble(), val));
      }
    }

    if (spots.isEmpty) {
      return const Center(child: Text('No valid metric values found.'));
    }

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true, drawVerticalLine: true),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            axisNameWidget: const Text('Timeline (Newest on the right)'),
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                final int index = value.toInt();
                if (index >= 0 && index < docs.length && index % (docs.length ~/ 3 + 1) == 0) {
                  final timestamp = docs[index]['timestamp'] as Timestamp?;
                  if (timestamp != null) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        DateFormat('HH:mm').format(timestamp.toDate()),
                        style: const TextStyle(fontSize: 10, color: Colors.black54),
                      ),
                    );
                  }
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: const Color(0xff37434d), width: 1),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: isTemp ? Colors.redAccent : Colors.blueAccent,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: (isTemp ? Colors.redAccent : Colors.blueAccent).withValues(alpha: 0.15),
            ),
          ),
        ],
      ),
    );
  }
}
