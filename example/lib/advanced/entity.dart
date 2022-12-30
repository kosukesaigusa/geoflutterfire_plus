import 'package:cloud_firestore/cloud_firestore.dart';

/// An entity of Cloud Firestore location document.
class Location {
  Location({
    required this.geo,
    required this.name,
  });

  factory Location.fromJson(Map<String, dynamic> json) => Location(
        geo: Geo.fromJson(json['geo'] as Map<String, dynamic>),
        name: json['name'] as String,
      );

  factory Location.fromDocumentSnapshot(DocumentSnapshot documentSnapshot) =>
      Location.fromJson(documentSnapshot.data()! as Map<String, dynamic>);

  final Geo geo;
  final String name;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'geo': geo.toJson(),
        'name': name,
      };
}

/// An entity of `geo` field of Cloud Firestore location document.
class Geo {
  Geo({
    required this.geohash,
    required this.geopoint,
  });

  factory Geo.fromJson(Map<String, dynamic> json) => Geo(
        geohash: json['geohash'] as String,
        geopoint: json['geopoint'] as GeoPoint,
      );

  final String geohash;
  final GeoPoint geopoint;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'geohash': geohash,
        'geopoint': geopoint,
      };
}
