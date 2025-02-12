import 'package:charset/charset.dart';
import 'package:flutter/foundation.dart';
import 'package:gbk_codec/gbk_codec.dart';

import 'int_x.dart';

class XReader {
  int _offset = 0;
  late Uint8List _bytes;
  late ByteData _data;

  XReader(List<int> bytes) {
    _bytes = Uint8List.fromList(bytes);
    _data = ByteData.view(_bytes.buffer);
  }

  int get offset => _offset;

  bool get isEnd => _offset >= _bytes.lengthInBytes;

  int get dataMore => _bytes.lengthInBytes - _offset;

  Uint8List? readBytes(int length) {
    if (_offset + length > _bytes.lengthInBytes) return null;

    final result = _bytes.sublist(_offset, _offset + length);
    _offset += length;

    return result;
  }

  ByteData readBytesAll() {
    final result = ByteData.view(_bytes.buffer, _offset);
    _offset += _bytes.lengthInBytes;

    return result;
  }

  Byte? readByte({int? defaultValue}) {
    if (isEnd) {
      return (defaultValue != null) ? Byte(-1) : null;
    }

    final result = _data.getUint8(_offset);
    _offset++;

    return Byte(result);
  }

  Short? readShort({int? defaultValue}) {
    if (_offset + 2 > _bytes.lengthInBytes) {
      return (defaultValue != null) ? Short(-1) : null;
    }

    final result = _data.getUint16(_offset, Endian.little);
    _offset += 2;

    return Short(result);
  }

  int? readInt({int? defaultValue}) {
    if (_offset + 4 > _bytes.lengthInBytes) return defaultValue;

    final result = _data.getUint32(_offset, Endian.little);
    _offset += 4;

    return result;
  }

  String? readString(int length) {
    if (_offset + length > _bytes.lengthInBytes) return null;

    final codes = _bytes.sublist(_offset, _offset + length);
    _offset += length;

    try {
      return gbkDecode(codes);
    } catch (e) {
      debugPrint(e.toString());
    }

    return '';
  }

  String? readStringX(int length) => readString(length)?.replaceAll('||', '\n');

  String? readUtf16Le(int length) {
    if (_offset + length > _bytes.lengthInBytes) return null;

    var codes = _bytes.sublist(_offset, _offset + length);
    _offset += length;

    // find end mark - 00 00
    int endIndex = 0;
    for (endIndex = 0; endIndex < length; endIndex += 2) {
      if (codes[endIndex] == 0 && codes[endIndex + 1] == 0) break;
    }
    codes = codes.sublist(0, endIndex);

    try {
      final decoder = utf16.decoder as Utf16Decoder;
      return decoder.decodeUtf16Le(codes);
    } catch (e) {
      debugPrint(e.toString());
    }

    return '';
  }

  static String gbkDecode(Uint8List buffer) {
    var pos = 0;

    for (; pos < buffer.length; pos++) {
      if (buffer[pos] == 0) break;
    }

    return gbk_bytes.decode(buffer.sublist(0, pos));
  }

  bool jumpTo(int offset) {
    if (offset < _bytes.length) {
      _offset = offset;
      return true;
    }

    return false;
  }

  int? scanData(Uint8List data) {
    var p = offset;

    while (p + data.length < _bytes.length) {
      if (_bytes[p] == data[0]) {
        bool found = true;

        for (var i = 1; i < data.length; i++) {
          if (data[i] != _bytes[p + i]) {
            found = false;
            break;
          }
        }

        if (found) return p;
      }

      p++;
    }

    return null;
  }
}
