import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'package:usb_serial/usb_serial.dart';

import 'storage_browser.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'USB File Sender',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'USB File Uploader'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _status = "Idle";
  List<Directory> _devices = [];
  File? _selectedFile;
  Directory? _outputDir;

  @override
  void initState() {
    super.initState();
    _ensurePermission();
  }

  Future<void> _ensurePermission() async {
    final status = await Permission.storage.request();
    if (status.isGranted) {
      _scanStorage();
    } else {
      setState(() => _status = 'Storage permission denied');
    }
  }

  Future<void> _scanStorage() async {
    final possibleRoots = [
      Directory('/storage'),
      Directory('/mnt'),
      Directory('/media'),
      Directory('/run/media'),
      Directory('/sdcard'),
    ];

    final Set<String> seenPaths = {};
    final List<Directory> found = [];

    for (final root in possibleRoots) {
      if (await root.exists()) {
        final entries = await root
            .list()
            .where((e) => e is Directory)
            .cast<Directory>()
            .toList();
        for (final d in entries) {
          final name = p.basename(d.path);
          if (name == 'self' || name == 'emulated') continue;
          if (seenPaths.add(d.path)) {
            found.add(d);
          }
        }
      }
    }

    setState(() => _devices = found);
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (!mounted) return;
    if (result != null && result.files.single.path != null) {
      setState(() => _selectedFile = File(result.files.single.path!));
    }
  }

  Future<void> _selectOutputDirectory() async {
    final path = await FilePicker.platform.getDirectoryPath();
    if (!mounted) return;
    if (path != null) {
      setState(() => _outputDir = Directory(path));
    }
  }

  Future<void> _copySelectedFile() async {
    if (_selectedFile == null || _outputDir == null) return;
    try {
      final destPath = p.join(_outputDir!.path, p.basename(_selectedFile!.path));
      await _selectedFile!.copy(destPath);
      setState(() => _status = 'File copied to ${_outputDir!.path}');
    } catch (e) {
      setState(() => _status = 'Failed to copy file: $e');
    }
  }

  Future<void> downloadAndSendToUsb(String url) async {
    setState(() => _status = "Downloading file...");
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        setState(() => _status = "Failed to download file");
        return;
      }
      final Uint8List fileBytes = response.bodyBytes;

      setState(() => _status = "Searching for USB device...");
      List<UsbDevice> devices = await UsbSerial.listDevices();
      if (devices.isEmpty) {
        setState(() => _status = "No USB device found");
        return;
      }

      setState(() => _status = "Connecting to USB device...");
      UsbPort? port = await devices[0].create();
      if (port == null) {
        setState(() => _status = "Failed to create USB port");
        return;
      }

      bool openResult = await port.open();
      if (!openResult) {
        setState(() => _status = "Failed to open USB port");
        return;
      }

      await port.setDTR(true);
      await port.setRTS(true);
      await port.setPortParameters(
        9600,
        UsbPort.DATABITS_8,
        UsbPort.STOPBITS_1,
        UsbPort.PARITY_NONE,
      );

      setState(() => _status = "Sending data...");
      await port.write(fileBytes);
      setState(() => _status = "Data sent to USB device");

      await port.close();
    } catch (e) {
      setState(() => _status = "Error: $e");
    }
  }


  @override
  Widget build(BuildContext context) {
    const fileUrl = "https://stagingiosmls.blob.core.windows.net/packages/9cf617e2-d5b0-4d87-bc72-b6de527e4eda/e5d78222-d647-4609-9482-af2f43ec4795/Dallas-20250616160004.zip"; // replace with real URL

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(_status, textAlign: TextAlign.center),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => downloadAndSendToUsb(fileUrl),
                  child: const Text("Download & Upload to USB"),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _pickFile,
                  child: const Text('Select File'),
                ),
                if (_selectedFile != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      p.basename(_selectedFile!.path),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _selectOutputDirectory,
                  child: const Text('Select Output'),
                ),
                if (_outputDir != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      _outputDir!.path,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: (_selectedFile != null && _outputDir != null)
                      ? _copySelectedFile
                      : null,
                  child: const Text('Copy File'),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _scanStorage,
              child: ListView.builder(
                itemCount: _devices.length,
                itemBuilder: (context, index) {
                  final d = _devices[index];
                  return ListTile(
                    title: Text(p.basename(d.path)),
                    subtitle: Text(d.path),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StorageBrowser(directory: d),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
