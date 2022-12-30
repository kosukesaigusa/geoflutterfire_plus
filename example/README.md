# geoflutterfire_plus example 🌍

A example project of geoflutterfire_plus.

## Prerequisites

```plain
Dart: '>=2.17.0 <3.0.0'
Flutter: '>=2.10.0'
```

## Getting Started

If you would like to clone and debug this example project, run this command on example project root:

```shell
flutterfire configure
```

If `flutterfire` command is not available, see [official documentation](https://firebase.flutter.dev/docs/cli/).

This example depends on [google_maps_flutter](https://pub.dev/packages/google_maps_flutter) package and requires Google Maps API key.

Add `ios/Runner/Environment.swift` and `android/secret.properties` by yourself.

```swift
import Foundation

struct Env {
  static let googleMapApiKey = "your-api-key-here"
}
```

```properties
googleMap.apiKey=your-api-key-here
```
