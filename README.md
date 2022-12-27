# geoflutterfire_plus

geoflutterfire_plus allows your flutter apps to query geographic data saved in Cloud Firestore.

This package is fork from [GeoFlutterFire](https://github.com/DarshanGowda0/GeoFlutterFire), and tried to be constantly maintained to work with latest Flutter SDK, Dart SDK, and other dependency packages.

## Prerequisites

```plain
Dart: '>=2.16.0 <3.0.0'
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

## Example

You will find some example projects under `example` directory.

## Geo queries

Refer to Firebase official document [Geo queries](https://firebase.google.com/docs/firestore/solutions/geoqueries) to understand what Geohash is, why you need to save geo location as Geohashes, and how to query them. You will also understand limitations of using Geohashes for querying locations.

## Save geo data

In order to save geo data as documents of Cloud Firestore, use `GeoFirePoint`. `geoFirePoint.data` gives geopoint (`GeoPoint` type defined in `cloud_firestore` package) and geohash string.

```dart
// Define GeoFirePoint instance by giving latitude and longitude.
final GeoFirePoint geoFirePoint = GeoFirePoint(35.681236, 139.767125);

// Get GeoPoint instance and geohash string as Map<String, dynamic>.
final Map<String, dynamic> data = geoFirePoint.data;

// {geopoint: Instance of 'GeoPoint', geohash: xn76urx66}
print(data);
```

And you can just call `add` or `set` method of `cloud_firestore` to save the data.

```dart
final db = FirebaseFirestore.instance;
await db.collection('locations').add(data);
```

## Query geo data

In order to query location documents within a 50km radius of Tokyo station, you will write query like the following:

```dart
final GeoFirePoint center = GeoFirePoint(35.681236, 139.767125);
const double radiusInKm = 50;
const String field = 'location';
GeoPoint geopointFrom(Map<String, dynamic> data) =>
    data['location'].geopoint as GeoPoint;

final db = FirebaseFirestore.instance;
final CollectionReference<Map<String, dynamic>> collectionReference =
    db.collection('locations');
final Stream<List<DocumentSnapshot<Map<String, dynamic>>>> stream =
    GeoCollectionRef<Map<String, dynamic>>(collectionReference).within(
  center: center,
  radiusInKm: radiusInKm,
  field: field,
  geopointFrom: geopointFrom,
);
```

If you would like to use `withConverter` to type-safely (e.g. `GeoUser` typed document, which has `location` field) write query, you will do in the same way.

```dart
final GeoFirePoint center = GeoFirePoint(35.681236, 139.767125);
const double radiusInKm = 50;
const String field = 'location';
GeoPoint geopointFrom(GeoUser geoUser) =>
    geoUser.location.geopoint as GeoPoint;

final db = FirebaseFirestore.instance;
final CollectionReference<GeoUser> collectionReference =
    db.collection('locations');
final Stream<List<DocumentSnapshot<GeoUser>>> stream =
    GeoCollectionRef(collectionReference).within(
  center: center,
  radiusInKm: radiusInKm,
  field: field,
  geopointFrom: geopointFrom,
);
```

