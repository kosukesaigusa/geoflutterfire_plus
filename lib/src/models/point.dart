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
    required Coordinate to,
    required Coordinate from,
  }) =>
      MathUtils.distanceInKilometers(to, from);

  /// return neighboring geo-hashes of [geohash]
  static List<String> neighborsOf({required String geohash}) =>
      _util.neighborsOfGeohash(geohash);

  /// return hash of [GeoFirePoint]
  String get geohash => _util.encode(latitude: latitude, longitude: longitude);

  /// return all neighbors of [GeoFirePoint]
  List<String> get neighbors => _util.neighborsOfGeohash(geohash);

  /// return [GeoPoint] of [GeoFirePoint]
  GeoPoint get geopoint => GeoPoint(latitude, longitude);

  Coordinate get coords => Coordinate(latitude, longitude);

  /// return distance between [GeoFirePoint] and ([lat], [lng])
  double kilometers({
    required double lat,
    required double lng,
  }) =>
      kmDistanceBetween(from: coords, to: Coordinate(lat, lng));

  // TODO: 型を付ける
  Map<String, Object> get data => {'geopoint': geopoint, 'geohash': geohash};

  /// haversine distance between [GeoFirePoint] and ([lat], [lng])
  double haversineDistance({
    required double lat,
    required double lng,
  }) =>
      GeoFirePoint.kmDistanceBetween(
        from: coords,
        to: Coordinate(lat, lng),
      );
}

// TODO: Equatable にする。
class Coordinate {
  Coordinate(this.latitude, this.longitude);
  double latitude;
  double longitude;
}
