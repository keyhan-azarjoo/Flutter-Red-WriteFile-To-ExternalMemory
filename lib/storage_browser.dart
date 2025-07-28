import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

class StorageBrowser extends StatefulWidget {
  final Directory directory;
  const StorageBrowser({super.key, required this.directory});

  @override
  State<StorageBrowser> createState() => _StorageBrowserState();
}

class _StorageBrowserState extends State<StorageBrowser> {
  late Directory _dir;
  List<FileSystemEntity> _items = [];

  @override
  void initState() {
    super.initState();
    _dir = widget.directory;
    _refresh();
  }

  Future<void> _refresh() async {
    final items = await _dir.list().toList();
    items.sort((a, b) =>
        p.basename(a.path).toLowerCase().compareTo(p.basename(b.path).toLowerCase()));
    setState(() {
      _items = items;
    });
  }

  Future<void> _addFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.single.path == null) return;
    final src = File(result.files.single.path!);
    final dest = File(p.join(_dir.path, p.basename(src.path)));
    await src.copy(dest.path);
    _refresh();
  }

  Future<void> _delete(FileSystemEntity entity) async {
    await entity.delete(recursive: true);
    _refresh();
  }

  Future<void> _rename(FileSystemEntity entity) async {
    final TextEditingController controller =
        TextEditingController(text: p.basename(entity.path));
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename'),
        content: TextField(controller: controller),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, controller.text),
              child: const Text('OK')),
        ],
      ),
    );
    if (newName == null || newName.isEmpty) return;
    final newPath = p.join(_dir.path, newName);
    if (entity is File) {
      await entity.rename(newPath);
    } else if (entity is Directory) {
      await entity.rename(newPath);
    }
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(p.basename(_dir.path))),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView.builder(
          itemCount: _items.length,
          itemBuilder: (context, index) {
            final item = _items[index];
            final isDir = item is Directory;
            return ListTile(
              leading: Icon(isDir ? Icons.folder : Icons.insert_drive_file),
              title: Text(p.basename(item.path)),
              onTap: isDir
                  ? () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StorageBrowser(
                            directory: Directory(item.path),
                          ),
                        ),
                      )
                  : null,
              trailing: PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'delete') {
                    _delete(item);
                  } else if (v == 'rename') {
                    _rename(item);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                  PopupMenuItem(value: 'rename', child: Text('Rename')),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addFile,
        child: const Icon(Icons.add),
      ),
    );
  }
}
