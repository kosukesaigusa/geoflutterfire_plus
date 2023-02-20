import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geoflutterfire_plus/src/geo_collection_reference.dart';

void main() async {
  /// FakeFirebaseFirestore collection reference.
  final fakeCollectionReference =
      FakeFirebaseFirestore().collection('locations');

  /// Geohash strings to be stored, includes invalid characters as geohashes for
  /// testing.
  const geohashes = <String>[
    "a",
    "aaa",
    "aab",
    "aabaaaa",
    "aaz",
    "aa{",
    "aa|",
    "aa}",
    "aa~",
    "aba",
    "bbb",
    "efg",
  ];

  /// A field name of geohashes to be stored.
  const field = 'geo';

  group('GeoCollectionReference.geoQuery', () {
    setUpAll(() async {
      await Future.forEach<String>(geohashes, (geohash) async {
        await fakeCollectionReference.add({
          '$field.geohash': geohash,
        });
      });
    });

    test('fetch geohashes with Firestore startAt, endAt query.', () async {
      final geoCollectionReference =
          GeoCollectionReference(fakeCollectionReference);
      final querySnapshot = await geoCollectionReference
          .geoQuery(field: field, geohash: 'aa')
          .get();
      final fetchedGeohashes = querySnapshot.docs.map((queryDocumentSnapshot) {
        final data = queryDocumentSnapshot.data();
        return (data['geo'] as Map<String, dynamic>)['geohash'] as String;
      }).toList();
      expect(fetchedGeohashes, ["aaa", "aab", "aabaaaa", "aaz", "aa{"]);
    });

    test(
        'fetch geohashes with Firestore startAt, endAt query, '
        'overriding rangeQueryEndAtCharacter parameter', () async {
      final geoCollectionReference = GeoCollectionReference(
        fakeCollectionReference,
        rangeQueryEndAtCharacter: '~',
      );
      final querySnapshot = await geoCollectionReference
          .geoQuery(field: field, geohash: 'aa')
          .get();
      final fetchedGeohashes = querySnapshot.docs.map((queryDocumentSnapshot) {
        final data = queryDocumentSnapshot.data();
        return (data['geo'] as Map<String, dynamic>)['geohash'] as String;
      }).toList();
      expect(
        fetchedGeohashes,
        ["aaa", "aab", "aabaaaa", "aaz", "aa{", "aa|", "aa}", "aa~"],
      );
    });
  });
}
