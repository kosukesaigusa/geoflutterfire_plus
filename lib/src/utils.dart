import 'math.dart';

/// Return neighbor geohashes of given [geohash].
List<String> neighborGeohashesOf({required String geohash}) =>
    neighborsOfGeohash(geohash);
