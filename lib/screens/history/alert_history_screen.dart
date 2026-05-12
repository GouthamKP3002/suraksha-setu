import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/alert_service.dart';
import '../../services/location_service.dart';
import '../../theme/app_theme.dart';

class AlertHistoryScreen extends StatelessWidget {
  const AlertHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Alert History',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Your past SOS alerts',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: colors.outline)),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: AlertService().alertHistory(),
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
                        Icon(Icons.history, size: 64, color: colors.outline),
                        const SizedBox(height: 12),
                        Text('No alerts yet',
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
                    final resolved = data['status'] == 'resolved';
                    final lat = data['latitude'] as double?;
                    final lng = data['longitude'] as double?;

                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: resolved
                              ? Colors.green.withOpacity(0.15)
                              : AppTheme.primaryRed.withOpacity(0.15),
                          child: Icon(
                            resolved
                                ? Icons.check_circle_outline
                                : Icons.warning_amber_rounded,
                            color:
                                resolved ? AppTheme.safeGreen : AppTheme.primaryRed,
                          ),
                        ),
                        title: Text(
                          resolved ? 'Resolved' : 'Active / Sent',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: resolved
                                  ? AppTheme.safeGreen
                                  : AppTheme.primaryRed),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (ts != null)
                              Text(
                                '${ts.day}/${ts.month}/${ts.year}  ${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            if (lat != null && lng != null)
                              Text(
                                '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
                                style: TextStyle(
                                    fontSize: 11, color: colors.outline),
                              ),
                          ],
                        ),
                        trailing: lat != null && lng != null
                            ? IconButton(
                                icon: const Icon(Icons.map_outlined),
                                tooltip: 'View on map',
                                onPressed: () async {
                                  final url = Uri.parse(
                                      LocationService.mapsLink(lat, lng));
                                  if (await canLaunchUrl(url)) {
                                    await launchUrl(url,
                                        mode: LaunchMode.externalApplication);
                                  }
                                },
                              )
                            : null,
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