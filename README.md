# geoflutterfire_plus

geoflutterfire_plus allows your flutter apps to query geographic data saved in Cloud Firestore.

This package is fork from [GeoFlutterFire](https://github.com/DarshanGowda0/GeoFlutterFire), and tried to be constantly maintained to work with latest Flutter SDK, Dart SDK, and other dependency packages.

## Prerequisites

```plain
Dart: '>=2.17.0 <3.0.0'
Flutter: '>=2.10.0'
```

## Installing

Run this command:

```shell
flutter pub add geoflutterfire_plus
```

Or add dependency to your `pubspec.yaml`.

```yaml
dependencies:
  geoflutterfire_plus: <latest-version>
```

## Geo queries

Refer to Firebase official document [Geo queries](https://firebase.google.com/docs/firestore/solutions/geoqueries) to understand what Geohash is, why you need to save geo location as Geohash, and how to query them. It will also help you understand limitations of using Geohashes for querying locations.

## Save geo data

In order to save geo data as documents of Cloud Firestore, use `GeoFirePoint`. `GeoFirePoint.data` gives geopoint (`GeoPoint` type defined in `cloud_firestore` package) and Geohash string.

```dart
// Define GeoFirePoint instance by giving latitude and longitude.
final GeoFirePoint geoFirePoint = GeoFirePoint(35.681236, 139.767125);

// Get GeoPoint instance and Geohash string as Map<String, dynamic>.
final Map<String, dynamic> data = geoFirePoint.data;

// {geopoint: Instance of 'GeoPoint', geohash: xn76urx66}
print(data);
```

And you can just call `add` or `set` method of `cloud_firestore` to save the data. For example,

```dart
// Add new documents to locations collection.
FirebaseFirestore.instance.collection('locations').add(
  <String, dynamic>{
    'geo': data,
    'name': 'Tokyo Station',
  },
);
```

The created document would be like the screenshot below. Geohash string (`geohash`) and Cloud Firestore GeoPoint data (`geopoint`) is saved in `geo` field as map type.

![Cloud Firestore](https://user-images.githubusercontent.com/13669049/210041865-43914691-ef00-4946-9c3f-38780b5b9f7a.png)

## Query geo data

In order to query location documents within a 50km radius of Tokyo station, you will write query like the following:

```dart
// Center of the geo query.
final GeoFirePoint center = GeoFirePoint(35.681236, 139.767125);

// Detection range from the center point.
const double radiusInKm = 50;

// Field name of Cloud Firestore documents where the geohash is saved.
const String field = 'geo';

// Function to get GeoPoint instance from Cloud Firestore document data.
GeoPoint geopointFrom(Map<String, dynamic> data) =>
     (data['geo'] as Map<String, dynamic>)['geopoint'] as GeoPoint;

// Reference to locations collection.
final CollectionReference<Map<String, dynamic>> collectionReference =
    FirebaseFirestore.instance.collection('locations');

// Streamed document snapshots of geo query under given conditions.
final Stream<List<DocumentSnapshot<Map<String, dynamic>>>> stream =
    GeoCollectionRef<Map<String, dynamic>>(collectionReference).within(
  center: center,
  radiusInKm: radiusInKm,
  field: field,
  geopointFrom: geopointFrom,
);
```

If you would like to use `withConverter` to type-safely write query, first, you need to define its entity class and factory constructors.

```dart
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
```

Then, define typed collection reference.

```dart
/// Reference to the collection where the location data is stored.
final typedCollectionReference =
    FirebaseFirestore.instance.collection('locations').withConverter(
          fromFirestore: (ds, _) => Location.fromDocumentSnapshot(ds),
          toFirestore: (obj, _) => obj.toJson(),
        );
```

You can write query in the same way as not type-safe one.

```dart
// Center of the geo query.
final GeoFirePoint center = GeoFirePoint(35.681236, 139.767125);

// Detection range from the center point.
const double radiusInKm = 50;

// Field name of Cloud Firestore documents where the geohash is saved.
const String field = 'geo';

// Function to get GeoPoint instance from Location instance.
GeoPoint geopointFrom: (Location location) => location.geo.geopoint;

// Streamed document snapshots of geo query under given conditions.
final Stream<List<DocumentSnapshot<Map<String, dynamic>>>> stream =
    GeoCollectionRef<Map<String, dynamic>>(typedCollectionReference).within(
  center: center,
  radiusInKm: radiusInKm,
  field: field,
  geopointFrom: geopointFrom,
);
```
