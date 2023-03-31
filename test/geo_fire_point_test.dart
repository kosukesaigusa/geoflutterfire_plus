import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';

/// Known geo location dataset for unit test.
class _KnownDataset {
  const _KnownDataset({
    required this.geopoint,
    required this.geohash,
    required this.neighborGeohashes,
  });

  final GeoPoint geopoint;
  final String geohash;
  final List<String> neighborGeohashes;
}

void main() {
  const knownDatasets = <_KnownDataset>[
    _KnownDataset(
      geopoint: GeoPoint(35.681236, 139.767125),
      geohash: 'xn76urx66',
      neighborGeohashes: [
        'xn76urx6d',
        'xn76urx6e',
        'xn76urx67',
        'xn76urx65',
        'xn76urx64',
        'xn76urx61',
        'xn76urx63',
        'xn76urx69',
      ],
    ),
    _KnownDataset(
      geopoint: GeoPoint(35.658034, 139.701636),
      geohash: 'xn76fgreh',
      neighborGeohashes: [
        'xn76fgrek',
        'xn76fgrem',
        'xn76fgrej',
        'xn76fgrdv',
        'xn76fgrdu',
        'xn76fgrdg',
        'xn76fgre5',
        'xn76fgre7',
      ],
    ),
  ];

  group('Test GeoFirePoint.', () {
    test('Test latitude and longitude.', () {
      for (final dataset in knownDatasets) {
        final geoFirePoint = GeoFirePoint(dataset.geopoint);
        expect(geoFirePoint.latitude, dataset.geopoint.latitude);
        expect(geoFirePoint.longitude, dataset.geopoint.longitude);
      }
    });

    test('Test encode geohash with known datasets.', () {
      for (final dataset in knownDatasets) {
        final geoFirePoint = GeoFirePoint(dataset.geopoint);
        expect(geoFirePoint.geohash, dataset.geohash);
      }
    });

    test('Test neighbor geohashes with known datasets.', () {
      for (final dataset in knownDatasets) {
        final geoFirePoint = GeoFirePoint(dataset.geopoint);
        expect(geoFirePoint.neighbors, dataset.neighborGeohashes);
      }
    });

    test('Test distanceBetweenInKm method with known datasets.', () {
      final tokyoStationGeoFirePoint = GeoFirePoint(knownDatasets[0].geopoint);
      expect(
        tokyoStationGeoFirePoint.distanceBetweenInKm(
          geopoint: knownDatasets[1].geopoint,
        ),
        // TODO: Probably need to take presicion into account?
        6.451,
      );
    });

    test('Test GeoFirePoint.data method.', () {
      for (final dataset in knownDatasets) {
        final geoFirePoint = GeoFirePoint(dataset.geopoint);
        expect(geoFirePoint.data, <String, dynamic>{
          'geopoint': geoFirePoint.geopoint,
          'geohash': geoFirePoint.geohash,
        });
      }
    });
  });
}
