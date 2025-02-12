import 'dart:async';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';

class Archives {
  static Future<bool> unzipFile({required String zipFile, required String folder}) async {
    try {
      final bytes = File(zipFile).readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(bytes);

      for (final f in archive) {
        final fileName = f.name;

        if (f.isFile) {
          final data = f.content as List<int>;

          final file = File('$folder/$fileName');
          await file.create(recursive: true);
          await file.writeAsBytes(data);
        } else {
          final dir = Directory('$folder/$fileName');
          await dir.create(recursive: true);
        }
      }
    } catch (e) {
      debugPrint('ArchiveAssistant - unzipFile: $e');
      return false;
    }

    return true;
  }

  static List<int> inflate(List<int> data) => const ZLibDecoder().decodeBytes(data);
}
