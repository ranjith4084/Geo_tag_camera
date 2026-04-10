import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionResult {
  final bool isGranted;
  final String errorMessage;

  const PermissionResult(this.isGranted, [this.errorMessage = '']);
}

class PermissionService {
  static Future<PermissionResult> ensureAll() async {
    // 📍 Location
    LocationPermission loc = await Geolocator.checkPermission();

    if (loc == LocationPermission.denied) {
      loc = await Geolocator.requestPermission();
    }

    if (loc == LocationPermission.deniedForever || loc == LocationPermission.denied) {
      return const PermissionResult(
        false,
        "We need Location access to fetch high-accuracy coordinates to footprint on your image.",
      );
    }

    // 📷 Camera
    final cam = await Permission.camera.request();

    if (!cam.isGranted) {
      return const PermissionResult(
        false,
        "We need Camera access to actually take the photos!",
      );
    }

    return const PermissionResult(true);
  }
}
