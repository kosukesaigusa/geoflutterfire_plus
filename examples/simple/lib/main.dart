import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        sliderTheme: SliderThemeData(
          overlayShape: SliderComponentShape.noOverlay,
        ),
      ),
      home: const MapPage(),
    );
  }
}

/// Tokyo Station location for demo.
/// You can get latitude and longitude from this site:
/// https://www.geocoding.jp/
const tokyoStation = LatLng(35.681236, 139.767125);

/// Reference to the collection where the location data is stored.
/// `withConverter` is available to type-safely define [CollectionReference].
final collectionReference = FirebaseFirestore.instance.collection('locations');

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  MapPageState createState() => MapPageState();
}

class MapPageState extends State<MapPage> {
  /// Camera position on Google Maps.
  /// Used as center point when running geo query.
  CameraPosition _cameraPosition = _initialCameraPosition;

  /// Detection radius (km) from the center point when running geo query.
  double _radiusInKm = _initialRadiusInKm;

  /// [Marker]s on Google Maps.
  Set<Marker> _markers = {};

  /// Geo query [StreamSubscription].
  late StreamSubscription<List<DocumentSnapshot<Map<String, dynamic>>>>
      _subscription;

  /// Returns geo query [StreamSubscription] with listener.
  StreamSubscription<List<DocumentSnapshot<Map<String, dynamic>>>>
      _geoQuerySubscription({
    required double latitude,
    required double longitude,
    required double radiusInKm,
  }) =>
          GeoCollectionRef(collectionReference)
              .within(
            center: GeoFirePoint(latitude, longitude),
            radiusInKm: radiusInKm,
            field: 'location',
            geopointFrom: (data) => (data['location']
                as Map<String, dynamic>)['geopoint'] as GeoPoint,
          )
              .listen((documentSnapshots) {
            final markers = <Marker>{};
            for (final ds in documentSnapshots) {
              final data = ds.data();
              if (data == null) {
                continue;
              }
              final geoPoint = (data['location']
                  as Map<String, dynamic>)['geopoint'] as GeoPoint;
              markers.add(
                Marker(
                  markerId:
                      MarkerId('(${geoPoint.latitude}, ${geoPoint.longitude})'),
                  position: LatLng(geoPoint.latitude, geoPoint.longitude),
                ),
              );
            }
            debugPrint('📍 markers (${markers.length}): $markers');
            setState(() {
              _markers = markers;
            });
          });

  /// Initial geo query detection radius in km.
  static const double _initialRadiusInKm = 1;

  /// Google Maps initial camera zoom level.
  static const double _initialZoom = 12;

  /// Google Maps initial camera position.
  static final _initialCameraPosition = CameraPosition(
    target: LatLng(tokyoStation.latitude, tokyoStation.longitude),
    zoom: _initialZoom,
  );

  @override
  void initState() {
    _subscription = _geoQuerySubscription(
      latitude: _cameraPosition.target.latitude,
      longitude: _cameraPosition.target.longitude,
      radiusInKm: _radiusInKm,
    );
    super.initState();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _initialCameraPosition,
            markers: _markers,
            circles: {
              Circle(
                circleId: const CircleId('value'),
                center: LatLng(
                  _cameraPosition.target.latitude,
                  _cameraPosition.target.longitude,
                ),
                // multiple 1000 to convert from meters to kilometers.
                radius: _radiusInKm * 1000,
                fillColor: Colors.black12,
                strokeWidth: 0,
              ),
            },
            onCameraMove: (cameraPosition) {
              debugPrint('📷 lat: ${cameraPosition.target.latitude}, '
                  'lng: ${cameraPosition.target.latitude}');
              _cameraPosition = cameraPosition;
              _subscription = _geoQuerySubscription(
                latitude: cameraPosition.target.latitude,
                longitude: cameraPosition.target.longitude,
                radiusInKm: _radiusInKm,
              );
              setState(() {});
            },
          ),
          Positioned(
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 16, left: 16, right: 16),
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
                      onChanged: (double value) {
                        _radiusInKm = value;
                        _subscription = _geoQuerySubscription(
                          latitude: _cameraPosition.target.latitude,
                          longitude: _cameraPosition.target.longitude,
                          radiusInKm: _radiusInKm,
                        );
                        setState(() {});
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          builder: (context) => const _AddLocationModalBottomSheet(),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// ModalBottomSheet widget to add location data to Cloud Firestore.
class _AddLocationModalBottomSheet extends StatefulWidget {
  const _AddLocationModalBottomSheet();

  @override
  _AddLocationModalBottomSheetState createState() =>
      _AddLocationModalBottomSheetState();
}

class _AddLocationModalBottomSheetState
    extends State<_AddLocationModalBottomSheet> {
  final _latitudeEditingController = TextEditingController();
  final _longitudeEditingController = TextEditingController();

  @override
  void dispose() {
    _latitudeEditingController.dispose();
    _longitudeEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 32,
        bottom: 60,
        right: 16,
        left: 16,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _latitudeEditingController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              label: const Text('latitude'),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _longitudeEditingController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              label: const Text('latitude'),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              try {
                await _addLocation();
              } on Exception catch (e) {
                debugPrint('🚨 An exception occurred when adding location data'
                    '${e.toString()}');
              }
              navigator.pop();
            },
            child: const Text('Add location data'),
          ),
        ],
      ),
    );
  }

  /// Add location data to Cloud Firestore.
  Future<void> _addLocation() async {
    final latitude = double.tryParse(_latitudeEditingController.value.text);
    final longitude = double.tryParse(_longitudeEditingController.value.text);
    if (latitude == null || longitude == null) {
      throw Exception('Enter valid values as latitude and longitude.');
    }
    final geoFirePoint = GeoFirePoint(latitude, longitude);
    await collectionReference.add(<String, dynamic>{
      'location': geoFirePoint.data,
    });
    debugPrint('🌍 Location data is successfully added: '
        'latitude: $latitude, '
        'longitude: $longitude, '
        'geohash: ${geoFirePoint.geohash}');
  }
}
