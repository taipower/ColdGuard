import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/coldchain_provider.dart';
import '../widgets/fridge_card.dart';
import 'history_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  Future<void> _confirmMute(
      BuildContext context,
      String siteId,
      String deviceId,
      ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Mute buzzer?'),
          content: Text(
            'ต้องการปิดเสียงเตือนของ $deviceId ($siteId) หรือไม่?\n\n'
                'สถานะ ALARM จะยังคงอยู่จนกว่าอุณหภูมิกลับสู่ระดับปกติ',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('CANCEL'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('MUTE'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      context.read<ColdChainProvider>().muteBuzzer(siteId, deviceId);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sent mute command to $deviceId in $siteId'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ColdChainProvider>();
    final fridges = provider.fridges;
    final sites = provider.uniqueSites;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ColdGuard Multi-Site'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            tooltip: 'View History Charts',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HistoryScreen()),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Icon(
                  provider.mqttConnected
                      ? Icons.cloud_done
                      : Icons.cloud_off,
                  color: provider.mqttConnected
                      ? Colors.greenAccent
                      : Colors.white70,
                ),
                const SizedBox(width: 6),
                Text(
                  provider.mqttConnected ? 'MQTT ON' : 'MQTT OFF',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _SummaryBar(
            normal: fridges
                .where((fridge) => fridge.displayStatus == 'NORMAL')
                .length,
            warning: fridges
                .where((fridge) => fridge.displayStatus == 'WARNING')
                .length,
            alarm: fridges
                .where(
                  (fridge) =>
              fridge.displayStatus == 'ALARM' ||
                  fridge.displayStatus == 'CRITICAL',
            )
                .length,
          ),
          Expanded(
            child: fridges.isEmpty
                ? _EmptyState(isConnecting: provider.isConnecting)
                : RefreshIndicator(
              onRefresh: provider.connect,
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 8, bottom: 24),
                itemCount: sites.length,
                itemBuilder: (context, siteIndex) {
                  final siteId = sites[siteIndex];
                  final siteFridges = provider.getFridgesBySite(siteId);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.blue, size: 20),
                            const SizedBox(width: 6),
                            Text(
                              siteId,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${siteFridges.length} devices',
                                style: const TextStyle(fontSize: 11, color: Colors.blue),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ...siteFridges.map((fridge) {
                        return FridgeCard(
                          fridge: fridge,
                          onMute: () => _confirmMute(
                            context,
                            fridge.siteId,
                            fridge.deviceId,
                          ),
                        );
                      }),
                      const SizedBox(height: 8),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: provider.mqttConnected
          ? null
          : FloatingActionButton.extended(
        onPressed: provider.isConnecting ? null : provider.connect,
        icon: provider.isConnecting
            ? const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
            : const Icon(Icons.wifi),
        label: Text(
          provider.isConnecting ? 'CONNECTING' : 'CONNECT MQTT',
        ),
      ),
    );
  }
}

class _SummaryBar extends StatelessWidget {
  const _SummaryBar({
    required this.normal,
    required this.warning,
    required this.alarm,
  });

  final int normal;
  final int warning;
  final int alarm;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _SummaryItem(
            label: 'NORMAL',
            count: normal,
            color: Colors.green,
          ),
          _SummaryItem(
            label: 'WARNING',
            count: warning,
            color: Colors.orange,
          ),
          _SummaryItem(
            label: 'ALARM',
            count: alarm,
            color: Colors.red,
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$count',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isConnecting});

  final bool isConnecting;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isConnecting)
              const CircularProgressIndicator()
            else
              const Icon(
                Icons.kitchen_outlined,
                size: 80,
                color: Colors.blueGrey,
              ),
            const SizedBox(height: 20),
            Text(
              isConnecting
                  ? 'Connecting to MQTT Broker...'
                  : 'No cold-chain devices found',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Start the Pico W simulation and wait for telemetry data.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}