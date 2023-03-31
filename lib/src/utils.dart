import 'math.dart' as math;

/// Returns neighbor geohashes of given [geohash].
List<String> neighborGeohashesOf({required final String geohash}) =>
    math.neighborGeohashesOf(geohash);
