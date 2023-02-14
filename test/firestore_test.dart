import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() async {
  final firebaseFirestore = FakeFirebaseFirestore();

  /// add data to FakeFirebaseFirestore
  final geohashs = <String>[
    "a",
    "aaa",
    "aab",
    "aabaaaa",
    "aac",
    "aaz",
    "aba",
    "bbb",
    "efggg",
  ];
  await Future.forEach<String>(geohashs, (geohash) async {
    await firebaseFirestore.collection('geohashs').add({
      'geohash': geohash,
    });
  });

  group('Test startAt and endAt', () {
    test('Test use `~`', () async {
      final snapshot = await firebaseFirestore
          .collection('geohashs')
          .orderBy('geohash')
          .startAt(['aa']).endAt(['aa~']).get();
      final fetchedGeoHashs = snapshot.docs
          .map((queryDocumentSnapshot) =>
              queryDocumentSnapshot.data()['geohash'])
          .toList();

      // unicode assign ~：\u007E、a：\u0061
      // it is able to narrow down because of `a < ~`
      final expectedGeoHashs = <String>[
        "aaa",
        "aab",
        "aabaaaa",
        "aac",
        "aaz",
      ];

      expect(fetchedGeoHashs, expectedGeoHashs);
    });

    test('Test use `{`', () async {
      final snapshot = await firebaseFirestore
          .collection('geohashs')
          .orderBy('geohash')
          .startAt(['aa']).endAt(['aa{']).get();
      final fetchedGeoHashs = snapshot.docs
          .map((queryDocumentSnapshot) =>
              queryDocumentSnapshot.data()['geohash'])
          .toList();

      // unicode assign {：\u007B、a：\u0061
      // it is able to narrow down because of `a < {`
      final expectedGeoHashs = <String>[
        "aaa",
        "aab",
        "aabaaaa",
        "aac",
        "aaz",
      ];
      expect(fetchedGeoHashs, expectedGeoHashs);
    });

    test('Test use `+`', () async {
      final snapshot = await firebaseFirestore
          .collection('geohashs')
          .orderBy('geohash')
          .startAt(['aa']).endAt(['aa+']).get();
      final fetchedGeoHashs = snapshot.docs
          .map((queryDocumentSnapshot) =>
              queryDocumentSnapshot.data()['geohash'])
          .toList();

      // unicode assign +：\u002B、a：\u0061
      // it cannot be narrowed down because of `+ < a`
      final expectedGeoHashs = <String>[];
      expect(fetchedGeoHashs, expectedGeoHashs);
    });

    test('Test specify unicode directly', () async {
      final snapshot =
          await firebaseFirestore.collection('geohashs').orderBy('geohash')
              // \uFFFF is the biggest unicode
              .startAt(['aa']).endAt(['aa\uFFFF']).get();
      final fetchedGeoHashs = snapshot.docs
          .map((queryDocumentSnapshot) =>
              queryDocumentSnapshot.data()['geohash'])
          .toList();

      // unicode assign a：\u0061
      // it is able to narrow down because of `a < \uFFFF`
      final expectedGeoHashs = <String>[
        "aaa",
        "aab",
        "aabaaaa",
        "aac",
        "aaz",
      ];
      expect(fetchedGeoHashs, expectedGeoHashs);
    });
  });
}
