import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';

class SetLocationDialog extends StatefulWidget {
  const SetLocationDialog({
    super.key,
    required this.id,
    required this.name,
    required this.geoFirePoint,
  });

  final String id;
  final String name;
  final GeoFirePoint geoFirePoint;

  @override
  State<SetLocationDialog> createState() => _SetLocationDialogState();
}

class _SetLocationDialogState extends State<SetLocationDialog> {
  final _nameEditingController = TextEditingController();
  final _latitudeEditingController = TextEditingController();
  final _longitudeEditingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameEditingController.text = widget.name;
    _latitudeEditingController.text = widget.geoFirePoint.latitude.toString();
    _longitudeEditingController.text = widget.geoFirePoint.longitude.toString();
  }

  @override
  void dispose() {
    _nameEditingController.dispose();
    _latitudeEditingController.dispose();
    _longitudeEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Center(
        child: Text('Enter location data'),
      ),
      content: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameEditingController,
            keyboardType: TextInputType.name,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              label: const Text('name'),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _latitudeEditingController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              label: const Text('longitude'),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _longitudeEditingController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              label: const Text('longitude'),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final newName = _nameEditingController.value.text;
              if (newName.isEmpty) {
                throw Exception('Enter valid name');
              }
              final newLatitude =
                  double.tryParse(_latitudeEditingController.text);
              final newLongitude =
                  double.tryParse(_longitudeEditingController.text);
              if (newLatitude == null || newLongitude == null) {
                throw Exception(
                  'Enter valid values as latitude and longitude.',
                );
              }
              try {
                await _set(
                  widget.id,
                  newName,
                  newLatitude,
                  newLongitude,
                );
              } on Exception catch (e) {
                debugPrint(
                  '🚨 An exception occurred when adding location data $e',
                );
              }
              navigator.popUntil((route) => route.isFirst);
            },
            child: const Text('Set location data'),
          ),
        ],
      ),
    );
  }

  /// Sets location data to Cloud Firestore.
  Future<void> _set(
    String id,
    String newName,
    double newLatitude,
    double newLongitude,
  ) async {
    final geoFirePoint = GeoFirePoint(GeoPoint(newLatitude, newLongitude));
    await GeoCollectionReference<Map<String, dynamic>>(
      FirebaseFirestore.instance.collection('locations'),
    ).set(
      id: id,
      data: {
        'geo': geoFirePoint.data,
        'name': newName,
      },
      merge: true,
    );
    debugPrint(
      '🌍 Location data is successfully set: '
      'id: $id'
      'latitude: $newLatitude'
      'longitude: $newLongitude',
    );
  }
}
