// import 'dart:async';

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:geoflutterfire2/geoflutterfire2.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:rxdart/rxdart.dart';

// import '../add_location.dart';

// /// Tokyo Station location for demo.
// const _tokyoStation = LatLng(35.681236, 139.767125);

// /// Reference to the collection where the location data is stored.
// /// `withConverter` is available to type-safely define [CollectionReference].
// ignore: lines_longer_than_80_chars
// final _collectionReference = FirebaseFirestore.instance.collection('locations');

// /// Geo query geoQueryCondition.
// class _GeoQueryCondition {
//   _GeoQueryCondition({
//     required this.radiusInKm,
//     required this.cameraPosition,
//   });

//   final double radiusInKm;
//   final CameraPosition cameraPosition;
// }

// class GeoFlutterFire2Example extends StatefulWidget {
//   const GeoFlutterFire2Example({super.key});

//   @override
//   GeoFlutterFire2ExampleState createState() => GeoFlutterFire2ExampleState();
// }

// /// Example page using GeoFlutterFire2 package for smooth comparison.
// class GeoFlutterFire2ExampleState extends State<GeoFlutterFire2Example> {
//   /// [Marker]s on Google Maps.
//   Set<Marker> _markers = {};

//   /// [BehaviorSubject] of currently geo query radius and camera position.
//   final _geoQueryCondition = BehaviorSubject<_GeoQueryCondition>.seeded(
//     _GeoQueryCondition(
//       radiusInKm: _initialRadiusInKm,
//       cameraPosition: _initialCameraPosition,
//     ),
//   );

//   /// [Stream] of geo query result.
//   late final Stream<List<DocumentSnapshot>> _stream =
//       _geoQueryCondition.switchMap(
//     (geoQueryCondition) =>
//         GeoFireCollectionRef(_collectionReference.orderBy('name')).within(
//       center: GeoFirePoint(
//         _cameraPosition.target.latitude,
//         _cameraPosition.target.longitude,
//       ),
//       radius: geoQueryCondition.radiusInKm,
//       field: 'geo',
//     ),
//   );

//   /// Updates [_markers] by fetched geo [DocumentSnapshot]s.
//   void _updateMarkersByDocumentSnapshots(
//     List<DocumentSnapshot> documentSnapshots,
//   ) {
//     final markers = <Marker>{};
//     for (final ds in documentSnapshots) {
//       final id = ds.id;
//       final data = ds.data() as Map<String, dynamic>?;
//       if (data == null) {
//         continue;
//       }
//       final name = data['name'] as String;
//       final geoPoint =
//           (data['geo'] as Map<String, dynamic>)['geopoint'] as GeoPoint;
//       markers.add(_createMarker(id: id, name: name, geoPoint: geoPoint));
//     }
//     debugPrint('📍 markers count: ${markers.length}');
//     setState(() {
//       _markers = markers;
//     });
//   }

//   /// Creates a [Marker] by fetched geo location.
//   Marker _createMarker({
//     required String id,
//     required String name,
//     required GeoPoint geoPoint,
//   }) =>
//       Marker(
//         markerId: MarkerId('(${geoPoint.latitude}, ${geoPoint.longitude})'),
//         position: LatLng(geoPoint.latitude, geoPoint.longitude),
//         infoWindow: InfoWindow(title: name),
//       );

//   /// Current detecting radius in kilometers.
//   double get _radiusInKm => _geoQueryCondition.value.radiusInKm;

//   /// Current camera position on Google Maps.
//   CameraPosition get _cameraPosition => _geoQueryCondition.value.cameraPosition;

//   /// Initial geo query detection radius in km.
//   static const double _initialRadiusInKm = 1;

//   /// Google Maps initial camera zoom level.
//   static const double _initialZoom = 14;

//   /// Google Maps initial target position.
//   static final LatLng _initialTarget = LatLng(
//     _tokyoStation.latitude,
//     _tokyoStation.longitude,
//   );

//   /// Google Maps initial camera position.
//   static final _initialCameraPosition = CameraPosition(
//     target: _initialTarget,
//     zoom: _initialZoom,
//   );

//   @override
//   void dispose() {
//     _geoQueryCondition.close();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Stack(
//         children: [
//           GoogleMap(
//             zoomControlsEnabled: false,
//             myLocationButtonEnabled: false,
//             initialCameraPosition: _initialCameraPosition,
//             onMapCreated: (_) =>
//                 _stream.listen(_updateMarkersByDocumentSnapshots),
//             markers: _markers,
//             circles: {
//               Circle(
//                 circleId: const CircleId('value'),
//                 center: LatLng(
//                   _cameraPosition.target.latitude,
//                   _cameraPosition.target.longitude,
//                 ),
//                 // multiple 1000 to convert from kilometers to meters.
//                 radius: _radiusInKm * 1000,
//                 fillColor: Colors.black12,
//                 strokeWidth: 0,
//               ),
//             },
//             onCameraMove: (cameraPosition) {
//               debugPrint('📷 lat: ${cameraPosition.target.latitude}, '
//                   'lng: ${cameraPosition.target.latitude}');
//               _geoQueryCondition.add(
//                 _GeoQueryCondition(
//                   radiusInKm: _radiusInKm,
//                   cameraPosition: cameraPosition,
//                 ),
//               );
//             },
//             onLongPress: (latLng) => showDialog<void>(
//               context: context,
//               builder: (context) => AddLocationDialog(latLng: latLng),
//             ),
//           ),
//           Container(
//             width: double.infinity,
//             margin: const EdgeInsets.only(top: 64, left: 16, right: 16),
//             padding: const EdgeInsets.all(16),
//             decoration: const BoxDecoration(
//               color: Colors.black38,
//               borderRadius: BorderRadius.all(Radius.circular(8)),
//             ),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 const Text(
//                   'Debug window',
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   'Currently detected count: '
//                   '${_markers.length}',
//                   style: const TextStyle(color: Colors.white),
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   'Current radius: '
//                   '${_radiusInKm.toStringAsFixed(1)} (km)',
//                   style: const TextStyle(color: Colors.white),
//                 ),
//                 const SizedBox(height: 8),
//                 Slider(
//                   value: _radiusInKm,
//                   min: 1,
//                   max: 100,
//                   divisions: 99,
//                   label: _radiusInKm.toStringAsFixed(1),
//                   onChanged: (value) => _geoQueryCondition.add(
//                     _GeoQueryCondition(
//                       radiusInKm: value,
//                       cameraPosition: _cameraPosition,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
