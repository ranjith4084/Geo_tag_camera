import 'dart:io';
import 'dart:async';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:geo_tag_camera/src/camera_settings.dart';
import 'package:geo_tag_camera/src/preview_page.dart';
import 'package:geo_tag_camera/src/permission_service.dart';

import 'geo_image_watermark.dart';
import 'grid_overlay.dart';
import 'sensor_overlay.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  int _cameraIndex = 0;
  FlashMode _flashMode = FlashMode.off;

  WatermarkSettings _watermarkSettings = const WatermarkSettings();

  bool _loading = true;
  bool _permissionDenied = false;
  String _permissionErrorMessage = "";
  bool _isProcessing = false;

  double _minAvailableZoom = 1.0;
  double _maxAvailableZoom = 1.0;
  double _currentScale = 1.0;
  double _baseScale = 1.0;

  // Caching mechanism variables
  Position? _cachedLocation;
  String _cachedAddress = "";
  StreamSubscription<Position>? _positionStream;

  String _compassDirection = "N";
  StreamSubscription<MagnetometerEvent>? _magnetometerStream;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _positionStream?.cancel();
    _magnetometerStream?.cancel();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) return;

    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _controller?.dispose();
      _positionStream?.pause();
      _magnetometerStream?.pause();
    } else if (state == AppLifecycleState.resumed) {
      _startCamera();
      _positionStream?.resume();
      _magnetometerStream?.resume();
    }
  }

  Future<void> _init() async {
    setState(() {
      _loading = true;
      _permissionDenied = false;
    });

    final result = await PermissionService.ensureAll();

    if (!result.isGranted) {
      if (mounted) {
        setState(() {
          _loading = false;
          _permissionDenied = true;
          _permissionErrorMessage = result.errorMessage;
        });
      }
      return;
    }

    _startBackgroundSensors();

    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
      await _startCamera();
    } else {
      if (mounted) {
        setState(() {
          _loading = false;
          _permissionDenied = true;
          _permissionErrorMessage = "No cameras are accessible on this device.";
        });
      }
    }
  }

  void _startBackgroundSensors() {
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10),
    ).listen((Position position) async {
      _cachedLocation = position;
      try {
        final place = (await placemarkFromCoordinates(position.latitude, position.longitude)).first;
        _cachedAddress = '${place.subLocality ?? ''}, ${place.locality ?? ''}, ${place.administrativeArea ?? ''}';
      } catch (_) {}
    });

    _magnetometerStream = magnetometerEventStream().listen((MagnetometerEvent event) {
      double heading = atan2(event.y, event.x) * (180 / pi);
      if (heading < 0) heading += 360;
      
      final directions = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"];
      final index = ((heading + 22.5) % 360) ~/ 45;
      if (mounted) {
        _compassDirection = directions[index % 8];
      }
    });
  }

  Future<void> _startCamera() async {
    if (_cameras == null || _cameras!.isEmpty) return;

    final controller = CameraController(
      _cameras![_cameraIndex],
      ResolutionPreset.veryHigh,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await controller.initialize();
      await controller.lockCaptureOrientation(DeviceOrientation.portraitUp);

      _minAvailableZoom = await controller.getMinZoomLevel();
      _maxAvailableZoom = await controller.getMaxZoomLevel();

      if (mounted) {
        setState(() {
          _controller = controller;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _permissionDenied = true;
          _permissionErrorMessage = "Camera initialized failed.";
        });
      }
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras == null || _cameras!.isEmpty) return;
    _cameraIndex = (_cameraIndex + 1) % _cameras!.length;
    setState(() => _loading = true);
    await _controller?.dispose();
    await _startCamera();
  }

  Future<void> _toggleFlash() async {
    if (_controller == null) return;
    try {
      _flashMode = _flashMode == FlashMode.off ? FlashMode.torch : FlashMode.off;
      await _controller!.setFlashMode(_flashMode);
      setState(() {});
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Flash not supported on this lens')),
      );
    }
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _baseScale = _currentScale;
  }

  Future<void> _handleScaleUpdate(ScaleUpdateDetails details) async {
    if (_controller == null || _cameras == null) return;
    _currentScale = (_baseScale * details.scale).clamp(_minAvailableZoom, _maxAvailableZoom);
    await _controller!.setZoomLevel(_currentScale);
    setState(() {});
  }


  Future<void> _capture() async {
    if (_controller == null || !_controller!.value.isInitialized || _controller!.value.isTakingPicture) {
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final XFile file = await _controller!.takePicture();

      final stamped = await GeoImageWatermark.stamp(
        imageFile: File(file.path),
        settings: _watermarkSettings,
        cachedPosition: _cachedLocation,
        cachedAddress: _cachedAddress,
        compassDirection: _compassDirection,
      );

      if (!mounted) return;

      final File? result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PreviewPage(imageFile: stamped),
        ),
      );

      if (result != null && mounted) {
        Navigator.pop(context, result);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error taking picture: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showSettingsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[600],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('Watermark Settings', 
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    
                    // Theme Toggle
                    ListTile(
                      leading: const Icon(Icons.palette, color: Colors.white70),
                      title: const Text('Theme', style: TextStyle(color: Colors.white)),
                      trailing: ToggleButtons(
                        isSelected: [
                          _watermarkSettings.theme == WatermarkTheme.dark,
                          _watermarkSettings.theme == WatermarkTheme.light,
                        ],
                        onPressed: (index) {
                          final newTheme = index == 0 ? WatermarkTheme.dark : WatermarkTheme.light;
                          setState(() {
                            _watermarkSettings = _watermarkSettings.copyWith(theme: newTheme);
                          });
                          setSheetState(() {});
                        },
                        color: Colors.grey,
                        selectedColor: Colors.white,
                        fillColor: Colors.blueAccent.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                        constraints: const BoxConstraints(minHeight: 36, minWidth: 60),
                        children: const [
                          Text('Dark'),
                          Text('Light'),
                        ],
                      ),
                    ),

                    // Ratio Toggle
                    ListTile(
                      leading: const Icon(Icons.aspect_ratio, color: Colors.white70),
                      title: const Text('Aspect Ratio', style: TextStyle(color: Colors.white)),
                      trailing: ToggleButtons(
                        isSelected: [
                          _watermarkSettings.ratio == CameraRatio.ratio16_9,
                          _watermarkSettings.ratio == CameraRatio.ratio4_3,
                        ],
                        onPressed: (index) {
                          final newRatio = index == 0 ? CameraRatio.ratio16_9 : CameraRatio.ratio4_3;
                          setState(() {
                            _watermarkSettings = _watermarkSettings.copyWith(ratio: newRatio);
                          });
                          setSheetState(() {});
                        },
                        color: Colors.grey,
                        selectedColor: Colors.white,
                        fillColor: Colors.blueAccent.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
                        constraints: const BoxConstraints(minHeight: 36, minWidth: 60),
                        children: const [
                          Text('16:9'),
                          Text('4:3'),
                        ],
                      ),
                    ),

                    // Position
                    ListTile(
                      leading: const Icon(Icons.crop_free, color: Colors.white70),
                      title: const Text('Position', style: TextStyle(color: Colors.white)),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButton<WatermarkPosition>(
                          dropdownColor: Colors.grey[800],
                          value: _watermarkSettings.position,
                          style: const TextStyle(color: Colors.white),
                          underline: const SizedBox(), 
                          icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                          items: const [
                            DropdownMenuItem(value: WatermarkPosition.bottomLeft, child: Text('Bottom Left')),
                            DropdownMenuItem(value: WatermarkPosition.bottomRight, child: Text('Bottom Right')),
                            DropdownMenuItem(value: WatermarkPosition.topLeft, child: Text('Top Left')),
                            DropdownMenuItem(value: WatermarkPosition.topRight, child: Text('Top Right')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _watermarkSettings = _watermarkSettings.copyWith(position: val);
                              });
                              setSheetState(() {});
                            }
                          },
                        ),
                      ),
                    ),
                    
                    // Size Slider
                    ListTile(
                      leading: const Icon(Icons.photo_size_select_large, color: Colors.white70),
                      title: const Text('Watermark Size', style: TextStyle(color: Colors.white)),
                      subtitle: Slider(
                        value: _watermarkSettings.scale,
                        min: 0.5,
                        max: 2.0,
                        divisions: 15,
                        label: '${(_watermarkSettings.scale * 100).toInt()}%',
                        onChanged: (val) {
                          setState(() {
                            _watermarkSettings = _watermarkSettings.copyWith(scale: val);
                          });
                          setSheetState(() {});
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCameraPreview() {
    final previewAspect = 1 / _controller!.value.aspectRatio;
    final aspectTarget = _watermarkSettings.ratio == CameraRatio.ratio16_9 ? 9 / 16 : 3 / 4;

    return Center(
      child: AspectRatio(
        aspectRatio: aspectTarget,
        child: ClipRect(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: 100,
              height: 100 / previewAspect,
              child: Builder(
                builder: (ctx) {
                  return GestureDetector(
                    onScaleStart: _handleScaleStart,
                    onScaleUpdate: _handleScaleUpdate,
                    onTapDown: (details) {
                      final box = ctx.findRenderObject() as RenderBox;
                      final size = box.size;
                      final offset = Offset(
                        details.localPosition.dx / size.width,
                        details.localPosition.dy / size.height,
                      );
                      try {
                        _controller!.setExposurePoint(offset);
                        _controller!.setFocusPoint(offset);
                      } catch (_) {}
                    },
                    child: CameraPreview(_controller!),
                  );
                }
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (_permissionDenied) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_disabled, color: Colors.blueAccent, size: 80),
                const SizedBox(height: 24),
                const Text(
                  'Access Required',
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  _permissionErrorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  onPressed: () => openAppSettings(),
                  child: const Text('Open Settings', style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _init,
                  child: const Text('I\'ve enabled it, Retry', style: TextStyle(color: Colors.white54)),
                )
              ],
            ),
          ),
        ),
      );
    }

    if (_controller == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: Text('Camera initialization failed', style: TextStyle(color: Colors.white))),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildCameraPreview(),
          const GridOverlay(),
          const SensorOverlay(),

          Positioned(
            top: 40,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.cameraswitch, color: Colors.white, size: 30),
              onPressed: _isProcessing ? null : _switchCamera,
            ),
          ),
          Positioned(
            top: 40,
            right: 60,
            child: IconButton(
              icon: const Icon(Icons.settings, color: Colors.white, size: 30),
              onPressed: _isProcessing ? null : _showSettingsSheet,
            ),
          ),
          Positioned(
            top: 40,
            right: 20,
            child: IconButton(
              icon: Icon(
                _flashMode == FlashMode.off ? Icons.flash_off : Icons.flash_on,
                color: Colors.white,
                size: 30,
              ),
              onPressed: _isProcessing ? null : _toggleFlash,
            ),
          ),

          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: FloatingActionButton(
                onPressed: _isProcessing ? null : _capture,
                backgroundColor: _isProcessing ? Colors.grey : Colors.white,
                child: _isProcessing
                    ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: CircularProgressIndicator(color: Colors.black, strokeWidth: 3),
                      )
                    : const Icon(Icons.camera_alt, color: Colors.black),
              ),
            ),
          ),
        ],
      ),
    );
  }
}