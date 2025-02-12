import 'dart:io';

import 'package:flutter/foundation.dart';

import '../common/x_reader.dart';
import 'cbl3_manual.dart';

class CBL3File {
  static const kManualIndexesOffset = 0x10440;
  static const kBaseIndexesAreaSize = 0x08A00;
  static const kBaseManualLength = 0x1000;

  String? name, source, creator, creatorEmail, createTime, modifyTime, comment;

  List<CBL3Manual> manuals = [];

  CBL3File.loadFile(String filePath) {
    final data = File(filePath).readAsBytesSync();
    load(data);
  }

  CBL3File.loadData(Uint8List data) {
    load(data);
  }

  bool load(Uint8List data) {
    final reader = XReader(data);

    final spec = reader.readString(16);
    debugPrint('CBL spec: $spec');

    final version = reader.readInt();
    debugPrint('CBL version: $version');

    // skip 32 bytes
    reader.readBytes(32);
    // skip FF FF FF 7F 00 00 00 00 80 00 00 00
    reader.readBytes(12);

    name = reader.readUtf16Le(512);
    source = reader.readUtf16Le(256);
    creator = reader.readUtf16Le(64);
    creatorEmail = reader.readUtf16Le(64);
    createTime = reader.readUtf16Le(64);
    modifyTime = reader.readUtf16Le(64);
    comment = reader.readUtf16Le(128);

    // manual index area
    if (!reader.jumpTo(kManualIndexesOffset)) return false;

    List<CBL3Manual> manualIndexes = [];

    // skip 07 00 00 00 / 07 4E FD 56 / 05 00 00 00
    var mark = reader.readInt();
    while (mark == 7 || mark == 5 || mark == 0x56fd4e07) {
      final manualIndex = readManualIndexes(reader);
      if (manualIndex != null) manualIndexes.add(manualIndex);
      mark = reader.readInt();
    }

    // manual data area
    int? firstRecordOffset = reader.scanData(Uint8List.fromList(
      [0x43, 0x43, 0x42, 0x72, 0x69, 0x64, 0x67, 0x65, 0x20, 0x52, 0x65, 0x63, 0x6f, 0x72, 0x64, 0x00],
    ));

    final times = (reader.offset - kManualIndexesOffset) ~/ kBaseIndexesAreaSize + 1;
    var manualOffset = firstRecordOffset ?? kManualIndexesOffset + kBaseIndexesAreaSize * times;

    for (int i = 0; i < manualIndexes.length; i++) {
      if (!reader.jumpTo(manualOffset)) return false;

      final manualLoading = manualIndexes[i];
      final length = manualLoading.length;

      manualOffset += kBaseManualLength * manualLoading.lengthTimes;

      final data = reader.readBytes(length);
      if (data == null) return false;

      try {
        final success = manualLoading.load(XReader(data));
        if (success) manuals.add(manualLoading);
      } catch (e) {
        debugPrint('CBL3x Load manual: $e');
      }
    }

    return true;
  }

  CBL3Manual? readManualIndexes(XReader reader) {
    final index = reader.readInt();

    final lengthTimes = reader.readInt();

    final length = reader.readInt();

    // skip 00 00 00 00
    reader.readInt();

    final uuid = reader.readUtf16Le(76);

    // skip 00 00 00 00
    reader.readInt();

    final title = reader.readUtf16Le(176);

    return CBL3Manual(index!, lengthTimes!, length!, uuid!, title!);
  }

  CBL3Manual manualAtIndex(int index) => manuals[index];

  int manualCount() => manuals.length;
}
