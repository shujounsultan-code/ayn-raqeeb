import 'location_service_io.dart' if (dart.library.html) 'location_service_web.dart';

abstract class LocationService {
  static Future<LatLng?> getCurrentLocation() async {
    return getLocationService().getCurrentLocation();
  }

  static Stream<LatLng> getLocationStream() {
    return getLocationService().getLocationStream();
  }

  static Future<bool> isLocationServiceEnabled() async {
    return getLocationService().isLocationServiceEnabled();
  }

  static Future<LocationPermissionStatus> requestPermission() async {
    return getLocationService().requestPermission();
  }

  static LocationServiceInterface getLocationService() {
    return LocationServiceImpl();
  }
}

enum LocationPermissionStatus {
  granted,
  denied,
  deniedForever,
  notDetermined,
}

abstract class LocationServiceInterface {
  Future<LatLng?> getCurrentLocation();
  Stream<LatLng> getLocationStream();
  Future<bool> isLocationServiceEnabled();
  Future<LocationPermissionStatus> requestPermission();
}

class LocationServiceImpl implements LocationServiceInterface {
  @override
  Future<LatLng?> getCurrentLocation() async {
    return getLocationServicePlatform().getCurrentLocation();
  }

  @override
  Stream<LatLng> getLocationStream() {
    return getLocationServicePlatform().getLocationStream();
  }

  @override
  Future<bool> isLocationServiceEnabled() async {
    return getLocationServicePlatform().isLocationServiceEnabled();
  }

  @override
  Future<LocationPermissionStatus> requestPermission() async {
    return getLocationServicePlatform().requestPermission();
  }

  LocationServiceInterface getLocationServicePlatform() {
    return LocationServicePlatform();
  }
}
