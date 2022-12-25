import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';

import '../geoflutterfire_plus.dart';
import 'math.dart';

/// Class to handle cloud_firestore [DocumentSnapshot]
/// with distance from given center in kilometers.
class GeoDocumentSnapshot<T> {
  GeoDocumentSnapshot({
    required this.documentSnapshot,
    required this.distanceFromCenterInKm,
  });

  /// Fetched [DocumentSnapshot].
  final DocumentSnapshot<T> documentSnapshot;

  /// Distance from center in kilometers.
  final double distanceFromCenterInKm;
}

class GeoCollectionRef<T> {
  GeoCollectionRef(this._collectionReference);

  /// Typed [Query] of target collection.
  final Query<T> _collectionReference;

  /// Detection range buffer when not strict mode.
  static const _detectionRangeBuffer = 1.02;

  /// Notifies of geo query results by given condition.
  ///
  /// - [center] Center point of detection.
  /// - [radiusInKm] Detection range in kilometers.
  /// - [strictMode] Whether to filter documents strictly within
  /// the bound of given radius.
  Stream<List<GeoDocumentSnapshot<T>>> within({
    required GeoFirePoint center,
    required double radiusInKm,
    required String field,
    required GeoPoint Function(T obj) geopointFromObject,
    bool strictMode = false,
  }) {
    final precisionDigits = geohashDigitsFromRadius(radiusInKm);
    final centerGeoHash = center.geohash.substring(0, precisionDigits);
    final geohashes = [
      ...neighborGeohashesOf(geohash: centerGeoHash),
      centerGeoHash,
    ];

    final collectionStreams = geohashes
        .map(
          (geohash) => _collectionReference
              .orderBy('$field.geohash')
              .startAt([geohash])
              .endAt(['$geohash~'])
              .snapshots()
              .map((querySnapshot) => querySnapshot.docs),
        )
        .toList();

    final mergedCollectionStreams = Rx.combineLatest(
      collectionStreams,
      (values) => [
        for (final queryDocumentSnapshots in values) ...queryDocumentSnapshots,
      ],
    );

    final filtered = mergedCollectionStreams.map((queryDocumentSnapshots) {
      final mappedList = queryDocumentSnapshots.map((queryDocumentSnapshot) {
        final exists = queryDocumentSnapshot.exists;
        if (!exists) {
          return null;
        }
        final fetchedData = queryDocumentSnapshot.data();
        final fetchedGeopoint = geopointFromObject(fetchedData);
        final distanceFromCenterInKm = center.distanceBetweenInKm(
          latitude: fetchedGeopoint.latitude,
          longitude: fetchedGeopoint.longitude,
        );

        return GeoDocumentSnapshot(
          documentSnapshot: queryDocumentSnapshot,
          distanceFromCenterInKm: distanceFromCenterInKm,
        );
      }).toList();

      final nullableFilteredList = strictMode
          ? mappedList.where(
              (doc) =>
                  doc != null &&
                  doc.distanceFromCenterInKm <=
                      radiusInKm * _detectionRangeBuffer,
            )
          : mappedList;
      return nullableFilteredList.whereType<GeoDocumentSnapshot<T>>().toList()
        ..sort(
          (a, b) =>
              (a.distanceFromCenterInKm * 1000).toInt() -
              (b.distanceFromCenterInKm * 1000).toInt(),
        );
    });
    return filtered.asBroadcastStream();
  }
}
