import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

import 'geo_fire_point.dart';
import 'math.dart';
import 'utils.dart' as utils;

/// Extended cloud_firestore [CollectionReference] for geo query features.
class GeoCollectionReference<T> {
  /// Instantiates [GeoCollectionReference].
  GeoCollectionReference(
    final CollectionReference<T> collectionReference, {
    @visibleForTesting final String rangeQueryEndAtCharacter = '{',
  })  : _collectionReference = collectionReference,
        _rangeQueryEndAtCharacter = rangeQueryEndAtCharacter;

  /// [CollectionReference] of target collection.
  final CollectionReference<T> _collectionReference;

  /// A character added to Firestore string range query endAt.
  /// About Firestore range queries, see:
  /// https://firebase.google.com/docs/database/rest/retrieve-data#section-complex-queries
  final String _rangeQueryEndAtCharacter;

  /// Detection range buffer when not strict mode.
  static const _detectionRangeBuffer = 1.02;

  /// Creates a document with provided [data].
  Future<DocumentReference<T>> add(final T data) =>
      _collectionReference.add(data);

  /// Sets the provided [data] on the document.
  Future<void> set({
    required final String id,
    required final T data,
    final SetOptions? options,
  }) =>
      _collectionReference.doc(id).set(data, options);

  /// Updates the [GeoPoint].data (i.e. [GeoPoint] geopoint and [String]
  /// geohash) of specified document.
  /// If you would like to update not only [GeoPoint].data but also other
  /// fields, use [set] method by setting merge true.
  Future<void> updatePoint({
    required final String id,
    required final String field,
    required final GeoPoint geopoint,
  }) async =>
      _collectionReference.doc(id).update(<String, dynamic>{
        field: GeoFirePoint(geopoint).data,
      });

  /// Deletes the document from the collection.
  Future<void> delete(final String id) => _collectionReference.doc(id).delete();

  /// Subscribes geo query results by given conditions.
  ///
  /// * [center] Center point of detection.
  /// * [radiusInKm] Detection range in kilometers.
  /// * [field] Field name of cloud_firestore document.
  /// * [geopointFrom] Function to get cloud_firestore [GeoPoint] instance from
  /// the object (type T).
  /// * [queryBuilder] Specifies query if you would like to give additional
  /// conditions.
  /// * [strictMode] Whether to filter documents strictly within the bound of
  /// given radius.
  /// * [asBroadcastStream] Whether to return geo query results as broadcast.
  Stream<List<DocumentSnapshot<T>>> subscribeWithin({
    required final GeoFirePoint center,
    required final double radiusInKm,
    required final String field,
    required final GeoPoint Function(T obj) geopointFrom,
    final Query<T>? Function(Query<T> query)? queryBuilder,
    final bool strictMode = false,
    final bool asBroadcastStream = false,
  }) =>
      subscribeWithinWithDistance(
        center: center,
        radiusInKm: radiusInKm,
        field: field,
        geopointFrom: geopointFrom,
        queryBuilder: queryBuilder,
        strictMode: strictMode,
      ).map(
        (final snapshots) => snapshots
            .map((final snapshot) => snapshot.documentSnapshot)
            .toList(),
      );

  /// Subscribes geo query results with distance from center in kilometers
  /// ([GeoDocumentSnapshot]) by given conditions.
  ///
  /// * [center] Center point of detection.
  /// * [radiusInKm] Detection range in kilometers.
  /// * [field] Field name of cloud_firestore document.
  /// * [geopointFrom] Function to get cloud_firestore [GeoPoint] instance from
  /// the object (type T).
  /// * [queryBuilder] Specifies query if you would like to give additional
  /// conditions.
  /// * [strictMode] Whether to filter documents strictly within the bound of
  /// given radius.
  /// * [asBroadcastStream] Whether to return geo query results as broadcast.
  Stream<List<GeoDocumentSnapshot<T>>> subscribeWithinWithDistance({
    required final GeoFirePoint center,
    required final double radiusInKm,
    required final String field,
    required final GeoPoint Function(T obj) geopointFrom,
    final Query<T>? Function(Query<T> query)? queryBuilder,
    final bool strictMode = false,
    final bool asBroadcastStream = false,
  }) {
    final collectionStreams = _collectionStreams(
      center: center,
      radiusInKm: radiusInKm,
      field: field,
      queryBuilder: queryBuilder,
    );

    final mergedCollectionStreams = _mergeCollectionStreams(collectionStreams);

    final filteredGeoDocumentSnapshots =
        mergedCollectionStreams.map((final queryDocumentSnapshots) {
      final geoDocumentSnapshots = queryDocumentSnapshots
          .map(
            (final queryDocumentSnapshot) =>
                _nullableGeoDocumentSnapshotFromQueryDocumentSnapshot(
              queryDocumentSnapshot: queryDocumentSnapshot,
              geopointFrom: geopointFrom,
              center: center,
            ),
          )
          // Removes null values.
          .whereType<GeoDocumentSnapshot<T>>();

      // Filter fetched geoDocumentSnapshots by distance from center point on
      // client side if strict mode.
      final filteredList = geoDocumentSnapshots.where(
        (final geoDocumentSnapshot) =>
            !strictMode ||
            geoDocumentSnapshot.distanceFromCenterInKm <=
                radiusInKm * _detectionRangeBuffer,
      );

      // Returns sorted list by distance from center point.
      return filteredList.toList()
        ..sort(
          (final a, final b) =>
              (a.distanceFromCenterInKm * 1000).toInt() -
              (b.distanceFromCenterInKm * 1000).toInt(),
        );
    });
    if (asBroadcastStream) {
      return filteredGeoDocumentSnapshots.asBroadcastStream();
    }
    return filteredGeoDocumentSnapshots;
  }

  /// Fetches geo query results by given conditions.
  ///
  /// * [center] Center point of detection.
  /// * [radiusInKm] Detection range in kilometers.
  /// * [field] Field name of cloud_firestore document.
  /// * [geohashField] Field name of the geohash in the [field]
  /// * [geopointFrom] Function to get cloud_firestore [GeoPoint] instance from
  /// the object (type T).
  /// * [queryBuilder] Specifies query if you would like to give additional
  /// conditions.
  /// * [strictMode] Whether to filter documents strictly within the bound of
  /// given radius.
  Future<List<DocumentSnapshot<T>>> fetchWithin({
    required final GeoFirePoint center,
    required final double radiusInKm,
    required final String field,
    final String geohashField = 'geohash',
    required final GeoPoint Function(T obj) geopointFrom,
    final Query<T>? Function(Query<T> query)? queryBuilder,
    final bool strictMode = false,
    final bool isCacheFirst = false,
  }) async {
    final geoDocumentSnapshots = await fetchWithinWithDistance(
      center: center,
      radiusInKm: radiusInKm,
      field: field,
      geohashField: geohashField,
      geopointFrom: geopointFrom,
      queryBuilder: queryBuilder,
      strictMode: strictMode,
      isCacheFirst: isCacheFirst,
    );
    return geoDocumentSnapshots
        .map((final snapshot) => snapshot.documentSnapshot)
        .toList();
  }

  /// Fetches geo query results with distance from center in kilometers
  /// ([GeoDocumentSnapshot]) by given conditions.
  ///
  /// * [center] Center point of detection.
  /// * [radiusInKm] Detection range in kilometers.
  /// * [field] Field name of cloud_firestore document.
  /// * [geohashField] Field name of the geohash in the [field]
  /// * [geopointFrom] Function to get cloud_firestore [GeoPoint] instance from
  /// the object (type T).
  /// * [queryBuilder] Specifies query if you would like to give additional
  /// conditions.
  /// * [strictMode] Whether to filter documents strictly within the bound of
  /// given radius.
  Future<List<GeoDocumentSnapshot<T>>> fetchWithinWithDistance({
    required final GeoFirePoint center,
    required final double radiusInKm,
    required final String field,
    final String geohashField = 'geohash',
    required final GeoPoint Function(T obj) geopointFrom,
    final Query<T>? Function(Query<T> query)? queryBuilder,
    final bool strictMode = false,
    final bool isCacheFirst = false,
  }) async {
    final collectionFutures = _collectionFutures(
      center: center,
      radiusInKm: radiusInKm,
      field: field,
      geohashField: geohashField,
      queryBuilder: queryBuilder,
      isCacheFirst: isCacheFirst,
    );

    final mergedCollections = await _mergeCollectionFutures(collectionFutures);

    final geoDocumentSnapshots = mergedCollections
        .map(
          (final queryDocumentSnapshot) =>
              _nullableGeoDocumentSnapshotFromQueryDocumentSnapshot(
            queryDocumentSnapshot: queryDocumentSnapshot,
            geopointFrom: geopointFrom,
            center: center,
          ),
        ) // Removes null values.
        .whereType<GeoDocumentSnapshot<T>>();

    // Filter fetched geoDocumentSnapshots by distance from center point on
    // client side if strict mode.
    final filteredList = geoDocumentSnapshots
        .where(
          (final geoDocumentSnapshot) =>
              !strictMode ||
              geoDocumentSnapshot.distanceFromCenterInKm <=
                  radiusInKm * _detectionRangeBuffer,
        )
        .toList()
      // sort list by distance from center point.
      ..sort(
        (final a, final b) =>
            (a.distanceFromCenterInKm * 1000).toInt() -
            (b.distanceFromCenterInKm * 1000).toInt(),
      );
    return filteredList;
  }

  /// Returns stream of [QueryDocumentSnapshot]s of neighbor and center
  /// Geohashes.
  List<Stream<List<QueryDocumentSnapshot<T>>>> _collectionStreams({
    required final double radiusInKm,
    required final GeoFirePoint center,
    required final String field,
    final String geohashField = 'geohash',
    final Query<T>? Function(Query<T> query)? queryBuilder,
  }) {
    return _geohashes(radiusInKm: radiusInKm, center: center)
        .map(
          (final geohash) => geoQuery(
            field: field,
            geohashField: geohashField,
            geohash: geohash,
            queryBuilder: queryBuilder,
          ).snapshots().map((final querySnapshot) => querySnapshot.docs),
        )
        .toList();
  }

  /// Returns future of [QueryDocumentSnapshot]s of neighbor and center
  /// Geohashes.
  List<Future<List<QueryDocumentSnapshot<T>>>> _collectionFutures({
    required final double radiusInKm,
    required final GeoFirePoint center,
    required final String field,
    required final String geohashField,
    final Query<T>? Function(Query<T> query)? queryBuilder,
    final bool isCacheFirst = false,
  }) {
    return _geohashes(radiusInKm: radiusInKm, center: center).map(
      (final geohash) async {
        late QuerySnapshot<T> querySnapshot;
        final query = geoQuery(
          field: field,
          geohashField: geohashField,
          geohash: geohash,
          queryBuilder: queryBuilder,
        );
        try {
          querySnapshot = await query.get(
            GetOptions(
              source: isCacheFirst ? Source.cache : Source.serverAndCache,
            ),
          );
        } on FirebaseException catch (_) {
          if (isCacheFirst) {
            querySnapshot = await query.get();
          }
        }
        return querySnapshot.docs;
      },
    ).toList();
  }

  /// Returns neighbor and center geohash strings.
  List<String> _geohashes({
    required final double radiusInKm,
    required final GeoFirePoint center,
  }) {
    final precisionDigits = geohashDigitsFromRadius(radiusInKm);
    final centerGeohash = center.geohash.substring(0, precisionDigits);
    return {
      ...utils.neighborGeohashesOf(geohash: centerGeohash),
      centerGeohash,
    }.toList();
  }

  /// Returns geohash query, adding query conditions if queryBuilder parameter
  /// is given.
  @visibleForTesting
  Query<T> geoQuery({
    required final String field,
    final String geohashField = 'geohash',
    required final String geohash,
    final Query<T>? Function(Query<T> query)? queryBuilder,
  }) {
    Query<T> query = _collectionReference;
    if (queryBuilder != null) {
      query = queryBuilder(query)!;
    }
    return query
        .orderBy('$field.$geohashField')
        .startAt([geohash]).endAt(['$geohash$_rangeQueryEndAtCharacter']);
  }

  /// Merge given list of collection streams by `Rx.combineLatest`.
  ///
  /// Note:
  ///
  /// ```dart
  /// final stream1 = Stream.value([1, 2, 3]);
  /// final stream2 = Stream.value([11, 12, 13]);
  /// final streams = [stream1, stream2];
  ///
  /// Rx.combineLatest<List<int>, List<int>>(
  ///   streams,
  ///   (values) => [
  ///     for (final numbers in values) ...numbers,
  ///   ],
  /// ).listen(print);
  ///
  /// // [1, 2, 3, 11, 12, 13]
  /// ```
  Stream<List<QueryDocumentSnapshot<T>>> _mergeCollectionStreams(
    final List<Stream<List<QueryDocumentSnapshot<T>>>> collectionStreams,
  ) =>
      Rx.combineLatest<List<QueryDocumentSnapshot<T>>,
          List<QueryDocumentSnapshot<T>>>(
        collectionStreams,
        (final values) => [
          for (final queryDocumentSnapshots in values)
            ...queryDocumentSnapshots,
        ],
      );

  /// Merge given list of collection futures.
  Future<List<QueryDocumentSnapshot<T>>> _mergeCollectionFutures(
    final List<Future<List<QueryDocumentSnapshot<T>>>> collectionFutures,
  ) async {
    final mergedQueryDocumentSnapshots = <QueryDocumentSnapshot<T>>[];
    await Future.forEach<Future<List<QueryDocumentSnapshot<T>>>>(
        collectionFutures, (final values) async {
      final queryDocumentSnapshots = await values;
      queryDocumentSnapshots.forEach(mergedQueryDocumentSnapshots.add);
    });
    return mergedQueryDocumentSnapshots;
  }

  /// Returns nullable [GeoDocumentSnapshot] from given [QueryDocumentSnapshot].
  GeoDocumentSnapshot<T>?
      _nullableGeoDocumentSnapshotFromQueryDocumentSnapshot({
    required final QueryDocumentSnapshot<T> queryDocumentSnapshot,
    required final GeoPoint Function(T obj) geopointFrom,
    required final GeoFirePoint center,
  }) {
    final exists = queryDocumentSnapshot.exists;
    if (!exists) {
      return null;
    }
    final fetchedData = queryDocumentSnapshot.data();
    final fetchedGeopoint = geopointFrom(fetchedData);
    final distanceFromCenterInKm =
        center.distanceBetweenInKm(geopoint: fetchedGeopoint);
    return GeoDocumentSnapshot(
      documentSnapshot: queryDocumentSnapshot,
      distanceFromCenterInKm: distanceFromCenterInKm,
    );
  }
}

/// A model to handle cloud_firestore [DocumentSnapshot] with distance from
/// given center in kilometers.
class GeoDocumentSnapshot<T> {
  /// Instantiates [GeoDocumentSnapshot].
  GeoDocumentSnapshot({
    required this.documentSnapshot,
    required this.distanceFromCenterInKm,
  });

  /// Fetched [DocumentSnapshot].
  final DocumentSnapshot<T> documentSnapshot;

  /// Distance from center in kilometers.
  final double distanceFromCenterInKm;
}
