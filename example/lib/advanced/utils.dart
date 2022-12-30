import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'entity.dart';

/// Tokyo Station location for demo.
/// You can get latitude and longitude from this site:
/// https://www.geocoding.jp/
const tokyoStation = LatLng(35.681236, 139.767125);

/// Typed reference to the collection where the location data is stored.
final typedCollectionReference =
    FirebaseFirestore.instance.collection('locations').withConverter(
          fromFirestore: (ds, _) => Location.fromDocumentSnapshot(ds),
          toFirestore: (obj, _) => obj.toJson(),
        );
