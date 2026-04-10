import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import 'camera_settings.dart';

class GeoImageWatermark {
  static Future<File> stamp({
    required File imageFile,
    required WatermarkSettings settings,
    required Position? cachedPosition,
    required String cachedAddress,
    required String compassDirection,
  }) async {
    final isDark = settings.theme == WatermarkTheme.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final cardColor = isDark ? const ui.Color(0xCC000000) : const ui.Color(0xCCFFFFFF);

    /// Load original image
    final bytes = await imageFile.readAsBytes();
    final baseImage = await decodeImageFromList(bytes);

    double cropWidth = baseImage.width.toDouble();
    double cropHeight = baseImage.height.toDouble();
    double srcX = 0;
    double srcY = 0;

    /// Aspect Ratio Enforcer via GPU Canvas Crop
    final targetAspect = settings.ratio == CameraRatio.ratio16_9 ? 9 / 16 : 3 / 4;
    final currentAspect = cropWidth / cropHeight;

    if (currentAspect > targetAspect) {
      double newWidth = cropHeight * targetAspect;
      srcX = (cropWidth - newWidth) / 2;
      cropWidth = newWidth;
    } else if (currentAspect < targetAspect) {
      double newHeight = cropWidth / targetAspect;
      srcY = (cropHeight - newHeight) / 2;
      cropHeight = newHeight;
    }

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    canvas.drawImageRect(
      baseImage,
      Rect.fromLTWH(srcX, srcY, cropWidth, cropHeight),
      Rect.fromLTWH(0, 0, cropWidth, cropHeight),
      Paint(),
    );

    /// Use background cached location or fallback to fetching
    Position gps = cachedPosition ?? await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    String address = cachedAddress;
    
    if (address.isEmpty) {
      try {
        final place = (await placemarkFromCoordinates(gps.latitude, gps.longitude)).first;
        address = '${place.subLocality ?? ''}, ${place.locality ?? ''}, ${place.administrativeArea ?? ''}';
      } catch (_) {}
    }

    final timeStr = DateFormat('dd-MM-yyyy HH:mm:ss').format(DateTime.now());

    /// Build watermark text
    final textPainter = TextPainter(
      text: TextSpan(
        style: TextStyle(
          fontSize: 26,
          color: textColor,
        ),
        children: [
          TextSpan(
            text: '📍 ${gps.latitude.toStringAsFixed(6)}, ${gps.longitude.toStringAsFixed(6)} ($compassDirection)\n',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          TextSpan(
            text: '🕒 $timeStr\n',
          ),
          TextSpan(
            text: '🏠 $address',
          ),
        ],
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout(maxWidth: cropWidth * 0.8);

    /// Layout configuration
    const padding = 20.0;
    const margin = 30.0;

    final totalWidth = textPainter.width + padding * 2;
    final totalHeight = textPainter.height + padding * 2;

    double dx = margin;
    double dy = margin;

    switch (settings.position) {
      case WatermarkPosition.bottomLeft:
        dx = margin;
        dy = cropHeight - totalHeight - margin;
        break;
      case WatermarkPosition.bottomRight:
        dx = cropWidth - totalWidth - margin;
        dy = cropHeight - totalHeight - margin;
        break;
      case WatermarkPosition.topLeft:
        dx = margin;
        dy = margin;
        break;
      case WatermarkPosition.topRight:
        dx = cropWidth - totalWidth - margin;
        dy = margin;
        break;
    }

    /// Draw background card
    final cardRect = Rect.fromLTWH(dx, dy, totalWidth, totalHeight);
    canvas.drawRRect(
      RRect.fromRectAndRadius(cardRect, const Radius.circular(24)),
      Paint()..color = cardColor,
    );

    /// Draw Text
    textPainter.paint(canvas, Offset(dx + padding, dy + padding));

    /// Convert to image natively
    final finalImage = await recorder.endRecording().toImage(cropWidth.toInt(), cropHeight.toInt());
    final byteData = await finalImage.toByteData(format: ui.ImageByteFormat.png);

    final dir = await getTemporaryDirectory();
    final outputFile = File('${dir.path}/geo_${DateTime.now().millisecondsSinceEpoch}.png');
    
    await outputFile.writeAsBytes(byteData!.buffer.asUint8List());

    return outputFile;
  }
}