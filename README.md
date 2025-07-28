# my_flutter_app

This sample demonstrates browsing of external
storage connected to the device. The main screen lists any directories
found under common mount points such as `/storage`, `/mnt`, `/media`,
`/run/media` and `/sdcard` that are not part of the internal system storage. Tapping
one opens a file browser where you can add, delete or rename files. When
adding a file you can browse the external storage to choose the exact
destination directory.

The app uses the `permission_handler` plugin to request storage access. On
Android 11 and later it also requests the `MANAGE_EXTERNAL_STORAGE`
permission so it can write to removable media.
You can pick any file using the system file picker via **Select File**.
The **Select Output** button now opens the system directory picker so you can
choose a destination folder. After selecting both a file and an output
directory, tap **Copy File** to copy the file to that folder. The app will
create the destination directory if it does not already exist.

### Storage permissions

The sample scans several common directories for removable media, including
`/storage`, `/mnt`, `/media`, `/run/media` and `/sdcard`. Items are displayed
alphabetically. On Android 10 and later, directly listing these locations may
fail with "Permission denied" unless the **All files access** permission is
granted. If scanning fails you can still pick a folder anywhere on the device
using **Select Output**, which opens the system directory picker. The app also
shows its own external storage directory obtained via `getExternalStorageDirectory()`.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
