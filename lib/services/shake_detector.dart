import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';

class ShakeDetector {
  static const double _shakeThreshold = 12.0; // m/s²
  static const int _shakeInterval = 1000; // ms between triggers

  StreamSubscription? _subscription;
  DateTime? _lastShakeTime;
  final VoidCallbackAction onShake;

  ShakeDetector({required this.onShake});

  void start() {
    _subscription =
        accelerometerEventStream(samplingPeriod: SensorInterval.gameInterval)
            .listen((AccelerometerEvent event) {
      final magnitude =
          sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      // Subtract gravity (~9.8)
      final acceleration = magnitude - 9.8;
      if (acceleration > _shakeThreshold) {
        final now = DateTime.now();
        if (_lastShakeTime == null ||
            now.difference(_lastShakeTime!).inMilliseconds > _shakeInterval) {
          _lastShakeTime = now;
          onShake();
        }
      }
    });
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
  }
}

typedef VoidCallbackAction = void Function();