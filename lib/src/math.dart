import 'dart:math';

import 'package:equatable/equatable.dart';

import 'geo_fire_point.dart';

/// 32 codes to use aas Base32.
const _base32Codes = '0123456789bcdefghjkmnpqrstuvwxyz';

/// Base 32 codes map.
const _base32CodesMap = <String, int>{
  '0': 0,
  '1': 1,
  '2': 2,
  '3': 3,
  '4': 4,
  '5': 5,
  '6': 6,
  '7': 7,
  '8': 8,
  '9': 9,
  'b': 10,
  'c': 11,
  'd': 12,
  'e': 13,
  'f': 14,
  'g': 15,
  'h': 16,
  'j': 17,
  'k': 18,
  'm': 19,
  'n': 20,
  'p': 21,
  'q': 22,
  'r': 23,
  's': 24,
  't': 25,
  'u': 26,
  'v': 27,
  'w': 28,
  'x': 29,
  'y': 30,
  'z': 31,
};

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

/// Decode a [geohash] string into [_CoordinatesWithErrors].
/// It includes 'latitude', 'longitude', 'latitudeError', 'longitudeError'.
_CoordinatesWithErrors _decode(String geohash) {
  final boundingBox = _decodedBoundingBox(geohash);
  final latitude = (boundingBox.minLatitude + boundingBox.maxLatitude) / 2;
  final longitude = (boundingBox.minLongitude + boundingBox.maxLongitude) / 2;
  final latitudeError = boundingBox.maxLatitude - latitude;
  final longitudeError = boundingBox.maxLongitude - longitude;
  return _CoordinatesWithErrors(
    latitude: latitude,
    longitude: longitude,
    latitudeError: latitudeError,
    longitudeError: longitudeError,
  );
}

/// Decode a hashString into a bounding box that matches it.
_DecodedBoundingBox _decodedBoundingBox(String geohash) {
  var isLongitude = true;
  var maxLatitude = 90.0;
  var minLatitude = -90.0;
  var maxLongitude = 180.0;
  var minLongitude = -180.0;
  for (var i = 0; i < geohash.length; i++) {
    final code = geohash[i].toLowerCase();
    final hashValue = _base32CodesMap[code];
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
  return _DecodedBoundingBox(
    minLatitude: minLatitude,
    minLongitude: minLongitude,
    maxLatitude: maxLatitude,
    maxLongitude: maxLongitude,
  );
}

/// Return all neighbors' geohash strings of given [geohash] clockwise,
/// in the following order, north, east, south, and then west.
List<String> neighborsOfGeohash(String geohash) {
  final coordinatesWithErrors = _decode(geohash);
  return [
    _encodeNeighbor(
      coordinatesWithErrors: coordinatesWithErrors,
      geohash: geohash,
      neighborLatitudeDirection: 1,
      neighborLongitudeDirection: 0,
    ),
    _encodeNeighbor(
      coordinatesWithErrors: coordinatesWithErrors,
      geohash: geohash,
      neighborLatitudeDirection: 1,
      neighborLongitudeDirection: 1,
    ),
    _encodeNeighbor(
      coordinatesWithErrors: coordinatesWithErrors,
      geohash: geohash,
      neighborLatitudeDirection: 0,
      neighborLongitudeDirection: 1,
    ),
    _encodeNeighbor(
      coordinatesWithErrors: coordinatesWithErrors,
      geohash: geohash,
      neighborLatitudeDirection: -1,
      neighborLongitudeDirection: 1,
    ),
    _encodeNeighbor(
      coordinatesWithErrors: coordinatesWithErrors,
      geohash: geohash,
      neighborLatitudeDirection: -1,
      neighborLongitudeDirection: 0,
    ),
    _encodeNeighbor(
      coordinatesWithErrors: coordinatesWithErrors,
      geohash: geohash,
      neighborLatitudeDirection: -1,
      neighborLongitudeDirection: -1,
    ),
    _encodeNeighbor(
      coordinatesWithErrors: coordinatesWithErrors,
      geohash: geohash,
      neighborLatitudeDirection: 0,
      neighborLongitudeDirection: -1,
    ),
    _encodeNeighbor(
      coordinatesWithErrors: coordinatesWithErrors,
      geohash: geohash,
      neighborLatitudeDirection: 1,
      neighborLongitudeDirection: -1,
    )
  ];
}

/// Return neighbor geohash of given [coordinatesWithErrors].
String _encodeNeighbor({
  required _CoordinatesWithErrors coordinatesWithErrors,
  required String geohash,
  required double neighborLatitudeDirection,
  required double neighborLongitudeDirection,
}) =>
    encode(
      latitude: coordinatesWithErrors.latitude +
          neighborLatitudeDirection * coordinatesWithErrors.latitudeError * 2,
      longitude: coordinatesWithErrors.longitude +
          neighborLongitudeDirection * coordinatesWithErrors.longitudeError * 2,
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
int geohashDigitsFromRadius(double radius) {
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

/// The equatorial radius of the earth in meters.
const double _earthEqRadius = 6378137;

/// The meridional radius of the earth in meters.
const double _earthPolarRadius = 6357852.3;

/// Returns distance between [to] and [from] in kilometers.
double distanceInKm({
  required Coordinates from,
  required Coordinates to,
}) {
  const radius = (_earthEqRadius + _earthPolarRadius) / 2;
  final latDelta = _toRadians(to.latitude - from.latitude);
  final lonDelta = _toRadians(to.longitude - from.longitude);

  final a = (sin(latDelta / 2) * sin(latDelta / 2)) +
      (cos(_toRadians(to.latitude)) *
          cos(_toRadians(from.latitude)) *
          sin(lonDelta / 2) *
          sin(lonDelta / 2));
  final distance = radius * 2 * atan2(sqrt(a), sqrt(1 - a)) / 1000;
  return double.parse(distance.toStringAsFixed(3));
}

double _toRadians(double num) => num * (pi / 180.0);

class _DecodedBoundingBox extends Equatable {
  const _DecodedBoundingBox({
    required this.minLatitude,
    required this.minLongitude,
    required this.maxLatitude,
    required this.maxLongitude,
  });

  final double minLatitude;
  final double minLongitude;
  final double maxLatitude;
  final double maxLongitude;

  @override
  List<Object> get props =>
      [minLatitude, minLongitude, maxLatitude, maxLongitude];
}

/// Coordinates ([latitude], [longitude])
/// with each errors ([latitudeError], [longitudeError]).
class _CoordinatesWithErrors extends Equatable {
  const _CoordinatesWithErrors({
    required this.latitude,
    required this.longitude,
    required this.latitudeError,
    required this.longitudeError,
  });

  final double latitude;
  final double longitude;
  final double latitudeError;
  final double longitudeError;

  @override
  List<Object> get props =>
      [latitude, longitude, latitudeError, longitudeError];
}
