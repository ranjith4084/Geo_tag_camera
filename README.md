# Geo Tag Camera 📸📍

A powerful Flutter package that provides a fully customizable camera UI for capturing photos with an automatic geo-location (GPS), compass direction, date, and address watermark stamped directly onto the image.

## 🌟 Features

* **Custom Camera UI:** Clean preview with tap-to-focus and pinch-to-zoom capabilities.
* **Automatic Watermarking:** Reads device GPS and stamps latitude, longitude, and actual street address directly onto the picture.
* **Compass Heading:** Real-time magnetometer analysis indicating the direction the camera is facing (N, NW, SE, etc.).
* **Custom Overlays:** Built-in Rule of Thirds grid overlay and device angle sensors (gyroscope) to align perfect shots.
* **Themes & Placements:** Native modal to toggle Dark/Light watermark themes and placement (Corners).
* **Cross-Platform:** Out-of-the-box working on Android & iOS.

## 📱 Screenshots

*(Add screenshots of your camera interface and a watermarked photo here!)*

## 🚀 Installing

To install the package, simply add the dependency to your `pubspec.yaml` file:

```yaml
dependencies:
  geo_tag_camera: ^1.0.0
```

## 🛠️ Usage

To use the camera feature, simply navigate to the `CameraPage`. The page will request location and camera permissions automatically.

```dart
import 'package:flutter/material.dart';
import 'package:geo_tag_camera/geo_tag_camera.dart';

class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          child: Text("Open Geo Camera"),
          onPressed: () async {
            // Push the camera page onto the navigation stack
            final resultFile = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => CameraPage()),
            );

            if (resultFile != null) {
              print("Picture saved to: ${resultFile.path}");
            }
          },
        ),
      ),
    );
  }
}
```

## ⚙️ Permissions Setup

### Android
Add these permissions to your `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

### iOS
Add these keys to your `ios/Runner/Info.plist`:
```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to capture photos.</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs access to your location to watermark photos.</string>
```