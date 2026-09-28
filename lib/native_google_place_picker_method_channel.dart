import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'native_google_place_picker_platform_interface.dart';

/// An implementation of [NativeGooglePlacePickerPlatform]
/// that uses method channels.
class MethodChannelNativeGooglePlacePicker
    extends NativeGooglePlacePickerPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel =
      const MethodChannel('native_google_place_picker');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }

  @override
  Future<Map<String, dynamic>?> openPlacePicker() async {
    final result = await methodChannel.invokeMapMethod<String, dynamic>(
      'openPlacePicker',
    );

    if (result == null) {
      return null;
    }

    return Map<String, dynamic>.from(result);
  }
}