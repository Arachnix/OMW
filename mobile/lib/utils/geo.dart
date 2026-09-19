import 'dart:math' as math;

/// Small geometry helpers for campus-scale distances (mirrors
/// src/utils/geo.js on the backend).
class Geo {
  Geo._();

  static const _earthRadius = 6371000.0;

  static double _rad(double d) => d * math.pi / 180;

  /// Great-circle distance in metres.
  static double meters(double lat1, double lng1, double lat2, double lng2) {
    final dLat = _rad(lat2 - lat1);
    final dLng = _rad(lng2 - lng1);
    final a =
        math.pow(math.sin(dLat / 2), 2) +
        math.cos(_rad(lat1)) *
            math.cos(_rad(lat2)) *
            math.pow(math.sin(dLng / 2), 2);
    return 2 * _earthRadius * math.asin(math.sqrt(a));
  }

  /// Walking distance estimate used by the backend (straight line × 1.3).
  static double walkMeters(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) => meters(lat1, lng1, lat2, lng2) * 1.3;

  /// Campus walking speed: 4.5 km/h = 75 m/min.
  static int walkMinutes(double meters) => math.max(1, (meters / 75).round());

  /// Shortest distance in metres from point P to segment A→B, using a local
  /// flat projection (fine at campus scale).
  static double toSegment(
    double pLat,
    double pLng,
    double aLat,
    double aLng,
    double bLat,
    double bLng,
  ) {
    final kx = math.cos(_rad(aLat)) * 111320.0;
    const ky = 110540.0;
    final px = (pLng - aLng) * kx, py = (pLat - aLat) * ky;
    final bx = (bLng - aLng) * kx, by = (bLat - aLat) * ky;
    final len2 = bx * bx + by * by;
    final t = len2 == 0 ? 0.0 : ((px * bx + py * by) / len2).clamp(0.0, 1.0);
    final dx = px - t * bx, dy = py - t * by;
    return math.sqrt(dx * dx + dy * dy);
  }

  /// Initial bearing in degrees from A to B.
  static double bearing(double aLat, double aLng, double bLat, double bLng) {
    final y = math.sin(_rad(bLng - aLng)) * math.cos(_rad(bLat));
    final x =
        math.cos(_rad(aLat)) * math.sin(_rad(bLat)) -
        math.sin(_rad(aLat)) *
            math.cos(_rad(bLat)) *
            math.cos(_rad(bLng - aLng));
    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
  }
}
