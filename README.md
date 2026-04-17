
<h1 align="center">Geo Tag Camera 📸📍</h1>

<p align="center">
  <strong>A premium Flutter package providing a fully customizable camera UI for capturing photos with automatic geo-location, compass direction, date, and address watermarks stamped directly onto the image.</strong>
</p>

<p align="center">
  <a href="https://pub.dev/packages/geo_tag_camera"><img src="https://img.shields.io/pub/v/geo_tag_camera.svg?style=flat-square&color=blue" alt="Pub Version"></a>
  <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Flutter-%E2%9D%A4-red.svg?style=flat-square" alt="Flutter Love"></a>
  <a href="https://github.com/ranjith4084/Geo_tag_camera/blob/main/LICENSE"><img src="https://img.shields.io/badge/License-MIT-green.svg?style=flat-square" alt="License: MIT"></a>
</p>

---

<p align="center">
  <img src="https://raw.githubusercontent.com/ranjith4084/Geo_tag_camera/main/assets/banner.png" alt="Geo Tag Camera Banner" width="800" style="max-width: 100%; height: auto;" />
</p>

## 🌟 Features

* ✨ **Custom Camera UI:** Clean, intuitive preview with tap-to-focus and pinch-to-zoom capabilities.
* 📍 **Automatic Watermarking:** Automatically reads device GPS and stamps latitude, longitude, and actual street address directly onto your pictures.
* 🧭 **Compass Heading:** Real-time magnetometer analysis indicating the direction the camera is facing (N, NW, SE, etc.).
* 📐 **Smart Overlays:** Built-in **Rule of Thirds** grid overlay and active device angle sensors (gyroscope alignment) to capture perfect shots.
* 🚀 **Dedicated Settings UI:** A beautiful, full-screen configuration menu divided into logical topics:
  * 🎨 **Layout & Style:** Toggle dark/light themes, aspect ratios (16:9, 4:3), watermark sizes, layout corners, and rich typography fonts.
  * 📍 **Location Content:** Individually hide or show street addresses and GPS coordinates based on your privacy needs.
  * 🕒 **Date & Time:** Complete control over 12/24 hour parameters along with DD/MM/YYYY, MM/DD/YYYY, and even custom formatting input.
  * 🗺️ **Map Overview:** Generate an API-Key-Free contextual Mini Map powered natively by OpenStreetMap and ESRI! Place it horizontally on the left or the right side of the watermark box seamlessly!
* 📱 **Cross-Platform:** Works right out of the box on both **Android & iOS**, requesting all the necessary permissions internally.


---

## 📸 Screenshots

<p align="center">
  <img src="https://raw.githubusercontent.com/ranjith4084/Geo_tag_camera/main/assets/1.jpg" alt="Screenshot 1" width="22%"/>
<img src="https://raw.githubusercontent.com/ranjith4084/Geo_tag_camera/main/assets/2.jpg" alt="Screenshot 2" width="22%"/>
  <img src="https://raw.githubusercontent.com/ranjith4084/Geo_tag_camera/main/assets/3.jpg" alt="Screenshot 3" width="22%"/>
  <img src="https://raw.githubusercontent.com/ranjith4084/Geo_tag_camera/main/assets/4.jpg" alt="Screenshot 4" width="22%"/>
 <img src="https://raw.githubusercontent.com/ranjith4084/Geo_tag_camera/main/assets/5.jpg" alt="Screenshot 5" width="22%"/>
  <img src="https://raw.githubusercontent.com/ranjith4084/Geo_tag_camera/main/assets/6.jpg" alt="Screenshot 6" width="22%"/>
  <img src="https://raw.githubusercontent.com/ranjith4084/Geo_tag_camera/main/assets/7.jpg" alt="Screenshot 7" width="22%"/>
</p>

---

## 🚀 Installation

To use `geo_tag_camera` in your project, add the dependency to your `pubspec.yaml` file:

```yaml
dependencies:
  geo_tag_camera: ^1.0.6
```

Then, run:
```bash
flutter pub get
```

---

## 🛠️ Usage

To use the camera feature, simply navigate to the `CameraPage`. The package will effortlessly handle requesting camera and location permissions from the user.

```dart
import 'package:flutter/material.dart';
import 'package:geo_tag_camera/geo_tag_camera.dart';

class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          child: const Text("Open Geo Camera"),
          onPressed: () async {
            // Push the camera page onto the navigation stack
            final resultFile = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CameraPage()),
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

---

## ⚙️ Native Permissions Setup

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
<key>NSLocationAlwaysUsageDescription</key>
<string>This app needs access to your location to watermark photos.</string>
```

---

## 👨‍💻 Author

Built with ❤️ by [**Ranjith**](https://github.com/ranjith4084)

If you found this package helpful, consider giving it a ⭐ on GitHub and a 👍 on [pub.dev](https://pub.dev)!

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.