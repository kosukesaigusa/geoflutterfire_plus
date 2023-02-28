import 'package:cloud_firestore/cloud_firestore.dart';

import 'entity.dart';

/// Typed reference to the collection where the location data is stored.
final typedCollectionReference =
    FirebaseFirestore.instance.collection('locations').withConverter<Location>(
          fromFirestore: (ds, _) => Location.fromDocumentSnapshot(ds),
          toFirestore: (obj, _) => obj.toJson(),
        );
