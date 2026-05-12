import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/alert_service.dart';
import '../../services/location_service.dart';
import '../../theme/app_theme.dart';

class IncomingAlertsScreen extends StatelessWidget {
  const IncomingAlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Incoming Alerts',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Active SOS from people who added you to their circle',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: colors.outline)),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: AlertService().incomingAlerts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_none,
                            size: 64, color: colors.outline),
                        const SizedBox(height: 12),
                        Text('No active alerts',
                            style: TextStyle(color: colors.outline)),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    final ts = (data['timestamp'] as Timestamp?)?.toDate();
                    final lat = data['latitude'] as double?;
                    final lng = data['longitude'] as double?;
                    final senderName = data['senderName'] ?? 'Unknown';
                    final senderPhone = data['senderPhone'] ?? '';

                    return Card(
                      color: AppTheme.primaryRed.withOpacity(0.08),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(
                            color: AppTheme.primaryRed, width: 1.5),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded,
                                    color: AppTheme.primaryRed, size: 20),
                                const SizedBox(width: 6),
                                Text('🚨 SOS from $senderName',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryRed,
                                        fontSize: 16)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (ts != null)
                              Text(
                                  'Triggered: ${ts.day}/${ts.month}/${ts.year} ${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}',
                                  style: const TextStyle(fontSize: 12)),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                if (senderPhone.isNotEmpty)
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () async {
                                        final uri =
                                            Uri.parse('tel:$senderPhone');
                                        if (await canLaunchUrl(uri)) {
                                          await launchUrl(uri);
                                        }
                                      },
                                      icon: const Icon(Icons.phone, size: 16),
                                      label: Text(senderPhone),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppTheme.primaryRed,
                                        side: const BorderSide(
                                            color: AppTheme.primaryRed),
                                      ),
                                    ),
                                  ),
                                if (senderPhone.isNotEmpty && lat != null)
                                  const SizedBox(width: 8),
                                if (lat != null && lng != null)
                                  Expanded(
                                    child: FilledButton.icon(
                                      onPressed: () async {
                                        final url = Uri.parse(
                                            LocationService.mapsLink(lat, lng));
                                        if (await canLaunchUrl(url)) {
                                          await launchUrl(url,
                                              mode: LaunchMode
                                                  .externalApplication);
                                        }
                                      },
                                      icon: const Icon(Icons.directions,
                                          size: 16),
                                      label: const Text('Navigate'),
                                      style: FilledButton.styleFrom(
                                          backgroundColor: AppTheme.primaryRed),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}