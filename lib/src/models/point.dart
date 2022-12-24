import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/math.dart';

class GeoFirePoint {
  GeoFirePoint({
    required this.latitude,
    required this.longitude,
  });

  static final MathUtils _util = MathUtils();
  double latitude;
  double longitude;

  /// return geographical distance between two Co-ordinates
  static double kmDistanceBetween({
    required Coordinates to,
    required Coordinates from,
  }) =>
      MathUtils.kmDistance(to, from);

  /// return neighboring geo-hashes of [geoHash]
  static List<String> neighborsOf({required String geoHash}) =>
      _util.neighbors(geoHash);

  /// return hash of [GeoFirePoint]
  String get geoHash => _util.encode(latitude: latitude, longitude: longitude);

  /// return all neighbors of [GeoFirePoint]
  List<String> get neighbors => _util.neighbors(geoHash);

  /// return [GeoPoint] of [GeoFirePoint]
  GeoPoint get geoPoint => GeoPoint(latitude, longitude);

  Coordinates get coords => Coordinates(latitude, longitude);

  /// return distance between [GeoFirePoint] and ([lat], [lng])
  double kilometers({
    required double lat,
    required double lng,
  }) =>
      kmDistanceBetween(from: coords, to: Coordinates(lat, lng));

  Map<String, Object> get data => {'geopoint': geoPoint, 'geohash': hash};

  /// haversine distance between [GeoFirePoint] and ([lat], [lng])
  double haversineDistance({
    required double lat,
    required double lng,
  }) =>
      GeoFirePoint.kmDistanceBetween(
        from: coords,
        to: Coordinates(lat, lng),
      );
}

// TODO: Equatable にする。
class Coordinates {
  Coordinates(this.latitude, this.longitude);
  double latitude;
  double longitude;
}
