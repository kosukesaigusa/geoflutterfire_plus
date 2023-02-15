import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';

class DeleteLocationDialog extends StatelessWidget {
  const DeleteLocationDialog({
    super.key,
    required this.id,
    required this.name,
    required this.geoFirePoint,
  });

  final String id;
  final String name;
  final GeoFirePoint geoFirePoint;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Are you sure you want to delete this point?'),
      content: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('name:${name}'),
          const SizedBox(height: 8),
          Text('latitude:${geoFirePoint.latitude}'),
          const SizedBox(height: 8),
          Text('longitude:${geoFirePoint.longitude}'),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.center,
            child: ElevatedButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                try {
                  await _deleteLocation(id);
                } on Exception catch (e) {
                  debugPrint(
                      '🚨 An exception occurred when adding location data'
                      '${e.toString()}');
                }
                navigator.pop();
              },
              child: const Text('Delete'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteLocation(String id) async {
    await GeoCollectionReference<Map<String, dynamic>>(
      FirebaseFirestore.instance.collection('locations'),
    ).delete(id);
    debugPrint(
      '🌍 Location data is successfully delete: '
      'id: $id',
    );
  }
}
