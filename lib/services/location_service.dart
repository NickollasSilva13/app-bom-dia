import 'package:geolocator/geolocator.dart';

import '../domain/weather.dart';
import 'native_bridge.dart';

enum LocationFailure { serviceDisabled, denied, deniedForever, unavailable }

class LocationResult {
  const LocationResult.success(CityLocation this.city) : failure = null;
  const LocationResult.failure(LocationFailure this.failure) : city = null;

  final CityLocation? city;
  final LocationFailure? failure;
}

/// Approximate device location, only to know which city's weather to show.
class LocationService {
  const LocationService({this.bridge = const NativeBridge()});

  final NativeBridge bridge;

  Future<LocationResult> currentCity() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return const LocationResult.failure(LocationFailure.serviceDisabled);
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        return const LocationResult.failure(LocationFailure.deniedForever);
      }
      if (permission == LocationPermission.denied) {
        return const LocationResult.failure(LocationFailure.denied);
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 20),
        ),
      );
      final name = await bridge.reverseGeocode(position.latitude, position.longitude);
      return LocationResult.success(CityLocation(
        name: name ?? '',
        latitude: position.latitude,
        longitude: position.longitude,
      ));
    } catch (_) {
      return const LocationResult.failure(LocationFailure.unavailable);
    }
  }
}
