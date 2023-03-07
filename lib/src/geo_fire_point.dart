import 'package:cloud_firestore/cloud_firestore.dart';

import 'math.dart';

/// A model corresponds to Cloud Firestore as geopoint field.
class GeoFirePoint {
  /// Instantiates [GeoFirePoint].
  GeoFirePoint(this.latitude, this.longitude);

  /// Latitude of the location.
  double latitude;

  /// Longitude of the location.
  double longitude;

  /// Returns geohash of [GeoFirePoint].
  String get geohash => encode(latitude: latitude, longitude: longitude);

  /// Returns all neighbors of [GeoFirePoint].
  List<String> get neighbors => neighborsOfGeohash(geohash);

  /// Returns [GeoPoint] of [GeoFirePoint].
  GeoPoint get geopoint => GeoPoint(latitude, longitude);

  /// Returns distance in kilometers between [GeoFirePoint]
  /// and given [geopoint].
  double distanceBetweenInKm({
    required final GeoPoint geopoint,
  }) =>
      distanceInKm(
        geopoint1: this.geopoint,
        geopoint2: geopoint,
      );

  /// Returns [geopoint] and [geohash] as Map<String, dynamic>. Can be used when
  /// adding or updating to Firestore document.
  Map<String, dynamic> get data => {'geopoint': geopoint, 'geohash': geohash};
}
