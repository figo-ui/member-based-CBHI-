import 'package:flutter/foundation.dart' show kIsWeb;

// dart:io is imported conditionally – on web these classes are stubs.
// We guard all usage with kIsWeb at runtime.
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class LocalAttachmentStore {
  LocalAttachmentStore._();

  /// Copies [sourcePath] to a persistent app-local folder and returns the new
  /// path.  On web (where [dart:io] file operations are not available) the
  /// original path is returned as-is.
  static Future<String> persist(
    String sourcePath, {
    required String category,
  }) async {
    // Web: no filesystem access – return the source path unchanged.
    if (kIsWeb) {
      return sourcePath;
    }

    try {
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        return sourcePath;
      }

      final dbPath = await getDatabasesPath();
      final targetDirectory = Directory(
        p.join(dbPath, '..', 'attachments', category),
      );
      if (!await targetDirectory.exists()) {
        await targetDirectory.create(recursive: true);
      }

      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${p.basename(sourcePath)}';
      final targetPath = p.join(targetDirectory.path, fileName);
      final copiedFile = await sourceFile.copy(targetPath);
      return copiedFile.path;
    } catch (_) {
      // Fallback: return original path if any I/O error occurs.
      return sourcePath;
    }
  }
}
