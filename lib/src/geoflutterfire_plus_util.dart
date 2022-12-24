import 'math.dart';

class GeoFlutterFireUtil {
  GeoFlutterFireUtil();
  static final MathUtils _util = MathUtils();

  /// Return neighboring geo-hashes of given [geohash].
  static List<String> neighborGeohashesOf({required String geohash}) =>
      _util.neighborsOfGeohash(geohash);
}
