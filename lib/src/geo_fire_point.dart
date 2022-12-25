import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import 'math.dart';

///
class GeoFirePoint {
  GeoFirePoint(this.latitude, this.longitude);

  double latitude;
  double longitude;

  /// Return geohash of [GeoFirePoint].
  String get geohash => encode(latitude: latitude, longitude: longitude);

  /// Return all neighbors of [GeoFirePoint].
  List<String> get neighbors => neighborsOfGeohash(geohash);

  /// Return [GeoPoint] of [GeoFirePoint].
  GeoPoint get geopoint => GeoPoint(latitude, longitude);

  /// Return [Coordinates]  of [GeoFirePoint].
  Coordinates get coordinates => Coordinates(latitude, longitude);

  /// Return distance in kilometers
  /// between [GeoFirePoint] and given ([latitude], [longitude]).
  double distanceBetweenInKm({
    required double latitude,
    required double longitude,
  }) =>
      distanceInKm(
        from: coordinates,
        to: Coordinates(latitude, longitude),
      );

  /// Return [geopoint] and [geohash] as Map<String, dynamic>.
  /// Can be used when adding or updating to Firestore document.
  Map<String, dynamic> get data => {'geopoint': geopoint, 'geohash': geohash};
}

class Coordinates extends Equatable {
  const Coordinates(this.latitude, this.longitude);
  final double latitude;
  final double longitude;

  @override
  List<Object> get props => [latitude, longitude];
}
