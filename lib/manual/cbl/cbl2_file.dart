import 'dart:io';

import 'package:flutter/foundation.dart';

import '../common/x_reader.dart';
import '../common/archives.dart';
import 'cbl2_manual.dart';

/// 棋库文件信息结构(共20字节)
/// {
/// CBL棋库文件标识(8字节,固定为'CCBridge')
/// 版本(4字节)
/// 压缩率方案(4字节)
/// 数据段大小标记(4字节)
/// }
class CBL2FileInfo {
  /// 偏移量08H处开始4字节为棋库的版本标识，本说明书介绍的版本即为15 00 00 00 的版本(2.1版)。
  /// 编程时棋库格式是否可识别以此为唯一依据。
  int version = 0;

  /// 00 00 00 00 不压缩
  /// 01 00 00 00 低压缩
  /// 02 00 00 00 中压缩
  /// 03 00 00 00 高压缩
  int compressMethod = 0;

  /// 偏移量10H处开始4字节为数据区在不压缩状态时的大小(除去标明棋库文件信息的前20字节，
  /// 其它部分都为数据区)。也就是说在不压缩状态时，该处值等于文件大小减去20的值。如果棋库
  /// 处于压缩状态，则从14h开始到结束都为压缩存储。
  int length = 0;

  CBL2FileInfo.initWithVersion(int v, int cm, int l) {
    version = v;
    compressMethod = cm;
    length = l;
  }

  CBL2FileInfo.initWithXReader(XReader reader) {
    const identify = 'CCBridge';

    final mark = reader.readStringX(8);

    if (identify == mark) {
      version = reader.readInt(defaultValue: -1)!;
      compressMethod = reader.readInt(defaultValue: -1)!;
      length = reader.readInt(defaultValue: -1)!;
    } else {
      debugPrint('CBL format is missing!');
    }
  }

  String compressMethodDesc() {
    switch (compressMethod) {
      case 1:
        return '低压缩';
      case 2:
        return '中压缩';
      case 3:
        return '高压缩';
      default:
        return '未压缩';
    }
  }
}

/// 棋库信息按次序包括有：
/// {
/// 棋库名（不定长）
/// 相关资源（不定长）
/// Other*（不定长，目前尚未使用，为4字节）
/// 创建人（不定长）
/// 创建人EMail（不定长）
/// 创建日期（定长，19字节）
/// 最后更新日期（定长，19字节）
/// 棋谱数量（定长，4字节）
/// 棋库说明（不定长）
/// }
/// 不固定大小的项采用的是前4字节标明大小，后面为具体数据的表示方法，注意：前4字
/// 节标明的大小不包括这4个字节本身。比如：有一项的值为ABC,则表示为：03 00 00 00 41 42 43
/// 其中Other*这一项为预留项，目前尚未使用，所以固定为00 00 00 00,但建议把这一项作为
/// 不定长项处理（事实上这一项为不定长项），以便将来使用时不至于发生不兼容的问题。
class CBL2Info {
  String name = '';
  String resource = '';
  String other = '';
  String creator = '';
  String creatorEmail = '';
  String createDate = '';
  String lastUpdate = '';
  int manualCount = 0;
  String desc = '';

  CBL2Info.initWithXReader(XReader reader) {
    var length = reader.readInt(defaultValue: -1)!;
    if (length > 0) name = reader.readStringX(length) ?? '';

    length = reader.readInt(defaultValue: -1)!;
    if (length > 0) resource = reader.readStringX(length) ?? '';

    length = reader.readInt(defaultValue: -1)!;
    if (length > 0) other = reader.readStringX(length) ?? '';

    length = reader.readInt(defaultValue: -1)!;
    if (length > 0) creator = reader.readStringX(length) ?? '';

    length = reader.readInt(defaultValue: -1)!;
    if (length > 0) creatorEmail = reader.readStringX(length) ?? '';

    createDate = reader.readStringX(19) ?? '';
    lastUpdate = reader.readStringX(19) ?? '';

    manualCount = reader.readInt() ?? 0;

    length = reader.readInt() ?? 0;
    if (length > 0) {
      desc = (reader.readStringX(length) ?? '').replaceAll('||', '\n');
    }
  }

  String description() {
    var info = '';

    if (name.isNotEmpty) {
      info += '棋库名称 $name\n';
    }
    if (resource.isNotEmpty) {
      info += '相关资源 $resource\n';
    }
    if (other.isNotEmpty) {
      info += '其它 $other\n';
    }
    if (creator.isNotEmpty) {
      info += '创建人 $creator\n';
    }
    if (creatorEmail.isNotEmpty) {
      info += '创建人EMail $creatorEmail\n';
    }
    if (createDate.isNotEmpty) {
      info += '创建日期 $createDate\n';
    }
    if (lastUpdate.isNotEmpty) {
      info += '最后更新 $lastUpdate\n';
    }

    info += '棋谱数量 $manualCount\n';

    if (desc.isNotEmpty) {
      info += '棋库说明 $desc\n';
    }

    return info;
  }
}

class CBL2File {
  List<CBL2Manual> manuals = [];

  late CBL2FileInfo fileInfo;
  late CBL2Info libInfo;

  CBL2File.loadFile(String filePath) {
    load(File(filePath).readAsBytesSync());
  }

  CBL2File.loadData(Uint8List data) {
    load(data);
  }

  bool load(Uint8List data) {
    var reader = XReader(data);

    fileInfo = CBL2FileInfo.initWithXReader(reader);

    final compressMethod = fileInfo.compressMethod;

    if (compressMethod > 0) {
      final compressedData = reader.readBytesAll();
      final inflateData = Archives.inflate(compressedData.buffer.asUint8List());

      reader = XReader(inflateData);
    }

    libInfo = CBL2Info.initWithXReader(reader);

    for (var i = 0; i < libInfo.manualCount; i++) {
      manuals.add(CBL2Manual.initWithXReader(reader));
    }

    return true;
  }

  String name() => libInfo.name;

  String info() => libInfo.description();

  void addManual(CBL2Manual manual) => manuals.add(manual);

  CBL2Manual manualAtIndex(int index) => manuals[index];

  int manualCount() => manuals.length;
}
