import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/fridge_telemetry.dart';

class FridgeCard extends StatelessWidget {
  const FridgeCard({
    super.key,
    required this.fridge,
    required this.onMute,
  });

  final FridgeTelemetry fridge;
  final VoidCallback onMute;

  Color _statusColor(String status) {
    switch (status) {
      case 'NORMAL':
        return Colors.green;
      case 'WARNING':
        return Colors.orange;
      case 'ALARM':
      case 'CRITICAL':
        return Colors.red;
      case 'OFFLINE':
        return Colors.grey;
      default:
        return Colors.blueGrey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'NORMAL':
        return Icons.check_circle;
      case 'WARNING':
        return Icons.warning_amber_rounded;
      case 'ALARM':
      case 'CRITICAL':
        return Icons.error;
      case 'OFFLINE':
        return Icons.cloud_off;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = fridge.displayStatus;
    final color = _statusColor(status);
    final updatedTime = DateFormat('HH:mm:ss').format(fridge.receivedAt);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(_statusIcon(status), color: color, size: 30),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fridge.deviceId,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Site: ${fridge.siteId}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: _Metric(
                    icon: Icons.thermostat,
                    label: 'Temperature',
                    value: fridge.temperature == null
                        ? '-'
                        : '${fridge.temperature!.toStringAsFixed(1)} °C',
                    color: color,
                  ),
                ),
                Expanded(
                  child: _Metric(
                    icon: Icons.water_drop_outlined,
                    label: 'Humidity',
                    value: fridge.humidity == null
                        ? '-'
                        : '${fridge.humidity!.toStringAsFixed(1)} %',
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(
                  fridge.isOffline ? Icons.cloud_off : Icons.schedule,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 6),
                Text(
                  fridge.isOffline
                      ? 'No data received for over 60 seconds'
                      : 'Last updated: $updatedTime',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                if (fridge.alarmActive && !fridge.isOffline)
                  OutlinedButton.icon(
                    onPressed: onMute,
                    icon: Icon(
                      fridge.alarmMuted
                          ? Icons.volume_off
                          : Icons.volume_up,
                    ),
                    label: Text(
                      fridge.alarmMuted ? 'MUTED' : 'MUTE',
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
          ],
        ),
      ],
    );
  }
}