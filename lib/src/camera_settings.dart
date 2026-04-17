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

enum WatermarkFontStyle {
  defaultStyle,
  monospaced,
  serif,
  italic,
  bold,
}

enum WatermarkTimeFormat {
  format12Hour,
  format24Hour,
}

enum WatermarkDateFormat {
  dd_mm_yyyy,
  mm_dd_yyyy,
  custom,
}

enum WatermarkMapType {
  normal,
  satellite,
  hybrid,
}

enum MapAlignment {
  left,
  right,
}

class WatermarkSettings {
  final WatermarkPosition position;
  final WatermarkTheme theme;
  final CameraRatio ratio;
  final double scale;
  final bool showCoordinates;
  final bool showAddress;
  final WatermarkTimeFormat timeFormat;
  final WatermarkFontStyle fontStyle;
  final WatermarkDateFormat dateFormat;
  final String customDateFormat;
  final bool showMap;
  final WatermarkMapType mapType;
  final MapAlignment mapAlignment;

  const WatermarkSettings({
    this.position = WatermarkPosition.bottomLeft,
    this.theme = WatermarkTheme.dark,
    this.ratio = CameraRatio.ratio16_9,
    this.scale = 1.0,
    this.showCoordinates = true,
    this.showAddress = true,
    this.timeFormat = WatermarkTimeFormat.format24Hour,
    this.fontStyle = WatermarkFontStyle.defaultStyle,
    this.dateFormat = WatermarkDateFormat.dd_mm_yyyy,
    this.customDateFormat = 'dd/MM/yyyy',
    this.showMap = false,
    this.mapType = WatermarkMapType.normal,
    this.mapAlignment = MapAlignment.left,
  });

  WatermarkSettings copyWith({
    WatermarkPosition? position,
    WatermarkTheme? theme,
    CameraRatio? ratio,
    double? scale,
    bool? showCoordinates,
    bool? showAddress,
    WatermarkTimeFormat? timeFormat,
    WatermarkFontStyle? fontStyle,
    WatermarkDateFormat? dateFormat,
    String? customDateFormat,
    bool? showMap,
    WatermarkMapType? mapType,
    MapAlignment? mapAlignment,
  }) {
    return WatermarkSettings(
      position: position ?? this.position,
      theme: theme ?? this.theme,
      ratio: ratio ?? this.ratio,
      scale: scale ?? this.scale,
      showCoordinates: showCoordinates ?? this.showCoordinates,
      showAddress: showAddress ?? this.showAddress,
      timeFormat: timeFormat ?? this.timeFormat,
      fontStyle: fontStyle ?? this.fontStyle,
      dateFormat: dateFormat ?? this.dateFormat,
      customDateFormat: customDateFormat ?? this.customDateFormat,
      showMap: showMap ?? this.showMap,
      mapType: mapType ?? this.mapType,
      mapAlignment: mapAlignment ?? this.mapAlignment,
    );
  }
}