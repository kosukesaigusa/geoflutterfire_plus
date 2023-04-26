import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';

void main() {
  final fakeCollectionReference =
      FakeFirebaseFirestore().collection('locations');

  const field = 'geo';

  setUpAll(() async {
    await fakeCollectionReference.add({
      '$field.geohash': 'u0wnvbpjs',
      '$field.geopoint': const GeoPoint(49, 8.7),
      'name': '1',
      'createdAt': FieldValue.serverTimestamp(),
    });
    await fakeCollectionReference.add({
      '$field.geohash': 'u0wnvbpjs',
      '$field.geopoint': const GeoPoint(49, 8.7),
      'name': '2',
      'createdAt': FieldValue.serverTimestamp(),
    });
  });

  group('', () {
    test('test 1', () async {
      final documentSnapshots =
          await GeoCollectionReference(fakeCollectionReference).fetchWithin(
        center: const GeoFirePoint(GeoPoint(49, 8.7)),
        radiusInKm: 100,
        field: field,
        geopointFrom: (final data) =>
            (data[field] as Map<String, dynamic>)['geopoint'] as GeoPoint,
      );
      expect(documentSnapshots.length, 2);
    });

    test('test 2', () async {
      final documentSnapshots =
          await GeoCollectionReference(fakeCollectionReference).fetchWithin(
        center: const GeoFirePoint(GeoPoint(49, 8.7)),
        radiusInKm: 100,
        field: field,
        geopointFrom: (final data) =>
            (data[field] as Map<String, dynamic>)['geopoint'] as GeoPoint,
        queryBuilder: (final query) =>
            query.orderBy('createdAt', descending: true),
      );
      expect(documentSnapshots.length, 2);
    });
  });
}
