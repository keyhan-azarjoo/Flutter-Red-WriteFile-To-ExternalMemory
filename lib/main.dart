import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

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
  Uint8List? _selectedBytes;
  String? _selectedFileName;
  Directory? _outputDir;

  Future<bool> _requestStoragePermissions() async {
    var status = await Permission.storage.request();
    if (Platform.isAndroid) {
      var manage = await Permission.manageExternalStorage.status;
      if (!manage.isGranted) {
        manage = await Permission.manageExternalStorage.request();
      }
      if (manage.isGranted) {
        status = manage;
      }
    }
    if (!status.isGranted) {
      if (status.isPermanentlyDenied) {
        await openAppSettings();
      }
      return false;
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
    _ensurePermission();
  }

  Future<void> _ensurePermission() async {
    if (await _requestStoragePermissions()) {
      _scanStorage();
    } else {
      setState(() => _status = 'Storage permission denied');
    }
  }

  Future<void> _scanStorage() async {
    final List<Directory> found = [];
    final appDir = await getExternalStorageDirectory();
    if (appDir != null) {
      found.add(appDir);
    }

    final possibleRoots = [
      Directory('/storage'),
      Directory('/mnt'),
      Directory('/media'),
      Directory('/run/media'),
      Directory('/sdcard'),
    ];

    final Set<String> seenPaths = {if (appDir != null) appDir.path};

    for (final root in possibleRoots) {
      if (await root.exists()) {
        try {
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
        } on FileSystemException {
          // Permission denied or inaccessible path.
          continue;
        }
      }
    }

    setState(() => _devices = found);
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (!mounted) return;
    if (result != null) {
      setState(() {
        final file = result.files.single;
        _selectedFileName = file.name;
        _selectedBytes = file.bytes;
        _selectedFile =
            file.path != null ? File(file.path!) : null;
      });
    }
  }

  Future<void> _selectOutputDirectory() async {
    final path = await FilePicker.platform.getDirectoryPath();
    if (!mounted) return;
    if (path != null) {
      if (await _requestStoragePermissions()) {
        setState(() => _outputDir = Directory(path));
      } else {
        setState(() => _status = 'Storage permission denied');
      }
    }
  }

  Future<void> _copySelectedFile() async {
    if (_outputDir == null) return;
    final fileName = _selectedFileName ??
        (_selectedFile != null ? p.basename(_selectedFile!.path) : null);
    if (fileName == null) return;

    final destPath = p.join(_outputDir!.path, fileName);
    if (!await _requestStoragePermissions()) {
      setState(() => _status = 'Storage permission denied');
      return;
    }

    try {
      await _outputDir!.create(recursive: true);
      if (_selectedBytes != null) {
        await File(destPath).writeAsBytes(_selectedBytes!, flush: true);
      } else if (_selectedFile != null) {
        if (!await _selectedFile!.exists()) {
          setState(() => _status = 'Selected file not found');
          return;
        }
        await _selectedFile!.copy(destPath);
      } else {
        return;
      }
      setState(() => _status = 'File copied to ${_outputDir!.path}');
    } catch (e) {
      setState(() => _status = 'Failed to copy file: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    

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
                // Download functionality removed
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _pickFile,
                  child: const Text('Select File'),
                ),
                if (_selectedFile != null || _selectedFileName != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      _selectedFile != null
                          ? p.basename(_selectedFile!.path)
                          : _selectedFileName!,
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
                  onPressed: ((_selectedFile != null || _selectedBytes != null) &&
                          _outputDir != null)
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
