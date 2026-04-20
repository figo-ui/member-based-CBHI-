import 'dart:io' if (dart.library.html) 'web_stubs.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'dart:convert' show base64Encode;


/// Compresses an image file to max 500KB before upload.
/// Returns the path to the compressed file.
/// Falls back to original path if compression fails or on web.
Future<String> compressImageForUpload(String sourcePath, {int maxSizeKb = 500}) async {
  if (kIsWeb) return sourcePath; // Web: no compression needed (handled differently)

  try {
    final file = File(sourcePath);
    if (!file.existsSync()) return sourcePath;

    final originalSize = await file.length();
    final maxBytes = maxSizeKb * 1024;

    // Already small enough
    if (originalSize <= maxBytes) return sourcePath;

    final ext = p.extension(sourcePath).toLowerCase();
    final isJpeg = ext == '.jpg' || ext == '.jpeg';
    final isPng = ext == '.png';

    if (!isJpeg && !isPng) return sourcePath; // Only compress images

    final tempDir = await getTemporaryDirectory();
    final targetPath = p.join(
      tempDir.path,
      'compressed_${DateTime.now().millisecondsSinceEpoch}${isJpeg ? '.jpg' : '.jpg'}',
    );

    // Start with quality 85, reduce if still too large
    int quality = 85;
    Uint8List? compressed;

    while (quality >= 40) {
      compressed = await FlutterImageCompress.compressWithFile(
        sourcePath,
        minWidth: 1024,
        minHeight: 1024,
        quality: quality,
        format: CompressFormat.jpeg,
      );

      if (compressed == null) break;
      if (compressed.length <= maxBytes) break;
      quality -= 15;
    }

    if (compressed == null || compressed.isEmpty) return sourcePath;

    final targetFile = File(targetPath);
    await targetFile.writeAsBytes(compressed);

    debugPrint(
      '[ImageUtils] Compressed ${(originalSize / 1024).toStringAsFixed(0)}KB → '
      '${(compressed.length / 1024).toStringAsFixed(0)}KB (quality: $quality)',
    );

    return targetPath;
  } catch (e) {
    debugPrint('[ImageUtils] Compression failed: $e — using original');
    return sourcePath;
  }
}

/// Converts a local file to base64 string for API upload.
/// Returns null if file doesn't exist.
Future<String?> fileToBase64(String filePath) async {
  if (kIsWeb) return null;
  try {
    final file = File(filePath);
    if (!file.existsSync()) return null;
    final bytes = await file.readAsBytes();
    return base64Encode(bytes);
  } catch (_) {
    return null;
  }
}


