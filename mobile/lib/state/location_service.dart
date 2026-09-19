import 'package:geolocator/geolocator.dart';

/// Why the device location could not be used.
class LocationFailure implements Exception {
  const LocationFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Wraps geolocator so the app (and tests) can swap it out.
abstract class LocationService {
  /// Returns the current (lat, lng) or throws [LocationFailure].
  Future<({double lat, double lng})> current();
}

class DeviceLocationService implements LocationService {
  const DeviceLocationService();

  @override
  Future<({double lat, double lng})> current() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw const LocationFailure('Location services are turned off.');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw const LocationFailure('Location permission was denied.');
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
      return (lat: pos.latitude, lng: pos.longitude);
    } on LocationFailure {
      rethrow;
    } catch (_) {
      throw const LocationFailure('We could not get a GPS fix.');
    }
  }
}
