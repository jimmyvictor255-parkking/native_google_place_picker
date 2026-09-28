import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'native_google_place_picker_method_channel.dart';

abstract class NativeGooglePlacePickerPlatform extends PlatformInterface {
  /// Constructs a NativeGooglePlacePickerPlatform.
  NativeGooglePlacePickerPlatform() : super(token: _token);

  static final Object _token = Object();

  static NativeGooglePlacePickerPlatform _instance =
      MethodChannelNativeGooglePlacePicker();

  /// The default instance of [NativeGooglePlacePickerPlatform] to use.
  ///
  /// Defaults to [MethodChannelNativeGooglePlacePicker].
  static NativeGooglePlacePickerPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [NativeGooglePlacePickerPlatform]
  /// when they register themselves.
  static set instance(NativeGooglePlacePickerPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError(
      'getPlatformVersion() has not been implemented.',
    );
  }

  Future<Map<String, dynamic>?> openPlacePicker() {
    throw UnimplementedError(
      'openPlacePicker() has not been implemented.',
    );
  }
}