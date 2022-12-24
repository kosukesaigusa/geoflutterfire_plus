import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import '../math.dart';

///
class GeoFirePoint {
  GeoFirePoint(
    this.latitude,
    this.longitude,
  );

  static final MathUtils _util = MathUtils();
  double latitude;
  double longitude;

  /// Return geohash of [GeoFirePoint].
  String get geohash => _util.encode(latitude: latitude, longitude: longitude);

  /// return all neighbors of [GeoFirePoint]
  List<String> get neighbors => _util.neighborsOfGeohash(geohash);

  /// return [GeoPoint] of [GeoFirePoint]
  GeoPoint get geopoint => GeoPoint(latitude, longitude);

  ///
  Coordinates get coordinates => Coordinates(latitude, longitude);

  /// return distance between [GeoFirePoint] and given ([latitude], [longitude])
  double distanceBetweenInKm({
    required double latitude,
    required double longitude,
  }) =>
      MathUtils.distanceInKm(
        from: coordinates,
        to: Coordinates(latitude, longitude),
      );

  // TODO: 型を付ける
  Map<String, Object> get data => {'geopoint': geopoint, 'geohash': geohash};

  /// haversine distance between [GeoFirePoint] and given ([lat], [lng])
  double haversineDistance({
    required double lat,
    required double lng,
  }) =>
      MathUtils.distanceInKm(
        from: coordinates,
        to: Coordinates(lat, lng),
      );
}

class Coordinates extends Equatable {
  const Coordinates(this.latitude, this.longitude);
  final double latitude;
  final double longitude;

  @override
  List<Object> get props => [latitude, longitude];
}
