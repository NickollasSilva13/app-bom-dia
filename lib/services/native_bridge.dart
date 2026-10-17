import 'package:flutter/services.dart';

/// Talks to MainActivity.kt over the "bom_dia/native" channel.
class NativeBridge {
  const NativeBridge();

  static const _channel = MethodChannel('bom_dia/native');

  /// Opens WhatsApp (or WhatsApp Business) with the image ready to send.
  /// Returns false when neither is installed or the platform has no handler.
  Future<bool> shareToWhatsApp(String path) async {
    try {
      return await _channel.invokeMethod<bool>('shareToWhatsApp', {'path': path}) ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// City name for the coordinates, from the Android geocoder.
  Future<String?> reverseGeocode(double latitude, double longitude) async {
    try {
      return await _channel.invokeMethod<String>(
        'reverseGeocode',
        {'latitude': latitude, 'longitude': longitude},
      );
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}
