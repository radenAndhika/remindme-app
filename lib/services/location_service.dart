import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  static Future<Position?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    
    if (permission == LocationPermission.deniedForever) return null;

    return await Geolocator.getCurrentPosition();
  }

  static Future<String> getAddressFromLatLng(Position pos) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        // Formatting for Indonesian addresses: Street, Sub-district, City, Province
        return "${place.street != null && place.street!.isNotEmpty ? '${place.street}, ' : ''}"
               "${place.subLocality != null && place.subLocality!.isNotEmpty ? '${place.subLocality}, ' : ''}"
               "${place.locality != null && place.locality!.isNotEmpty ? '${place.locality}, ' : ''}"
               "${place.subAdministrativeArea != null && place.subAdministrativeArea!.isNotEmpty ? '${place.subAdministrativeArea}' : ''}";
      }
    } catch (e) {
      return "${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}";
    }
    return "${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}";
  }

  static String formatPosition(Position pos) {
    return '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}';
  }

  static Future<String?> resolveLocationLabel(String rawLocation) async {
    final query = rawLocation.trim();
    if (query.isEmpty) return null;

    try {
      final locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        final first = locations.first;
        final placemarks = await placemarkFromCoordinates(first.latitude, first.longitude);
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          final formatted = [
            place.name,
            place.street,
            place.subLocality,
            place.locality,
            place.subAdministrativeArea,
          ].where((part) => part != null && part!.trim().isNotEmpty).map((part) => part!.trim()).toList();

          if (formatted.isNotEmpty) {
            return formatted.join(', ');
          }
        }
      }
    } catch (_) {
      return query;
    }

    return query;
  }
}
