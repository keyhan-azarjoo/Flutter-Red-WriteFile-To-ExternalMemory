# External Storage Manager

This Flutter example lists removable storage devices (such as USB drives) mounted under `/storage` and allows basic file operations on them.

Features:

- Display connected external storage devices.
- Browse the contents of a selected device.
- Add files to the device using a file picker and destination selector.
- Delete or rename existing files and folders.

The code relies on the `permission_handler` and `file_picker` packages for storage access and selecting files/folders.
