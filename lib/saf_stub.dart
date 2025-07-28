import "dart:io";
import "package:path/path.dart" as path;
class Saf {
  /// Opens the system directory picker and returns the selected URI.
  static Future<String?> openDocumentTree() async {
    // This stub simply returns null as no directory can be chosen
    return null;
  }

  /// Persists the read/write permissions for the provided [uri].
  static Future<bool> persistPermissions(String uri) async {
    // Always return false in the stub implementation.
    return false;
  }

  /// Writes [bytes] as [name] into the directory represented by [uri].
  /// This stub writes to the local filesystem when the [uri] scheme is `file`.
  static Future<void> writeToFile({
    required String uri,
    required String name,
    required List<int> bytes,
  }) async {
    final parsed = Uri.tryParse(uri);
    if (parsed != null && parsed.scheme == 'file') {
      final file = File(path.join(parsed.toFilePath(), name));
      await file.create(recursive: true);
      await file.writeAsBytes(bytes, flush: true);
    }
  }
}
