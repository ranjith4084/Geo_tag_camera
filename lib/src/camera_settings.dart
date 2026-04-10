enum CameraRatio {
  ratio4_3,
  ratio16_9,
}

enum WatermarkPosition {
  bottomLeft,
  bottomRight,
  topLeft,
  topRight,
}

enum WatermarkTheme {
  dark,
  light,
}

class WatermarkSettings {
  final WatermarkPosition position;
  final WatermarkTheme theme;
  final CameraRatio ratio;
  final double scale;

  const WatermarkSettings({
    this.position = WatermarkPosition.bottomLeft,
    this.theme = WatermarkTheme.dark,
    this.ratio = CameraRatio.ratio16_9,
    this.scale = 1.0,
  });

  WatermarkSettings copyWith({
    WatermarkPosition? position,
    WatermarkTheme? theme,
    CameraRatio? ratio,
    double? scale,
  }) {
    return WatermarkSettings(
      position: position ?? this.position,
      theme: theme ?? this.theme,
      ratio: ratio ?? this.ratio,
      scale: scale ?? this.scale,
    );
  }
}