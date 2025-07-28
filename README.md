# my_flutter_app

This sample demonstrates basic USB interaction and browsing of external
storage connected to the device. The main screen lists any directories
under `/storage` that are not part of the internal system storage. Tapping
one opens a file browser where you can add, delete or rename files. When
adding a file you can browse the external storage to choose the exact
destination directory.

The app uses the `permission_handler` plugin to request storage access.

### Android NDK version

The `usb_serial` plugin requires Android NDK `27.0.12077973`. If you see a
build failure mentioning a mismatched NDK version, update
`android/app/build.gradle.kts`:

```kotlin
android {
    ndkVersion = "27.0.12077973"
}
```

### Storage permissions

The sample scans `/storage` for removable media. Items are displayed alphabetically. Grant the Storage
permission on first launch so the app can access external files.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
