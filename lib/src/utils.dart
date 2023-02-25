import 'math.dart';

/// Returns neighbor geohashes of given [geohash].
List<String> neighborGeohashesOf({required final String geohash}) =>
    neighborsOfGeohash(geohash);
