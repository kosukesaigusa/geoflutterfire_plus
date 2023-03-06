import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geoflutterfire_plus/src/math.dart';

void main() {
  test('Test encode method by known datasets', () {
    final knownDatasets = <GeoPoint, String>{
      // Tokyo Station
      const GeoPoint(35.681236, 139.767125): 'xn76urx66',
      // Shibuya Station
      const GeoPoint(35.658034, 139.701636): 'xn76fgreh',
    };
    for (final dataset in knownDatasets.entries) {
      final geohash = encode(
        latitude: dataset.key.latitude,
        longitude: dataset.key.longitude,
      );
      expect(geohash, dataset.value);
    }
  });
}
