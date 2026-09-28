import 'package:flutter_test/flutter_test.dart';
import 'package:native_google_place_picker/native_google_place_picker.dart';
import 'package:native_google_place_picker/native_google_place_picker_platform_interface.dart';
import 'package:native_google_place_picker/native_google_place_picker_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockNativeGooglePlacePickerPlatform
    with MockPlatformInterfaceMixin
    implements NativeGooglePlacePickerPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<Map<String, dynamic>?> openPlacePicker() {
    return Future.value({
      'placeId': 'test_place_id',
      'name': 'Test Place',
      'address': '123 Test Street',
      'lat': 45.5017,
      'lng': -73.5673,
    });
  }
}

void main() {
  final NativeGooglePlacePickerPlatform initialPlatform =
      NativeGooglePlacePickerPlatform.instance;

  test('$MethodChannelNativeGooglePlacePicker is the default instance', () {
    expect(
      initialPlatform,
      isInstanceOf<MethodChannelNativeGooglePlacePicker>(),
    );
  });

  test('getPlatformVersion', () async {
    final nativeGooglePlacePickerPlugin = NativeGooglePlacePicker();
    final fakePlatform = MockNativeGooglePlacePickerPlatform();

    NativeGooglePlacePickerPlatform.instance = fakePlatform;

    expect(
      await nativeGooglePlacePickerPlugin.getPlatformVersion(),
      '42',
    );
  });

  test('openPlacePicker', () async {
    final fakePlatform = MockNativeGooglePlacePickerPlatform();

    NativeGooglePlacePickerPlatform.instance = fakePlatform;

    final result = await NativeGooglePlacePicker.openPlacePicker();

    expect(result, isNotNull);
    expect(result!['placeId'], 'test_place_id');
    expect(result['name'], 'Test Place');
    expect(result['address'], '123 Test Street');
    expect(result['lat'], 45.5017);
    expect(result['lng'], -73.5673);
  });
}