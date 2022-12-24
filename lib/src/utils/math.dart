import 'dart:math';

import '../models/point.dart';

class MathUtils {
  MathUtils() {
    for (var i = 0; i < _base32Codes.length; i++) {
      _base32CodesDic.putIfAbsent(_base32Codes[i], () => i);
    }
  }
  static const _base32Codes = '0123456789bcdefghjkmnpqrstuvwxyz';
  final _base32CodesDic = <String, int>{};

  ///
  /// Encode
  /// Create a geohash from latitude and longitude
  /// that is 'number of chars' long
  String encode({
    required double latitude,
    required double longitude,
    int numberOfChars = 9,
  }) {
    final chars = <String>[];
    var bits = 0;
    var bitsTotal = 0;
    var hashValue = 0;
    // TODO: しんどい...
    double maxLat = 90, minLat = -90, maxLon = 180, minLon = -180, mid;

    while (chars.length < numberOfChars) {
      if (bitsTotal.isEven) {
        mid = (maxLon + minLon) / 2;
        if (longitude > mid) {
          hashValue = (hashValue << 1) + 1;
          minLon = mid;
        } else {
          hashValue = (hashValue << 1) + 0;
          maxLon = mid;
        }
      } else {
        mid = (maxLat + minLat) / 2;
        if (latitude > mid) {
          hashValue = (hashValue << 1) + 1;
          minLat = mid;
        } else {
          hashValue = (hashValue << 1) + 0;
          maxLat = mid;
        }
      }

      bits++;
      bitsTotal++;
      if (bits == 5) {
        final code = _base32Codes[hashValue];
        chars.add(code);
        bits = 0;
        hashValue = 0;
      }
    }

    return chars.join();
  }

  ///
  /// Decode Bounding box
  ///
  /// Decode a hashString into a bound box that matches it.
  /// Data returned in a List [minLat, minLon, maxLat, maxLon]
  List<double> decodeBbox(String hashString) {
    var isLon = true;
    double maxLat = 90, minLat = -90, maxLon = 180, minLon = -180, mid;

    int? hashValue = 0;
    for (var i = 0, l = hashString.length; i < l; i++) {
      final code = hashString[i].toLowerCase();
      hashValue = _base32CodesDic[code];

      for (var bits = 4; bits >= 0; bits--) {
        final bit = (hashValue! >> bits) & 1;
        if (isLon) {
          mid = (maxLon + minLon) / 2;
          if (bit == 1) {
            minLon = mid;
          } else {
            maxLon = mid;
          }
        } else {
          mid = (maxLat + minLat) / 2;
          if (bit == 1) {
            minLat = mid;
          } else {
            maxLat = mid;
          }
        }
        isLon = !isLon;
      }
    }
    return [minLat, minLon, maxLat, maxLon];
  }

  ///
  /// Decode a [hashString] into a pair of latitude and longitude.
  /// A map is returned with keys 'latitude', 'longitude','latitudeError','longitudeError'
  Map<String, double> decode(String hashString) {
    final bbox = decodeBbox(hashString);
    final lat = (bbox[0] + bbox[2]) / 2;
    final lon = (bbox[1] + bbox[3]) / 2;
    final latErr = bbox[2] - lat;
    final lonErr = bbox[3] - lon;
    // TODO: 型をつける...
    return {
      'latitude': lat,
      'longitude': lon,
      'latitudeError': latErr,
      'longitudeError': lonErr,
    };
  }

  ///
  /// Neighbors
  /// Returns all neighbors' hashstrings clockwise from north around to northwest
  /// 7 0 1
  /// 6 X 2
  /// 5 4 3
  List<String> neighbors(String geoHash) {
    final hashStringLength = geoHash.length;
    final lonlat = decode(geoHash);
    final lat = lonlat['latitude'];
    final lon = lonlat['longitude'];
    final latErr = lonlat['latitudeError']! * 2;
    final lonErr = lonlat['longitudeError']! * 2;

    double neighborLat, neighborLon;

    String encodeNeighbor(double neighborLatDir, double neighborLonDir) {
      neighborLat = lat! + neighborLatDir * latErr;
      neighborLon = lon! + neighborLonDir * lonErr;
      return encode(
        latitude: neighborLat,
        longitude: neighborLon,
        numberOfChars: hashStringLength,
      );
    }

    final neighborHashList = [
      encodeNeighbor(1, 0),
      encodeNeighbor(1, 1),
      encodeNeighbor(0, 1),
      encodeNeighbor(-1, 1),
      encodeNeighbor(-1, 0),
      encodeNeighbor(-1, -1),
      encodeNeighbor(0, -1),
      encodeNeighbor(1, -1)
    ];

    return neighborHashList;
  }

  static int setPrecision(double km) {
    /*
      * 1	≤ 5,000km	×	5,000km
      * 2	≤ 1,250km	×	625km
      * 3	≤ 156km	×	156km
      * 4	≤ 39.1km	×	19.5km
      * 5	≤ 4.89km	×	4.89km
      * 6	≤ 1.22km	×	0.61km
      * 7	≤ 153m	×	153m
      * 8	≤ 38.2m	×	19.1m
      * 9	≤ 4.77m	×	4.77m
      *
     */

    if (km <= 0.00477) {
      return 9;
    } else if (km <= 0.0382) {
      return 8;
    } else if (km <= 0.153) {
      return 7;
    } else if (km <= 1.22) {
      return 6;
    } else if (km <= 4.89) {
      return 5;
    } else if (km <= 39.1) {
      return 4;
    } else if (km <= 156) {
      return 3;
    } else if (km <= 1250) {
      return 2;
    } else {
      return 1;
    }
  }

  // The equatorial radius of the earth in meters
  static const double _earthEqRadius = 6378137;

  // The meridional radius of the earth in meters
  static const double _earthPolarRadius = 6357852.3;

  /// distance in km
  static double kmDistance(Coordinates location1, Coordinates location2) {
    return kmCalcDistance(
      location1.latitude,
      location1.longitude,
      location2.latitude,
      location2.longitude,
    );
  }

  /// distance in km
  static double kmCalcDistance(
    double lat1,
    double long1,
    double lat2,
    double long2,
  ) {
    // Earth's mean radius in meters
    const radius = (_earthEqRadius + _earthPolarRadius) / 2;
    final latDelta = _toRadians(lat1 - lat2);
    final lonDelta = _toRadians(long1 - long2);

    final a = (sin(latDelta / 2) * sin(latDelta / 2)) +
        (cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(lonDelta / 2) *
            sin(lonDelta / 2));
    final distance = radius * 2 * atan2(sqrt(a), sqrt(1 - a)) / 1000;
    return double.parse(distance.toStringAsFixed(3));
  }

  static double _toRadians(double num) => num * (pi / 180.0);
}
