import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';

import '../geoflutterfire_plus.dart';
import 'utils/math.dart';

/// ドキュメントスナップショットと中心からの距離をまとめたクラス。
class GeoDocumentSnapshot<T> {
  GeoDocumentSnapshot({
    required this.documentSnapshot,
    required this.kilometers,
  });

  ///
  final DocumentSnapshot<T> documentSnapshot;

  ///
  final double kilometers;
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
    required GeoPoint Function(T obj) geoPointFromObject,
    bool strictMode = false,
  }) {
    //
    final nonNullStrictMode = strictMode;

    // int: geoHash の精度（桁数）
    final precision = MathUtils.setPrecision(radius);

    // String: 中心の geoHash
    final centerGeoHash = center.geoHash.substring(0, precision);

    // List<String>: 検出範囲の geoHash 一覧（中心含む）
    final geoHashes = [
      ...GeoFirePoint.neighborsOf(geoHash: centerGeoHash),
      centerGeoHash,
    ];

    // Iterable of
    // geoHash <= x <= geoHash~
    final collectionStreams = geoHashes
        .map(
          (geoHash) => _collectionReference
              .orderBy('$field.geoHash')
              .startAt([geoHash])
              .endAt(['$geoHash~'])
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
        final geoPoint = geoPointFromObject(data);

        // 中心と指定した緯度・経度の点との間の距離 (km)
        final kilometers = center.kilometers(
          lat: geoPoint.latitude,
          lng: geoPoint.longitude,
        );
        return GeoDocumentSnapshot(
          documentSnapshot: queryDocumentSnapshot,
          kilometers: kilometers,
        );
      }).toList();

      final nullableFilteredList = nonNullStrictMode
          ? mappedList.where(
              (doc) =>
                  doc != null &&
                  doc.kilometers <= radius * 1.02, // buffer for edge distances;
            )
          : mappedList;
      return nullableFilteredList.whereType<GeoDocumentSnapshot<T>>().toList()
        ..sort(
          (a, b) =>
              (a.kilometers * 1000).toInt() - (b.kilometers * 1000).toInt(),
        );
    });
    return filtered.asBroadcastStream();
  }
}
