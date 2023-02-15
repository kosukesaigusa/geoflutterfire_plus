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
  final _latitudeEditingController = TextEditingController();
  final _longitudeEditingController = TextEditingController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _latitudeEditingController.text = widget.geoFirePoint.latitude.toString();
    _longitudeEditingController.text = widget.geoFirePoint.longitude.toString();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Center(
        child: const Text('Enter location data'),
      ),
      content: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.name),
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
              try {
                await _setLocation(
                  widget.id,
                  widget.geoFirePoint,
                );
              } on Exception catch (e) {
                debugPrint('🚨 An exception occurred when adding location data'
                    '${e.toString()}');
              }
              navigator.pop();
            },
            child: const Text('set location data'),
          ),
        ],
      ),
    );
  }

  Future<void> _setLocation(
    String id,
    GeoFirePoint geoFirePoint,
  ) async {
    await GeoCollectionReference<Map<String, dynamic>>(
      FirebaseFirestore.instance.collection('locations'),
    ).setPoint(
      id: id,
      field: geoFirePoint.geohash,
      latitude: geoFirePoint.latitude,
      longitude: geoFirePoint.longitude,
    );
    debugPrint(
      '🌍 Location data is successfully set: '
      'id: ${id}'
      'field: ${geoFirePoint.geohash}'
      'latitude: ${geoFirePoint.latitude}'
      'longitude: ${geoFirePoint.longitude}',
    );
  }
}
