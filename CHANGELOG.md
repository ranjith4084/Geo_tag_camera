## 1.0.3
* Added `SettingsPage` to allow deep watermark customization (map type, alignment, font style, and positioning).
* Fixed a "red screen" crash that occurred when location permissions were denied by the user.
* Improved camera lifecycle management to properly handle app pauses/resumes during permission requests.
* Enhanced null safety in the camera preview widget.

## 1.0.2
* Updated repository and image URLs to match the GitHub repository rename to `Geo_tag_camera`.

## 1.0.1
* Fixed broken image links in README for better visibility on pub.dev.

## 1.0.0+1

* Initial Release of the `geo_tag_camera` package.
* Added standard `CameraPage` with Tap-to-Focus and Zoom.
* Added `GeoImageWatermark` utility to draw coordinates, street addresses, orientation, and timestamps onto the image via GPU Canvas.
* Added `PermissionService` to easily prompt Location and Camera requirements natively.
* Integrated Dark and Light Watermark themes with configurable positioning.
* Included an `example/` application demonstrating implementation.
