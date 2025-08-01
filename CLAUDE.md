# geoflutterfire_plus Project Guide

## Project Overview

This is **geoflutterfire_plus**, a Flutter package that enables geographic queries on Cloud Firestore documents. It's a redesigned fork of GeoFlutterFire with modern Flutter/Dart support and additional features.

### Key Information

- **Package**: geoflutterfire_plus
- **Language**: Dart/Flutter
- **Purpose**: Geographic data storage and querying for Cloud Firestore
- **Repository**: <https://github.com/KosukeSaigusa/geoflutterfire_plus>
- **License**: MIT

## Technical Stack

### Dependencies

- **cloud_firestore** (Core Firestore integration)
- **rxdart** (Reactive programming)
- **flutter** (UI framework - SDK)

### Development Dependencies

- **build_runner** (Code generation)
- **mockito** (Testing mocks)
- **flutter_test** (Testing framework - SDK)

### SDK Requirements

- **Dart**: >=2.17.0 <4.0.0
- **Flutter**: >=2.10.0

## Project Structure

```bash
lib/
├── geoflutterfire_plus.dart          # Main library export
└── src/
    ├── geo_collection_reference.dart  # Collection reference with geo queries
    ├── geo_fire_point.dart           # Geographic point representation
    ├── math.dart                     # Mathematical calculations for geo queries
    └── utils.dart                    # Utility functions

example/
├── lib/
│   ├── main.dart                     # Example app entry point
│   ├── add_location.dart             # Location adding functionality
│   ├── delete_location.dart          # Location deletion functionality
│   ├── set_location.dart             # Location setting functionality
│   ├── set_or_delete_location.dart   # Combined operations
│   └── advanced/                     # Advanced usage examples
│       ├── additional_query.dart     # Custom query examples
│       ├── entity.dart               # Entity class definitions
│       ├── geoflutterfire2.dart      # Advanced geo queries
│       ├── utils.dart                # Utility functions
│       └── with_converter.dart       # Type-safe converter examples

test/
├── geo_collection_reference_test.dart # Collection reference tests
├── geo_fire_point_test.dart          # GeoFirePoint tests
└── math_test.dart                    # Mathematical function tests
```

## Core Concepts

### Geographic Data Storage

- Uses **Geohash** algorithm for efficient geographic queries
- Stores both `GeoPoint` (Firestore native) and `geohash` (string) in documents
- Data structure: `{ geopoint: GeoPoint, geohash: string }`

### Main Classes

1. **GeoFirePoint**: Represents a geographic point with latitude/longitude
2. **GeoCollectionReference**: Enhanced CollectionReference with geo query capabilities
3. **Mathematical utilities**: Distance calculations and geohash operations

## Development Guidelines

### Code Style

- Follow Dart/Flutter conventions
- Use meaningful variable names
- Document public APIs thoroughly
- Follow the existing code patterns in the repository

### Testing

- Write unit tests for all public methods
- Use mockito for mocking Firestore dependencies
- Test both successful and error cases
- Run tests with: `flutter test`

### Linting

- Uses `analysis_options.yaml` for linting rules
- Follows strict linting from `all_lint_rules.yaml`
- Ensure code passes all lint checks

## Common Operations

### Adding Geographic Data

```dart
final geoFirePoint = GeoFirePoint(GeoPoint(35.681236, 139.767125));
GeoCollectionReference(collection).add({
  'geo': geoFirePoint.data,
  'name': 'Location Name',
});
```

### Querying Geographic Data

```dart
final stream = GeoCollectionReference(collection).subscribeWithin(
  center: center,
  radiusInKm: radiusInKm,
  field: 'geo',
  geopointFrom: (data) => data['geo']['geopoint'],
);
```

### Custom Query Conditions

```dart
Query<T> queryBuilder(Query<T> query) => 
    query.where('isVisible', isEqualTo: true);
```

## Important Notes

### Limitations

- `limit` and `orderBy` are not supported due to geohash query algorithm constraints
- Custom queries may require composite indexes in Firestore
- Geographic queries are approximate due to Geohash precision

### Performance Considerations

- Larger radius queries require more Firestore reads
- Consider implementing client-side sorting for better UX
- Use appropriate geohash precision for your use case

## Commands

### Running Tests

```bash
flutter test                    # Run all tests
flutter test test/specific_test.dart  # Run specific test
```

### Analysis

```bash
flutter analyze                 # Static analysis
dart format .                   # Format code
```

### Example App

```bash
cd example
flutter run                     # Run example app
```

## Firebase Setup

### Firestore Rules

Ensure appropriate security rules for location data:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /locations/{document} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### Indexes

Geographic queries may require composite indexes. Create them when prompted by Firestore errors.

## Contributing

This is an open-source Flutter package. When contributing:

1. Follow existing code style and patterns
2. Add tests for new functionality
3. Update documentation as needed
4. Ensure all tests pass before submitting PRs
5. Consider backward compatibility

## Troubleshooting

### Common Issues

- **Index errors**: Create required composite indexes in Firestore console
- **Permission errors**: Check Firestore security rules
- **Distance calculation errors**: Verify latitude/longitude ranges (-90 to 90, -180 to 180)

### Debug Information

- Enable Firestore debug logging for query troubleshooting
- Use example app to verify expected behavior
- Check GitHub issues for known problems and solutions
