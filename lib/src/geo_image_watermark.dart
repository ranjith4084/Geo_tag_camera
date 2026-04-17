import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:math';

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
    Position gps = cachedPosition ?? await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
    String address = cachedAddress;
    
    if (address.isEmpty) {
      try {
        final place = (await placemarkFromCoordinates(gps.latitude, gps.longitude)).first;
        address = '${place.subLocality ?? ''}, ${place.locality ?? ''}, ${place.administrativeArea ?? ''}';
      } catch (_) {}
    }

    String basePattern = 'dd/MM/yyyy';
    if (settings.dateFormat == WatermarkDateFormat.mm_dd_yyyy) {
      basePattern = 'MM/dd/yyyy';
    } else if (settings.dateFormat == WatermarkDateFormat.custom) {
      basePattern = settings.customDateFormat.isNotEmpty ? settings.customDateFormat : 'dd/MM/yyyy';
    }

    final timePattern = settings.timeFormat == WatermarkTimeFormat.format12Hour 
        ? 'hh:mm:ss a' 
        : 'HH:mm:ss';
        
    final fullDateFormatPattern = '$basePattern $timePattern';
    
    String timeStr = '';
    try {
      timeStr = DateFormat(fullDateFormatPattern).format(DateTime.now());
    } catch (_) {
      timeStr = DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now());
    }

    var mapTiles = <(int, int, ui.Image)>[];
    double vpLeft = 0;
    double vpTop = 0;
    
    if (settings.showMap) {
      try {
        final zoom = 15;
        final latRad = gps.latitude * pi / 180.0;
        final n = pow(2.0, zoom).toDouble();
        
        final px = ((gps.longitude + 180.0) / 360.0 * n) * 256.0;
        final py = ((1.0 - log(tan(latRad) + 1.0 / cos(latRad)) / pi) / 2.0 * n) * 256.0;

        vpLeft = px - 200.0;
        vpTop = py - 150.0;
        final vpRight = px + 200.0;
        final vpBottom = py + 150.0;

        final minTx = (vpLeft ~/ 256);
        final maxTx = (vpRight ~/ 256);
        final minTy = (vpTop ~/ 256);
        final maxTy = (vpBottom ~/ 256);

        final client = HttpClient();
        final futures = <Future<void>>[];

        for (int tx = minTx; tx <= maxTx; tx++) {
          for (int ty = minTy; ty <= maxTy; ty++) {
            futures.add(() async {
              String url;
              if (settings.mapType == WatermarkMapType.satellite || settings.mapType == WatermarkMapType.hybrid) {
                url = 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/$zoom/$ty/$tx';
              } else {
                url = 'https://tile.openstreetmap.org/$zoom/$tx/$ty.png';
              }
              try {
                final request = await client.getUrl(Uri.parse(url));
                request.headers.add('User-Agent', 'geo_tag_camera_flutter (github.com/ranjith4084/Geo_tag_camera)');
                final response = await request.close();
                if (response.statusCode == 200) {
                  final List<int> byteList = [];
                  await for (var chunk in response) {
                    byteList.addAll(chunk);
                  }
                  final img = await decodeImageFromList(Uint8List.fromList(byteList));
                  mapTiles.add((tx, ty, img));
                }
              } catch (_) {}
            }());
          }
        }
        await Future.wait(futures);
        client.close();
      } catch (_) {}
    }

    String? fontFamily;
    FontWeight textWeight = FontWeight.normal;
    FontStyle textStyle = FontStyle.normal;

    switch (settings.fontStyle) {
      case WatermarkFontStyle.monospaced:
        fontFamily = 'monospace';
        break;
      case WatermarkFontStyle.serif:
        fontFamily = 'serif';
        break;
      case WatermarkFontStyle.italic:
        textStyle = FontStyle.italic;
        break;
      case WatermarkFontStyle.bold:
        textWeight = FontWeight.bold;
        break;
      default:
        break;
    }

    final List<TextSpan> spans = [];

    if (settings.showCoordinates) {
      spans.add(TextSpan(
        text: '📍 ${gps.latitude.toStringAsFixed(6)}, ${gps.longitude.toStringAsFixed(6)} ($compassDirection)',
        style: TextStyle(
          fontWeight: settings.fontStyle == WatermarkFontStyle.bold ? FontWeight.w900 : FontWeight.bold,
        ),
      ));
    }

    spans.add(TextSpan(
      text: '${spans.isNotEmpty ? '\n' : ''}🕒 $timeStr',
    ));

    if (settings.showAddress && address.isNotEmpty) {
      spans.add(TextSpan(
        text: '\n🏠 $address',
      ));
    }

    /// Build watermark text
    double safeMaxWidth = (cropWidth * 0.9) - (settings.showMap ? (200.0 * settings.scale + 20.0 * settings.scale) : 0);

    final textPainter = TextPainter(
      text: TextSpan(
        style: TextStyle(
          fontSize: 26 * settings.scale,
          color: textColor,
          fontFamily: fontFamily,
          fontWeight: textWeight,
          fontStyle: textStyle,
        ),
        children: spans,
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout(maxWidth: safeMaxWidth);

    /// Layout configuration
    final padding = 20.0 * settings.scale;
    final margin = 30.0 * settings.scale;

    double mapDrawWidth = 0;
    double mapDrawHeight = 0;
    if (mapTiles.isNotEmpty) {
      mapDrawWidth = 200.0 * settings.scale;
      mapDrawHeight = 200.0 * settings.scale;
    }

    final mapSpacing = mapTiles.isNotEmpty ? padding : 0.0;
    final totalWidth = mapDrawWidth + mapSpacing + textPainter.width + padding * 2;
    
    final contentHeight = mapDrawHeight > textPainter.height ? mapDrawHeight : textPainter.height;
    final totalHeight = contentHeight + padding * 2;

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
      RRect.fromRectAndRadius(cardRect, Radius.circular(24 * settings.scale)),
      Paint()..color = cardColor,
    );

    /// Draw Map if available
    double mapX = dx + padding;
    double textX = dx + padding;
    
    if (mapTiles.isNotEmpty) {
      if (settings.mapAlignment == MapAlignment.left) {
        mapX = dx + padding;
        textX = dx + padding + mapDrawWidth + mapSpacing;
      } else {
        textX = dx + padding;
        mapX = dx + padding + textPainter.width + mapSpacing;
      }
    }

    double mapY = dy + padding + (contentHeight - mapDrawHeight) / 2;
    double textY = dy + padding + (contentHeight - textPainter.height) / 2;

    if (mapTiles.isNotEmpty) {
      final mapRect = Rect.fromLTWH(mapX, mapY, mapDrawWidth, mapDrawHeight);
      
      canvas.save();
      // Clip to our bounds with rounded corners
      canvas.clipRRect(RRect.fromRectAndRadius(mapRect, Radius.circular(8 * settings.scale)));
      
      for (final tile in mapTiles) {
        final tx = tile.$1;
        final ty = tile.$2;
        final img = tile.$3;
        
        final tileX = tx * 256.0 - vpLeft;
        final tileY = ty * 256.0 - vpTop;
        
        canvas.drawImageRect(
          img,
          Rect.fromLTWH(0, 0, 256, 256),
          Rect.fromLTWH(
            mapX + tileX * settings.scale, 
            mapY + tileY * settings.scale, 
            256 * settings.scale, 
            256 * settings.scale
          ),
          Paint(),
        );
      }
      
      canvas.restore();
    }

    /// Draw Text
    textPainter.paint(canvas, Offset(textX, textY));

    /// Convert to image natively
    final finalImage = await recorder.endRecording().toImage(cropWidth.toInt(), cropHeight.toInt());
    final byteData = await finalImage.toByteData(format: ui.ImageByteFormat.png);

    final dir = await getTemporaryDirectory();
    final outputFile = File('${dir.path}/geo_${DateTime.now().millisecondsSinceEpoch}.png');
    
    await outputFile.writeAsBytes(byteData!.buffer.asUint8List());

    return outputFile;
  }
}