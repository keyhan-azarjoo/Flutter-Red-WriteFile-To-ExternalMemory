import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'External Storage Manager',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ExternalDeviceListPage(),
    );
  }
}

class ExternalDeviceListPage extends StatefulWidget {
  const ExternalDeviceListPage({Key? key}) : super(key: key);

  @override
  State<ExternalDeviceListPage> createState() => _ExternalDeviceListPageState();
}

class _ExternalDeviceListPageState extends State<ExternalDeviceListPage> {
  List<Directory> devices = [];

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    final status = await Permission.storage.request();
    if (!status.isGranted) return;

    final storageDir = Directory('/storage');
    final dirs = storageDir
        .listSync()
        .whereType<Directory>()
        .where((d) => !d.path.contains('emulated'))
        .toList();
    setState(() {
      devices = dirs;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('External Devices')),
      body: ListView.builder(
        itemCount: devices.length,
        itemBuilder: (context, index) {
          final dir = devices[index];
          return ListTile(
            title: Text(p.basename(dir.path)),
            subtitle: Text(dir.path),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FileExplorerPage(root: dir),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class FileExplorerPage extends StatefulWidget {
  final Directory root;
  const FileExplorerPage({Key? key, required this.root}) : super(key: key);

  @override
  State<FileExplorerPage> createState() => _FileExplorerPageState();
}

class _FileExplorerPageState extends State<FileExplorerPage> {
  late Directory currentDir;

  @override
  void initState() {
    super.initState();
    currentDir = widget.root;
  }

  void _refresh() {
    setState(() {});
  }

  Future<void> _addFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      final destDir = await FilePicker.platform.getDirectoryPath(dialogTitle: 'Select destination folder');
      if (destDir != null) {
        final file = File(result.files.single.path!);
        final newPath = p.join(destDir, p.basename(file.path));
        await file.copy(newPath);
        _refresh();
      }
    }
  }

  Future<void> _deleteEntity(FileSystemEntity entity) async {
    if (await entity.exists()) {
      await entity.delete(recursive: true);
      _refresh();
    }
  }

  Future<void> _renameEntity(FileSystemEntity entity) async {
    final controller = TextEditingController(text: p.basename(entity.path));
    final newName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rename'),
          content: TextField(controller: controller),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
    if (newName != null && newName.isNotEmpty) {
      final newPath = p.join(p.dirname(entity.path), newName);
      await entity.rename(newPath);
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final entities = currentDir.listSync();
    return Scaffold(
      appBar: AppBar(title: Text(currentDir.path)),
      floatingActionButton: FloatingActionButton(
        onPressed: _addFile,
        child: const Icon(Icons.add),
      ),
      body: ListView.builder(
        itemCount: entities.length,
        itemBuilder: (context, index) {
          final entity = entities[index];
          final name = p.basename(entity.path);
          return ListTile(
            leading: Icon(entity is Directory ? Icons.folder : Icons.insert_drive_file),
            title: Text(name),
            onTap: () {
              if (entity is Directory) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FileExplorerPage(root: entity),
                  ),
                );
              }
            },
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'delete':
                    _deleteEntity(entity);
                    break;
                  case 'rename':
                    _renameEntity(entity);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete'),
                ),
                const PopupMenuItem(
                  value: 'rename',
                  child: Text('Rename'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
