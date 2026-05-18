import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';

class GeocodingService {
  /// Converts a postal code to LatLng coordinates using Nominatim (OpenStreetMap)
  static Future<LatLng?> postalCodeToLatLng(String postalCode) async {
    try {
      debugPrint('GeocodingService: البحث عن الرمز البريدي: $postalCode');

      final headers = {
        'User-Agent': 'ayn_raqeeb_app/1.0 (support@ayn-raqeeb.app)',
        'Accept-Language': 'ar',
      };

      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'postalcode': postalCode,
        'country': 'SA',
        'format': 'json',
        'limit': '1',
      });

      var response = await http.get(uri, headers: headers);
      debugPrint('GeocodingService: Status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        debugPrint('GeocodingService: عدد النتائج: ${data.length}');
        if (data.isNotEmpty) {
          final lat = double.tryParse(data[0]['lat']?.toString() ?? '');
          final lon = double.tryParse(data[0]['lon']?.toString() ?? '');
          debugPrint('GeocodingService: lat=$lat, lon=$lon');
          if (lat != null && lon != null) {
            return LatLng(lat, lon);
          }
        } else {
          debugPrint('GeocodingService: لا توجد نتائج للرمز البريدي $postalCode');
        }
      } else {
        debugPrint('GeocodingService: فشل الاتصال بـ OpenStreetMap (${response.statusCode})');
      }

      // Fallback search by query if postal code-specific search returns nothing.
      final fallbackUri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': '$postalCode Saudi Arabia',
        'format': 'json',
        'limit': '1',
      });
      debugPrint('GeocodingService: محاولة fallback للرمز البريدي: $postalCode');
      response = await http.get(fallbackUri, headers: headers);
      debugPrint('GeocodingService: Status code fallback: ${response.statusCode}');
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        debugPrint('GeocodingService: عدد نتائج fallback: ${data.length}');
        if (data.isNotEmpty) {
          final lat = double.tryParse(data[0]['lat']?.toString() ?? '');
          final lon = double.tryParse(data[0]['lon']?.toString() ?? '');
          debugPrint('GeocodingService: fallback lat=$lat, lon=$lon');
          if (lat != null && lon != null) {
            return LatLng(lat, lon);
          }
        }
      }

      return null;
    } catch (e) {
      debugPrint('GeocodingService: خطأ: $e');
      return null;
    }
  }
}
