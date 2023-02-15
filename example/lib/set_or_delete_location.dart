import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';

/// AlertDialog widget to add location data to Cloud Firestore.
class SetOrDeleteLocationDialog extends StatefulWidget {
  const SetOrDeleteLocationDialog({super.key, required this.id});

  final String id;

  @override
  AddLocationDialogState createState() => AddLocationDialogState();
}

class AddLocationDialogState extends State<SetOrDeleteLocationDialog> {
  final _nameEditingController = TextEditingController();
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
    return AlertDialog(
      title: const Text('Enter location data'),
      content: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(
            onPressed: () {
              _setLocation(widget.id);
            },
            child: Text('set location'),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              _setLocation(widget.id);
              Navigator.pop(context);
            },
            child: Text('delete location'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _setLocation(String id) async {
    await GeoCollectionReference<Map<String, dynamic>>(
      FirebaseFirestore.instance.collection('locations'),
    ).delete(id);
    debugPrint(
      '🌍 Location data is successfully delete: '
      'id: $id',
    );
  }

// _deleteLocation() {

// }

  /// Add location data to Cloud Firestore.
  Future<void> _addLocation() async {
    final name = _nameEditingController.value.text;
    if (name.isEmpty) {
      throw Exception('Enter valid name');
    }
    final latitude = double.tryParse(_latitudeEditingController.value.text);
    final longitude = double.tryParse(_longitudeEditingController.value.text);
    if (latitude == null || longitude == null) {
      throw Exception('Enter valid values as latitude and longitude.');
    }
    final geoFirePoint = GeoFirePoint(latitude, longitude);
    await GeoCollectionReference<Map<String, dynamic>>(
      FirebaseFirestore.instance.collection('locations'),
    ).add(<String, dynamic>{
      'geo': geoFirePoint.data,
      'name': name,
      'isVisible': true,
    });
    debugPrint('🌍 Location data is successfully added: '
        'name: $name'
        'lat: $latitude, '
        'lng: $longitude, '
        'geohash: ${geoFirePoint.geohash}');
  }
}
