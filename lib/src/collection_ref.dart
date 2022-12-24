import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';

import '../geoflutterfire_plus.dart';
import 'math.dart';

/// ドキュメントスナップショットと中心からの距離をまとめたクラス。
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

///
class GeoCollectionRef<T> {
  GeoCollectionRef(this._collectionReference);

  ///
  final Query<T> _collectionReference;

  Stream<List<GeoDocumentSnapshot<T>>> within({
    required GeoFirePoint center,
    required double radius,
    required String field,
    required GeoPoint Function(T obj) geopointFromObject,
    // TODO: strictMode の説明を書く
    bool strictMode = false,
  }) {
    // int: geohash の精度（桁数）
    final precision = MathUtils.geohashDigitsFromRadius(radius);

    // String: 中心の geohash
    final centerGeoHash = center.geohash.substring(0, precision);

    // List<String>: 検出範囲の geohash 一覧（中心含む）
    final geohashes = [
      ...GeoFlutterFireUtil.neighborGeohashesOf(geohash: centerGeoHash),
      centerGeoHash,
    ];

    // Iterable of
    // geohash <= x <= geohash~
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

    // ここが何をやっているのかわからない
    // 指定された複数の Stream (List<Stream>) を、第 2 引数の combiner 関数によって
    // ひとつの Stream にまとめている
    final mergedCollectionStreams = Rx.combineLatest(
      collectionStreams,
      (values) => [
        for (final queryDocumentSnapshots in values) ...queryDocumentSnapshots,
      ],
    );

    // Stream<List<DistanceDocSnapshot<T>>>
    final filtered = mergedCollectionStreams.map((queryDocumentSnapshots) {
      final mappedList = queryDocumentSnapshots.map((queryDocumentSnapshot) {
        final exists = queryDocumentSnapshot.exists;
        if (!exists) {
          return null;
        }
        final data = queryDocumentSnapshot.data();
        final geopoint = geopointFromObject(data);

        // 中心と指定した緯度・経度の点との間の距離 (km)
        final kilometers = center.distanceBetweenInKm(
          latitude: geopoint.latitude,
          longitude: geopoint.longitude,
        );

        return GeoDocumentSnapshot(
          documentSnapshot: queryDocumentSnapshot,
          distanceFromCenterInKm: kilometers,
        );
      }).toList();

      final nullableFilteredList = strictMode
          ? mappedList.where(
              (doc) =>
                  doc != null &&
                  doc.distanceFromCenterInKm <=
                      radius * 1.02, // buffer for edge distances;
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
