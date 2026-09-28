import 'package:flutter/material.dart';

import '../services/audio_service.dart';

class DataWallet extends StatelessWidget {
  final DataUsageSnapshot? snapshot;
  const DataWallet({super.key, required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final usage = snapshot;
    final String rateText = usage == null
        ? '—'
        : '${(usage.bytesPerMinute / 1024).toStringAsFixed(1)} KB/min';
    final String totalText = usage == null
        ? '—'
        : '${(usage.totalBytes / (1024)).toStringAsFixed(1)} KB total';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.data_usage_outlined),
                const SizedBox(width: 8),
                const Text('Network Usage'),
                const Spacer(),
                Text(rateText, style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: usage == null ? 0 : (usage.recentUtilization01.clamp(0.0, 1.0)),
              minHeight: 6,
            ),
            const SizedBox(height: 8),
            Text('Total: $totalText'),
          ],
        ),
      ),
    );
  }
}


