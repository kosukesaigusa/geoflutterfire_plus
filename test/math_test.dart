import 'package:flutter_test/flutter_test.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import 'package:geoflutterfire_plus/src/math.dart';

void main() {
  test('Test encode method by known datasets', () {
    final knownDatasets = <Coordinates, String>{
      // Tokyo Station
      const Coordinates(35.681236, 139.767125): 'xn76urx66',
      // Shibuya Station
      const Coordinates(35.658034, 139.701636): 'xn76fgreh',
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
