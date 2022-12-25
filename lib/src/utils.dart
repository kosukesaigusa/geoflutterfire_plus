import 'math.dart';

/// Returns neighbor geohashes of given [geohash].
List<String> neighborGeohashesOf({required String geohash}) =>
    neighborsOfGeohash(geohash);
