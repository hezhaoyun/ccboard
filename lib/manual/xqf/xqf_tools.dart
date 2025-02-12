import 'package:flutter/foundation.dart';

import '../common/int_x.dart';
import '../common/x_reader.dart';
import 'xqf_base.dart';

class StoreNode {
  late Byte from, to, childTag, reserved;
  String comment = '';

  StoreNode(XReader reader) {
    from = reader.readByte(defaultValue: -1)!;
    to = reader.readByte(defaultValue: -1)!;
    childTag = reader.readByte(defaultValue: -1)!;
    reserved = reader.readByte(defaultValue: -1)!;
  }
}

class XQFStream {
  static const pattern = '[(C) Copyright Mr. Dong Shiwei.]';

  XReader reader;
  Uint8List? f32Keys;

  XQFStream(this.reader);

  bool get isEnd => reader.isEnd;

  void setKeyBytes(Uint8List keys) {
    f32Keys = Uint8List(32);
    for (var i = 0, length = pattern.length; i < length; i++) {
      f32Keys![i] = pattern.codeUnitAt(i) & keys[i % 4];
    }
  }

  XQFHeader readHeader() {
    final data = readData(1024);
    return XQFHeader(XReader(data));
  }

  StoreNode readNodePart() {
    final data = readData(4);
    return StoreNode(XReader(data));
  }

  int readNodeCommentSize() {
    final data = readData(4);
    return XReader(data).readInt() ?? -1;
  }

  String readComment(int remarkSize) {
    final data = readData(remarkSize);
    return XReader.gbkDecode(data.buffer.asUint8List());
  }

  Uint8List readData(int length) {
    var pos = reader.offset;

    final orgData = reader.readBytes(length);
    final processedData = Uint8List(length);

    for (var i = 0; i < length; i++) {
      final keyByte = f32Keys![pos % 32];
      processedData[i] = orgData![i] - keyByte;
      pos++;
    }

    return processedData;
  }
}
