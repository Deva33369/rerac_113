import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class MapUtils {
  static LatLngBounds boundsFromLatLngList(List<LatLng> list) {
    double? x0, x1, y0, y1;
    for (LatLng latLng in list) {
      if (x0 == null) {
        x0 = x1 = latLng.latitude;
        y0 = y1 = latLng.longitude;
      } else {
        if (latLng.latitude > x1!) x1 = latLng.latitude;
        if (latLng.latitude < x0) x0 = latLng.latitude;
        if (latLng.longitude > y1!) y1 = latLng.longitude;
        if (latLng.longitude < y0!) y0 = latLng.longitude;
      }
    }
    return LatLngBounds(
        northeast: LatLng(x1! + 1, y1! + 1),
        southwest: LatLng(x0! - 1, y0! - 1));
  }

  static Future<void> openMap(
    double latitude,
    double longtitude,
  ) async {
    final Uri launchmaps = Uri.parse(
        "https://www.google.com/maps/search/?api=1&query=$latitude,$longtitude");

    if (await canLaunchUrl(launchmaps)) {
      await launchUrl(launchmaps);
    }
  }
}
