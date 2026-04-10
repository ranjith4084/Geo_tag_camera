import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

class SensorOverlay extends StatefulWidget {
  const SensorOverlay({super.key});

  @override
  State<SensorOverlay> createState() => _SensorOverlayState();
}

class _SensorOverlayState extends State<SensorOverlay> {
  StreamSubscription? _accSub;
  double _roll = 0.0;

  @override
  void initState() {
    super.initState();

    _accSub = accelerometerEventStream().listen((event) {
      if (!mounted) return;

      final roll =
      atan2(event.x, sqrt(event.y * event.y + event.z * event.z));

      setState(() => _roll = roll);
    });
  }

  @override
  void dispose() {
    _accSub?.cancel();
    super.dispose();
  }

  bool get _isLevel => _roll.abs() < 0.03;

  @override
  Widget build(BuildContext context) {
    final color = _isLevel ? Colors.green : Colors.red;

    return IgnorePointer(
      child: Center(
        child: Transform.rotate(
          angle: _roll,
          child: Container(
            width: 180,
            height: 2,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }
}