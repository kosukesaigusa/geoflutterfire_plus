import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rxdart/rxdart.dart';

import '../add_location.dart';
import '../set_or_delete_location.dart';
import 'entity.dart';
import 'utils.dart';

/// Tokyo Station location for demo.
const _tokyoStation = LatLng(35.681236, 139.767125);

/// Geo query geoQueryCondition.
class _GeoQueryCondition {
  _GeoQueryCondition({
    required this.radiusInKm,
    required this.cameraPosition,
    required this.filterIsVisible,
  });

  final double radiusInKm;
  final CameraPosition cameraPosition;
  final bool filterIsVisible;
}

class AdditionalQueryExample extends StatefulWidget {
  const AdditionalQueryExample({super.key});

  @override
  AdditionalQueryExampleState createState() => AdditionalQueryExampleState();
}

/// Example page using [GoogleMap].
class AdditionalQueryExampleState extends State<AdditionalQueryExample> {
  /// [Marker]s on Google Maps.
  Set<Marker> _markers = {};

  /// [BehaviorSubject] of currently geo query radius and camera position.
  final _geoQueryCondition = BehaviorSubject<_GeoQueryCondition>.seeded(
    _GeoQueryCondition(
      radiusInKm: _initialRadiusInKm,
      cameraPosition: _initialCameraPosition,
      filterIsVisible: true,
    ),
  );

  /// [Stream] of geo query result.
  late Stream<List<DocumentSnapshot<Location>>> _stream;

  /// Updates [_markers] by fetched geo [DocumentSnapshot]s.
  void _updateMarkersByDocumentSnapshots(
    List<DocumentSnapshot<Location>> documentSnapshots,
  ) {
    final markers = <Marker>{};
    for (final ds in documentSnapshots) {
      final id = ds.id;
      final location = ds.data();
      if (location == null) {
        continue;
      }
      final name = location.name;
      final geoPoint = location.geo.geopoint;
      markers.add(_createMarker(id: id, name: name, geoPoint: geoPoint));
    }
    debugPrint('📍 markers count: ${markers.length}');
    setState(() {
      _markers = markers;
    });
  }

  /// Creates a [Marker] by fetched geo location.
  Marker _createMarker({
    required String id,
    required String name,
    required GeoPoint geoPoint,
  }) =>
      Marker(
        markerId: MarkerId('(${geoPoint.latitude}, ${geoPoint.longitude})'),
        position: LatLng(geoPoint.latitude, geoPoint.longitude),
        infoWindow: InfoWindow(title: name),
        onTap: () => showDialog<void>(
          context: context,
          builder: (context) => SetOrDeleteLocationDialog(
            id: id,
            name: name,
            geoFirePoint: GeoFirePoint(
              GeoPoint(geoPoint.latitude, geoPoint.longitude),
            ),
          ),
        ),
      );

  /// Current detecting radius in kilometers.
  double get _radiusInKm => _geoQueryCondition.value.radiusInKm;

  /// Current camera position on Google Maps.
  CameraPosition get _cameraPosition => _geoQueryCondition.value.cameraPosition;

  /// Currently filtering only visible locations or not.
  bool get _filterIsVisible => _geoQueryCondition.value.filterIsVisible;

  /// Initial geo query detection radius in km.
  static const double _initialRadiusInKm = 1;

  /// Google Maps initial camera zoom level.
  static const double _initialZoom = 14;

  /// Google Maps initial target position.
  static final LatLng _initialTarget = LatLng(
    _tokyoStation.latitude,
    _tokyoStation.longitude,
  );

  /// Google Maps initial camera position.
  static final _initialCameraPosition = CameraPosition(
    target: _initialTarget,
    zoom: _initialZoom,
  );

  @override
  void initState() {
    _stream = _geoQueryCondition.switchMap(
      (geoQueryCondition) =>
          GeoCollectionReference(typedCollectionReference).subscribeWithin(
        center: GeoFirePoint(
          GeoPoint(
            _cameraPosition.target.latitude,
            _cameraPosition.target.longitude,
          ),
        ),
        radiusInKm: geoQueryCondition.radiusInKm,
        field: 'geo',
        geopointFrom: (location) => location.geo.geopoint,
        queryBuilder: _filterIsVisible
            ? (query) => query.where('isVisible', isEqualTo: true)
            : null,
        strictMode: true,
      ),
    );
    super.initState();
  }

  @override
  void dispose() {
    _geoQueryCondition.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
            initialCameraPosition: _initialCameraPosition,
            onMapCreated: (_) =>
                _stream.listen(_updateMarkersByDocumentSnapshots),
            markers: _markers,
            circles: {
              Circle(
                circleId: const CircleId('value'),
                center: LatLng(
                  _cameraPosition.target.latitude,
                  _cameraPosition.target.longitude,
                ),
                // multiple 1000 to convert from kilometers to meters.
                radius: _radiusInKm * 1000,
                fillColor: Colors.black12,
                strokeWidth: 0,
              ),
            },
            onCameraMove: (cameraPosition) {
              debugPrint('📷 lat: ${cameraPosition.target.latitude}, '
                  'lng: ${cameraPosition.target.latitude}');
              _geoQueryCondition.add(
                _GeoQueryCondition(
                  radiusInKm: _radiusInKm,
                  cameraPosition: cameraPosition,
                  filterIsVisible: _filterIsVisible,
                ),
              );
            },
            onLongPress: (latLng) => showDialog<void>(
              context: context,
              builder: (context) => AddLocationDialog(latLng: latLng),
            ),
          ),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 64, left: 16, right: 16),
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.black38,
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Debug window',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Currently detected count: '
                  '${_markers.length}',
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  'Current radius: '
                  '${_radiusInKm.toStringAsFixed(1)} (km)',
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 8),
                Slider(
                  value: _radiusInKm,
                  min: 1,
                  max: 100,
                  divisions: 99,
                  label: _radiusInKm.toStringAsFixed(1),
                  onChanged: (value) => _geoQueryCondition.add(
                    _GeoQueryCondition(
                      radiusInKm: value,
                      cameraPosition: _cameraPosition,
                      filterIsVisible: _filterIsVisible,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text(
                      'Filter only visible locations:',
                      style: TextStyle(color: Colors.white),
                    ),
                    Checkbox(
                      value: _filterIsVisible,
                      onChanged: (value) => _geoQueryCondition.add(
                        _GeoQueryCondition(
                          radiusInKm: _radiusInKm,
                          cameraPosition: _cameraPosition,
                          filterIsVisible: value ?? _filterIsVisible,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          builder: (context) => const AddLocationDialog(),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}
