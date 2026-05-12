import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../services/auth_service.dart';
import '../../services/alert_service.dart';
import '../../services/shake_detector.dart';
import '../../services/location_service.dart';
import '../../theme/app_theme.dart';
import '../circle/safe_circle_screen.dart';
import '../history/alert_history_screen.dart';
import '../incoming/incoming_alerts_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final AlertService _alertService = AlertService();
  final AuthService _authService = AuthService();
  late ShakeDetector _shakeDetector;

  bool _alertActive = false;
  String? _activeAlertId;
  int _cancelCountdown = 10;
  Timer? _cancelTimer;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _initFcm();
    _requestLocationPermission();

    _shakeDetector = ShakeDetector(onShake: _onShakeDetected);
    _shakeDetector.start();
  }

  Future<void> _initFcm() async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) await _authService.updateFcmToken(token);

    // Foreground FCM
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (!mounted) return;
      final title = message.notification?.title ?? 'Alert';
      final body = message.notification?.body ?? '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$title: $body'),
          backgroundColor: AppTheme.primaryRed,
          duration: const Duration(seconds: 5),
        ),
      );
    });
  }

  Future<void> _requestLocationPermission() async {
    await LocationService.requestPermission();
  }

  void _onShakeDetected() {
    if (!_alertActive) {
      _startAlertCountdown();
    }
  }

  void _startAlertCountdown() {
    setState(() {
      _alertActive = true;
      _cancelCountdown = 10;
    });

    _cancelTimer?.cancel();
    _cancelTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cancelCountdown <= 1) {
        timer.cancel();
        _sendAlert();
      } else {
        if (mounted) setState(() => _cancelCountdown--);
      }
    });
  }

  Future<void> _sendAlert() async {
    final alertId = await _alertService.triggerAlert();
    if (mounted) {
      setState(() {
        _activeAlertId = alertId;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🚨 Alert sent to your Safe-Circle!'),
          backgroundColor: AppTheme.primaryRed,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  void _cancelAlert() {
    _cancelTimer?.cancel();
    setState(() {
      _alertActive = false;
      _activeAlertId = null;
      _cancelCountdown = 10;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Alert cancelled')),
    );
  }

  Future<void> _markSafe() async {
    if (_activeAlertId != null) {
      await _alertService.resolveAlert(_activeAlertId!);
    }
    _cancelTimer?.cancel();
    setState(() {
      _alertActive = false;
      _activeAlertId = null;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('✅ Marked safe. Alert resolved.'),
            backgroundColor: AppTheme.safeGreen),
      );
    }
  }

  @override
  void dispose() {
    _shakeDetector.stop();
    _cancelTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _SOSPage(
        alertActive: _alertActive,
        activeAlertId: _activeAlertId,
        cancelCountdown: _cancelCountdown,
        onSOSPressed: _alertActive ? null : _startAlertCountdown,
        onCancel: _cancelAlert,
        onMarkSafe: _markSafe,
      ),
      const SafeCircleScreen(),
      const AlertHistoryScreen(),
      const IncomingAlertsScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.shield_rounded,
                color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Suraksha-Setu',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async => await _authService.logout(),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.sos_outlined),
              selectedIcon: Icon(Icons.sos),
              label: 'SOS'),
          NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people),
              label: 'Circle'),
          NavigationDestination(
              icon: Icon(Icons.history_outlined),
              selectedIcon: Icon(Icons.history),
              label: 'History'),
          NavigationDestination(
              icon: Icon(Icons.notifications_outlined),
              selectedIcon: Icon(Icons.notifications),
              label: 'Alerts'),
        ],
      ),
    );
  }
}

// ── SOS page widget ──────────────────────────────────────────────
class _SOSPage extends StatelessWidget {
  final bool alertActive;
  final String? activeAlertId;
  final int cancelCountdown;
  final VoidCallback? onSOSPressed;
  final VoidCallback onCancel;
  final VoidCallback onMarkSafe;

  const _SOSPage({
    required this.alertActive,
    required this.activeAlertId,
    required this.cancelCountdown,
    required this.onSOSPressed,
    required this.onCancel,
    required this.onMarkSafe,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bool alertSent = activeAlertId != null;
    final bool inCountdown = alertActive && !alertSent;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Status text
          Text(
            inCountdown
                ? 'Sending alert in...'
                : alertSent
                    ? '🚨 Alert Sent — Help is Coming'
                    : 'Shake phone or press button to alert your circle',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: inCountdown || alertSent
                      ? AppTheme.primaryRed
                      : colors.onSurface.withOpacity(0.7),
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 40),

          // SOS Button
          GestureDetector(
            onTap: onSOSPressed,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: alertActive ? AppTheme.primaryRed : colors.primary,
                boxShadow: [
                  BoxShadow(
                    color: (alertActive ? AppTheme.primaryRed : colors.primary)
                        .withOpacity(0.4),
                    blurRadius: 30,
                    spreadRadius: 8,
                  ),
                ],
              ),
              child: Center(
                child: inCountdown
                    ? Text(
                        '$cancelCountdown',
                        style: const TextStyle(
                            fontSize: 64,
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            alertSent ? Icons.warning_rounded : Icons.sos,
                            size: 64,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            alertSent ? 'SOS' : 'SOS',
                            style: const TextStyle(
                                fontSize: 24,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 4),
                          ),
                        ],
                      ),
              ),
            ),
          ),

          const SizedBox(height: 40),

          // Cancel / Mark Safe buttons
          if (inCountdown)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onCancel,
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Cancel — False Alarm',
                    style: TextStyle(fontSize: 16)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryRed,
                  side: const BorderSide(color: AppTheme.primaryRed),
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),

          if (alertSent) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onMarkSafe,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('I am Safe — Resolve Alert',
                    style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.safeGreen,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Hint
          if (!alertActive)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.vibration, size: 16, color: colors.outline),
                const SizedBox(width: 6),
                Text('Shake phone to trigger SOS',
                    style: TextStyle(color: colors.outline)),
              ],
            ),
        ],
      ),
    );
  }
}