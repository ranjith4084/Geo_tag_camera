import 'package:flutter/material.dart';

import 'camera_settings.dart';

class SettingsPage extends StatefulWidget {
  final WatermarkSettings initialSettings;

  const SettingsPage({super.key, required this.initialSettings});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late WatermarkSettings _watermarkSettings;

  @override
  void initState() {
    super.initState();
    _watermarkSettings = widget.initialSettings;
  }

  void _saveAndPop() {
    Navigator.pop(context, _watermarkSettings);
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8, left: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.blueAccent, size: 20),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: Colors.blueAccent,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Card(
      color: const Color(0xFF1E1E1E),
      elevation: 4,
      shadowColor: Colors.black54,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: children,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F), // Sleek dark grey background
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        title: const Text('Watermark Settings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton(
            onPressed: _saveAndPop,
            child: const Text('Save', style: TextStyle(color: Colors.blueAccent, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              
              _buildSectionHeader('Layout & Style', Icons.dashboard),
              _buildCard(
                children: [
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
                      },
                      color: Colors.grey,
                      selectedColor: Colors.white,
                      fillColor: Colors.blueAccent.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                      constraints: const BoxConstraints(minHeight: 36, minWidth: 60),
                      children: const [Text('Dark'), Text('Light')],
                    ),
                  ),

                  const Divider(color: Colors.white10, height: 1),

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
                      },
                      color: Colors.grey,
                      selectedColor: Colors.white,
                      fillColor: Colors.blueAccent.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                      constraints: const BoxConstraints(minHeight: 36, minWidth: 60),
                      children: const [Text('16:9'), Text('4:3')],
                    ),
                  ),

                  const Divider(color: Colors.white10, height: 1),

                  // Position
                  ListTile(
                    leading: const Icon(Icons.crop_free, color: Colors.white70),
                    title: const Text('Position', style: TextStyle(color: Colors.white)),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(8)),
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
                            setState(() => _watermarkSettings = _watermarkSettings.copyWith(position: val));
                          }
                        },
                      ),
                    ),
                  ),
                  
                  const Divider(color: Colors.white10, height: 1),

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
                      activeColor: Colors.blueAccent,
                      onChanged: (val) {
                        setState(() => _watermarkSettings = _watermarkSettings.copyWith(scale: val));
                      },
                    ),
                  ),

                  const Divider(color: Colors.white10, height: 1),

                  // Font Style
                  ListTile(
                    leading: const Icon(Icons.font_download, color: Colors.white70),
                    title: const Text('Font Style', style: TextStyle(color: Colors.white)),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(8)),
                      child: DropdownButton<WatermarkFontStyle>(
                        dropdownColor: Colors.grey[800],
                        value: _watermarkSettings.fontStyle,
                        style: const TextStyle(color: Colors.white),
                        underline: const SizedBox(),
                        icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                        items: const [
                          DropdownMenuItem(value: WatermarkFontStyle.defaultStyle, child: Text('Default')),
                          DropdownMenuItem(value: WatermarkFontStyle.monospaced, child: Text('Monospaced')),
                          DropdownMenuItem(value: WatermarkFontStyle.serif, child: Text('Serif')),
                          DropdownMenuItem(value: WatermarkFontStyle.italic, child: Text('Italic')),
                          DropdownMenuItem(value: WatermarkFontStyle.bold, child: Text('Bold')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _watermarkSettings = _watermarkSettings.copyWith(fontStyle: val));
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),

              _buildSectionHeader('Location Content', Icons.pin_drop),
              _buildCard(
                children: [
                  // Show Coordinates Toggle
                  SwitchListTile(
                    secondary: const Icon(Icons.location_on, color: Colors.white70),
                    title: const Text('Show Coordinates', style: TextStyle(color: Colors.white)),
                    value: _watermarkSettings.showCoordinates,
                    activeColor: Colors.blueAccent,
                    onChanged: (val) {
                      setState(() => _watermarkSettings = _watermarkSettings.copyWith(showCoordinates: val));
                    },
                  ),

                  const Divider(color: Colors.white10, height: 1),

                  // Show Address Toggle
                  SwitchListTile(
                    secondary: const Icon(Icons.home, color: Colors.white70),
                    title: const Text('Show Address', style: TextStyle(color: Colors.white)),
                    value: _watermarkSettings.showAddress,
                    activeColor: Colors.blueAccent,
                    onChanged: (val) {
                      setState(() => _watermarkSettings = _watermarkSettings.copyWith(showAddress: val));
                    },
                  ),
                ]
              ),

              _buildSectionHeader('Date & Time', Icons.access_time),
              _buildCard(
                children: [
                  // Time Format
                  ListTile(
                    leading: const Icon(Icons.access_time, color: Colors.white70),
                    title: const Text('Time Format', style: TextStyle(color: Colors.white)),
                    trailing: ToggleButtons(
                      isSelected: [
                        _watermarkSettings.timeFormat == WatermarkTimeFormat.format12Hour,
                        _watermarkSettings.timeFormat == WatermarkTimeFormat.format24Hour,
                      ],
                      onPressed: (index) {
                        final newFormat = index == 0 ? WatermarkTimeFormat.format12Hour : WatermarkTimeFormat.format24Hour;
                        setState(() => _watermarkSettings = _watermarkSettings.copyWith(timeFormat: newFormat));
                      },
                      color: Colors.grey,
                      selectedColor: Colors.white,
                      fillColor: Colors.blueAccent.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                      constraints: const BoxConstraints(minHeight: 36, minWidth: 60),
                      children: const [Text('12 Hrs'), Text('24 Hrs')],
                    ),
                  ),

                  const Divider(color: Colors.white10, height: 1),

                  // Date Format
                  ListTile(
                    leading: const Icon(Icons.date_range, color: Colors.white70),
                    title: const Text('Date Format', style: TextStyle(color: Colors.white)),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(8)),
                      child: DropdownButton<WatermarkDateFormat>(
                        dropdownColor: Colors.grey[800],
                        value: _watermarkSettings.dateFormat,
                        style: const TextStyle(color: Colors.white),
                        underline: const SizedBox(),
                        icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                        items: const [
                          DropdownMenuItem(value: WatermarkDateFormat.dd_mm_yyyy, child: Text('DD/MM/YYYY')),
                          DropdownMenuItem(value: WatermarkDateFormat.mm_dd_yyyy, child: Text('MM/DD/YYYY')),
                          DropdownMenuItem(value: WatermarkDateFormat.custom, child: Text('Custom')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _watermarkSettings = _watermarkSettings.copyWith(dateFormat: val));
                          }
                        },
                      ),
                    ),
                  ),

                  if (_watermarkSettings.dateFormat == WatermarkDateFormat.custom) ...[
                    const Divider(color: Colors.white10, height: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: TextFormField(
                        initialValue: _watermarkSettings.customDateFormat,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Custom Date Pattern (e.g. yyyy-MMM-dd)',
                          labelStyle: const TextStyle(color: Colors.white54),
                          filled: true,
                          fillColor: Colors.black26,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onChanged: (val) {
                          setState(() => _watermarkSettings = _watermarkSettings.copyWith(customDateFormat: val));
                        },
                      ),
                    ),
                  ],
                ]
              ),

              _buildSectionHeader('Map Overview', Icons.map),
              _buildCard(
                children: [
                  // Show Mini Map
                  SwitchListTile(
                    secondary: const Icon(Icons.map, color: Colors.white70),
                    title: const Text('Show Mini Map', style: TextStyle(color: Colors.white)),
                    value: _watermarkSettings.showMap,
                    activeColor: Colors.blueAccent,
                    onChanged: (val) {
                      setState(() => _watermarkSettings = _watermarkSettings.copyWith(showMap: val));
                    },
                  ),

                  if (_watermarkSettings.showMap) ...[
                    const Divider(color: Colors.white10, height: 1),
                    
                    // Map Type
                    ListTile(
                      leading: const Icon(Icons.layers, color: Colors.white70),
                      title: const Text('Map Type', style: TextStyle(color: Colors.white)),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(8)),
                        child: DropdownButton<WatermarkMapType>(
                          dropdownColor: Colors.grey[800],
                          value: _watermarkSettings.mapType,
                          style: const TextStyle(color: Colors.white),
                          underline: const SizedBox(),
                          icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                          items: const [
                            DropdownMenuItem(value: WatermarkMapType.normal, child: Text('Normal')),
                            DropdownMenuItem(value: WatermarkMapType.satellite, child: Text('Satellite')),
                            DropdownMenuItem(value: WatermarkMapType.hybrid, child: Text('Hybrid')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _watermarkSettings = _watermarkSettings.copyWith(mapType: val));
                            }
                          },
                        ),
                      ),
                    ),

                    const Divider(color: Colors.white10, height: 1),

                    // Map Alignment
                    ListTile(
                      leading: const Icon(Icons.align_horizontal_left, color: Colors.white70),
                      title: const Text('Map Position', style: TextStyle(color: Colors.white)),
                      trailing: ToggleButtons(
                        isSelected: [
                          _watermarkSettings.mapAlignment == MapAlignment.left,
                          _watermarkSettings.mapAlignment == MapAlignment.right,
                        ],
                        onPressed: (index) {
                          final newAlignment = index == 0 ? MapAlignment.left : MapAlignment.right;
                          setState(() => _watermarkSettings = _watermarkSettings.copyWith(mapAlignment: newAlignment));
                        },
                        color: Colors.grey,
                        selectedColor: Colors.white,
                        fillColor: Colors.blueAccent.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                        constraints: const BoxConstraints(minHeight: 36, minWidth: 60),
                        children: const [Text('Left'), Text('Right')],
                      ),
                    ),
                  ],
                ],
              ),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
