import 'native_google_place_picker_platform_interface.dart';

class NativeGooglePlacePicker {
  Future<String?> getPlatformVersion() {
    return NativeGooglePlacePickerPlatform.instance.getPlatformVersion();
  }

  static Future<Map<String, dynamic>?> openPlacePicker() {
    return NativeGooglePlacePickerPlatform.instance.openPlacePicker();
  }
}