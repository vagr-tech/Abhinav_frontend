// ignore_for_file: avoid_print

import 'dart:typed_data';

class ExifHelper {
  /// Extract EXIF GPS manually (no dependency)
  static Map<String, double?> extractGPS(Uint8List bytes) {
    try {
      String data = String.fromCharCodes(bytes);

      // GPSLatitude
      RegExp latExp = RegExp(r"GPSLatitude[^0-9]*([0-9./, ]+)");
      RegExp lngExp = RegExp(r"GPSLongitude[^0-9]*([0-9./, ]+)");

      var latMatch = latExp.firstMatch(data);
      var lngMatch = lngExp.firstMatch(data);

      if (latMatch == null || lngMatch == null) {
        return {"lat": null, "lng": null};
      }

      List<String> latParts = latMatch.group(1)!.split(",");
      List<String> lngParts = lngMatch.group(1)!.split(",");

      double dmsToDecimal(List<String> dms) {
        double d = double.parse(dms[0]);
        double m = double.parse(dms[1]);
        double s = double.parse(dms[2]);
        return d + (m / 60) + (s / 3600);
      }

      double lat = dmsToDecimal(latParts);
      double lng = dmsToDecimal(lngParts);

      return {"lat": lat, "lng": lng};
    } catch (e) {
      print("EXIF parse error $e");
      return {"lat": null, "lng": null};
    }
  }
}
