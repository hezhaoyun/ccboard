import 'dart:io';

import '../common/x_reader.dart';
import 'base/manual_base.dart';
import 'cbl/cbl2_file.dart';
import 'cbl/cbl3_file.dart';

class CBLFile {
  String path;

  CBL2File? _cbl2file;
  CBL3File? _cbl3file;

  CBLFile(this.path) {
    final data = File(path).readAsBytesSync();

    if (data.length > 16) {
      final header = data.sublist(0, 16);
      final reader = XReader(header);

      final mark = reader.readString(8);
      if (mark == 'CCBridge') {
        final mark2 = reader.readInt();
        if (mark2 == 0x00000015) {
          // version 2.1 ... 2.x
          _cbl2file = CBL2File.loadData(data);
        } else if (mark2 == 0x7262694C) {
          // Libr... 3.x
          _cbl3file = CBL3File.loadData(data);
        }
      }
    }
  }

  String get version {
    if (_cbl2file != null) return '2.x';
    if (_cbl3file != null) return '3.x';
    return 'unknown';
  }

  String? get name {
    if (_cbl2file != null) return _cbl2file!.name();
    if (_cbl3file != null) return _cbl3file!.name!;
    return null;
  }

  List<Manual>? get manuals {
    if (_cbl2file != null) return _cbl2file!.manuals;
    if (_cbl3file != null) return _cbl3file!.manuals;
    return null;
  }

  Manual? manualAtIndex(int index) {
    if (_cbl2file != null) return _cbl2file!.manualAtIndex(index);
    if (_cbl3file != null) return _cbl3file!.manualAtIndex(index);
    return null;
  }

  int manualCount() {
    if (_cbl2file != null) return _cbl2file!.manualCount();
    if (_cbl3file != null) return _cbl3file!.manualCount();
    return 0;
  }
}
