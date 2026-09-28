import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:native_google_place_picker/native_google_place_picker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Google Place Picker Test',
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: const PlacePickerTestPage(),
    );
  }
}

class PlacePickerTestPage extends StatefulWidget {
  const PlacePickerTestPage({super.key});

  @override
  State<PlacePickerTestPage> createState() => _PlacePickerTestPageState();
}

class _PlacePickerTestPageState extends State<PlacePickerTestPage> {
  Map<String, dynamic>? _selectedPlace;
  String? _errorMessage;
  bool _isOpening = false;

  Future<void> _openGooglePlacePicker() async {
    if (_isOpening) {
      return;
    }

    setState(() {
      _isOpening = true;
      _errorMessage = null;
    });

    try {
      final result = await NativeGooglePlacePicker.openPlacePicker();

      if (!mounted) {
        return;
      }

      setState(() {
        _selectedPlace = result;
      });
    } on PlatformException catch (exception) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage =
            '${exception.code}: ${exception.message ?? 'Unknown error'}';
      });
    } catch (exception) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = exception.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isOpening = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final place = _selectedPlace;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Native Google Places Test'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'ParkKing Native Place Picker',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Tap the button below to open Google\'s native '
                'Place Autocomplete interface.',
              ),
              const SizedBox(height: 24),

              FilledButton(
                onPressed:
                    _isOpening ? null : _openGooglePlacePicker,
                child: Text(
                  _isOpening
                      ? 'Opening...'
                      : 'Open Google Place Picker',
                ),
              ),

              const SizedBox(height: 32),

              if (_errorMessage != null) ...[
                const Text(
                  'Error',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                SelectableText(_errorMessage!),
              ],

              if (place != null) ...[
                const Text(
                  'Selected Place',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                _ResultRow(
                  label: 'Name',
                  value: place['name']?.toString(),
                ),
                _ResultRow(
                  label: 'Address',
                  value: place['address']?.toString(),
                ),
                _ResultRow(
                  label: 'Place ID',
                  value: place['placeId']?.toString(),
                ),
                _ResultRow(
                  label: 'Latitude',
                  value: place['lat']?.toString(),
                ),
                _ResultRow(
                  label: 'Longitude',
                  value: place['lng']?.toString(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          SelectableText(value ?? 'Not returned'),
        ],
      ),
    );
  }
}