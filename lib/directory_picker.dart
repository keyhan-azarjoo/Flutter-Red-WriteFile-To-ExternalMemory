import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

/// A simple directory picker that lets the user navigate directories
/// starting from [initialDirectory] and select a destination directory.
class DirectoryPicker extends StatefulWidget {
  final Directory initialDirectory;
  const DirectoryPicker({super.key, required this.initialDirectory});

  @override
  State<DirectoryPicker> createState() => _DirectoryPickerState();
}

class _DirectoryPickerState extends State<DirectoryPicker> {
  late Directory _dir;
  List<Directory> _subDirs = [];

  @override
  void initState() {
    super.initState();
    _dir = widget.initialDirectory;
    _refresh();
  }

  Future<void> _refresh() async {
    final entries = await _dir.list().whereType<Directory>().toList();
    entries.sort(
      (a, b) => p.basename(a.path).toLowerCase().compareTo(
            p.basename(b.path).toLowerCase(),
          ),
    );
    setState(() => _subDirs = entries);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(p.basename(_dir.path))),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView.builder(
          itemCount: _subDirs.length,
          itemBuilder: (context, index) {
            final d = _subDirs[index];
            return ListTile(
              leading: const Icon(Icons.folder),
              title: Text(p.basename(d.path)),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DirectoryPicker(initialDirectory: d),
                ),
              ).then((value) {
                if (value != null) Navigator.pop(context, value);
              }),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pop(context, _dir),
        child: const Icon(Icons.check),
      ),
    );
  }
}
