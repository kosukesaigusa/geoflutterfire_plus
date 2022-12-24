import 'dart:math';

import '../models/point.dart';

class MathUtils {
  MathUtils() {
    _initialize();
  }

  ///
  static const _base32Codes = '0123456789bcdefghjkmnpqrstuvwxyz';

  // The equatorial radius of the earth in meters
  static const double _earthEqRadius = 6378137;

  // The meridional radius of the earth in meters
  static const double _earthPolarRadius = 6357852.3;

  ///
  final _base32CodesDic = <String, int>{};

  ///
  void _initialize() {
    for (var i = 0; i < _base32Codes.length; i++) {
      _base32CodesDic.putIfAbsent(_base32Codes[i], () => i);
    }
  }

  /// Return geohash String from [latitude] and [longitude],
  /// whose length is equal to [geohashLength].
  String encode({
    required double latitude,
    required double longitude,
    int geohashLength = 9,
  }) {
    final characters = <String>[];
    var bits = 0;
    var bitsTotal = 0;
    var hashValue = 0;
    var maxLatitude = 90.0;
    var minLatitude = -90.0;
    var maxLongitude = 180.0;
    var minLongitude = -180.0;

    while (characters.length < geohashLength) {
      if (bitsTotal.isEven) {
        final middle = (maxLongitude + minLongitude) / 2;
        if (longitude > middle) {
          hashValue = (hashValue << 1) + 1;
          minLongitude = middle;
        } else {
          hashValue = (hashValue << 1) + 0;
          maxLongitude = middle;
        }
      } else {
        final middle = (maxLatitude + minLatitude) / 2;
        if (latitude > middle) {
          hashValue = (hashValue << 1) + 1;
          minLatitude = middle;
        } else {
          hashValue = (hashValue << 1) + 0;
          maxLatitude = middle;
        }
      }

      bits++;
      bitsTotal++;
      if (bits == 5) {
        final code = _base32Codes[hashValue];
        characters.add(code);
        bits = 0;
        hashValue = 0;
      }
    }
    return characters.join();
  }

  ///
  /// Decode a [geohash] into a pair of latitude and longitude.
  /// A map is returned with keys 'latitude', 'longitude','latitudeError','longitudeError'
  LatLngWithErrors decode(String geohash) {
    final bbox = _decodeBbox(geohash);
    final latitude = (bbox[0] + bbox[2]) / 2;
    final longitude = (bbox[1] + bbox[3]) / 2;
    final latitudeError = bbox[2] - latitude;
    final longitudeError = bbox[3] - longitude;
    return LatLngWithErrors(
      latitude: latitude,
      longitude: longitude,
      latitudeError: latitudeError,
      longitudeError: longitudeError,
    );
  }

  ///
  /// Decode Bounding box
  ///
  /// Decode a hashString into a bound box that matches it.
  /// Data returned in a List [minLatitude, minLongitude, maxLatitude, maxLongitude]
  List<double> _decodeBbox(String geohash) {
    var isLongitude = true;
    var maxLatitude = 90.0;
    var minLatitude = -90.0;
    var maxLongitude = 180.0;
    var minLongitude = -180.0;

    for (var i = 0, l = geohash.length; i < l; i++) {
      final code = geohash[i].toLowerCase();
      final hashValue = _base32CodesDic[code];
      for (var bits = 4; bits >= 0; bits--) {
        final bit = (hashValue! >> bits) & 1;
        if (isLongitude) {
          final middle = (maxLongitude + minLongitude) / 2;
          if (bit == 1) {
            minLongitude = middle;
          } else {
            maxLongitude = middle;
          }
        } else {
          final middle = (maxLatitude + minLatitude) / 2;
          if (bit == 1) {
            minLatitude = middle;
          } else {
            maxLatitude = middle;
          }
        }
        isLongitude = !isLongitude;
      }
    }
    return [minLatitude, minLongitude, maxLatitude, maxLongitude];
  }

  /// Return all neighbors' geohash strings of given [geohash] clockwise,
  /// in the following order, north, east, south, and then west.
  List<String> neighborsOfGeohash(String geohash) {
    final latLngWithErrors = decode(geohash);
    return [
      _encodeNeighbor(
        latLngWithErrors: latLngWithErrors,
        geohash: geohash,
        neighborLatDir: 1,
        neighborLonDir: 0,
      ),
      _encodeNeighbor(
        latLngWithErrors: latLngWithErrors,
        geohash: geohash,
        neighborLatDir: 1,
        neighborLonDir: 1,
      ),
      _encodeNeighbor(
        latLngWithErrors: latLngWithErrors,
        geohash: geohash,
        neighborLatDir: 0,
        neighborLonDir: 1,
      ),
      _encodeNeighbor(
        latLngWithErrors: latLngWithErrors,
        geohash: geohash,
        neighborLatDir: -1,
        neighborLonDir: 1,
      ),
      _encodeNeighbor(
        latLngWithErrors: latLngWithErrors,
        geohash: geohash,
        neighborLatDir: -1,
        neighborLonDir: 0,
      ),
      _encodeNeighbor(
        latLngWithErrors: latLngWithErrors,
        geohash: geohash,
        neighborLatDir: -1,
        neighborLonDir: -1,
      ),
      _encodeNeighbor(
        latLngWithErrors: latLngWithErrors,
        geohash: geohash,
        neighborLatDir: 0,
        neighborLonDir: -1,
      ),
      _encodeNeighbor(
        latLngWithErrors: latLngWithErrors,
        geohash: geohash,
        neighborLatDir: 1,
        neighborLonDir: -1,
      )
    ];
  }

  ///
  String _encodeNeighbor({
    required LatLngWithErrors latLngWithErrors,
    required String geohash,
    required double neighborLatDir,
    required double neighborLonDir,
  }) =>
      encode(
        latitude: latLngWithErrors.latitude +
            neighborLatDir * latLngWithErrors.latitudeError * 2,
        longitude: latLngWithErrors.longitude +
            neighborLonDir * latLngWithErrors.longitudeError * 2,
        geohashLength: geohash.length,
      );

  /// Return geohash digits from [radius] in kilometers,
  /// which decide how precisely detect neighbors.
  ///
  /// * 1	≤ 5,000km	×	5,000km
  /// * 2	≤ 1,250km	×	625km
  /// * 3	≤ 156km	×	156km
  /// * 4	≤ 39.1km	×	19.5km
  /// * 5	≤ 4.89km	×	4.89km
  /// * 6	≤ 1.22km	×	0.61km
  /// * 7	≤ 153m	×	153m
  /// * 8	≤ 38.2m	×	19.1m
  /// * 9	≤ 4.77m	×	4.77m
  static int geohashDigitsFromRadius(double radius) {
    if (radius <= 0.00477) {
      return 9;
    } else if (radius <= 0.0382) {
      return 8;
    } else if (radius <= 0.153) {
      return 7;
    } else if (radius <= 1.22) {
      return 6;
    } else if (radius <= 4.89) {
      return 5;
    } else if (radius <= 39.1) {
      return 4;
    } else if (radius <= 156) {
      return 3;
    } else if (radius <= 1250) {
      return 2;
    } else {
      return 1;
    }
  }

  /// Returns distance between [to] and [from] in kilometers.
  static double distanceInKilometers(
    Coordinate to,
    Coordinate from,
  ) {
    final latitude1 = to.latitude;
    final longitude1 = to.longitude;
    final latitude2 = from.latitude;
    final longitude2 = from.longitude;

    // Earth's mean radius in meters
    const radius = (_earthEqRadius + _earthPolarRadius) / 2;
    final latDelta = _toRadians(latitude1 - latitude2);
    final lonDelta = _toRadians(longitude1 - longitude2);

    final a = (sin(latDelta / 2) * sin(latDelta / 2)) +
        (cos(_toRadians(latitude1)) *
            cos(_toRadians(latitude2)) *
            sin(lonDelta / 2) *
            sin(lonDelta / 2));
    final distance = radius * 2 * atan2(sqrt(a), sqrt(1 - a)) / 1000;
    return double.parse(distance.toStringAsFixed(3));
  }

  static double _toRadians(double num) => num * (pi / 180.0);
}

/// TODO: Equatable にする
class LatLngWithErrors {
  LatLngWithErrors({
    required this.latitude,
    required this.longitude,
    required this.latitudeError,
    required this.longitudeError,
  });

  final double latitude;
  final double longitude;
  final double latitudeError;
  final double longitudeError;
}
