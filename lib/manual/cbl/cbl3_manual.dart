import 'dart:io';

import 'package:flutter/foundation.dart';

import '../common/x_reader.dart';
import '../../cchess/models/piece.dart';
import '../../cchess/knowledge/fen.dart';
import '../base/manual_base.dart';
import 'cbl3_move.dart';

class CBL3Manual extends Manual {
  final int index, lengthTimes, length;
  final String uuid;

  @override
  final String title;

  CBL3Manual(this.index, this.lengthTimes, this.length, this.uuid, this.title);

  String? scriptFile;
  String? title2;
  String? category;
  String? source;
  String? gameCategory; // 赛事分类
  String? game; // 赛事
  String? turn; // 轮次
  String? level; // 组别
  String? desktop; // 台次
  String? date;
  String? address;
  String? timeRule;
  String? _red;
  String? redTeam;
  String? redTime;
  String? redLevelScore;
  String? _black;
  String? blackTeam;
  String? blackTime;
  String? blackLevelScore;
  String? referee; // 裁判员
  String? recorder; // 记录员
  String? narrator; // 解说者
  String? narratorEmail; // 解说者邮件
  String? creator; // 创建者
  String? creatorEmail; // 创建者邮件
  int? type; // 棋局类型：1-实全，2-摆全，3-实残，4-摆残
  String? nature; // 棋局性质
  int? _result; // 棋局结果：0-未知，1-红胜，2-黑胜，3-和局，4-多种结果
  String? endMethod; // 结束方式

  List<int>? board;

  List<CBL3Move> moves = [];

  TreeNode? root;

  bool load(XReader reader) {
    // CCBridge Record
    final spec = reader.readString(16);
    if (spec != 'CCBridge Record') debugPrint('Something wrong!');
    debugPrint('Manual spec: $spec');

    // skip 02 00 00 00
    reader.readInt();
    // skip 16 bytes
    reader.readBytes(16);
    // skip 16 bytes - all 00
    reader.readBytes(16);

    scriptFile = reader.readUtf16Le(128);
    title2 = reader.readUtf16Le(128);
    category = reader.readUtf16Le(256);
    source = reader.readUtf16Le(64);
    gameCategory = reader.readUtf16Le(64);
    game = reader.readUtf16Le(64);
    turn = reader.readUtf16Le(64);
    level = reader.readUtf16Le(32);
    desktop = reader.readUtf16Le(32);
    date = reader.readUtf16Le(64);
    address = reader.readUtf16Le(64);
    timeRule = reader.readUtf16Le(64);
    _red = reader.readUtf16Le(64);
    redTeam = reader.readUtf16Le(64);
    redTime = reader.readUtf16Le(64);
    redLevelScore = reader.readUtf16Le(32);
    _black = reader.readUtf16Le(64);
    blackTeam = reader.readUtf16Le(64);
    blackTime = reader.readUtf16Le(64);
    blackLevelScore = reader.readUtf16Le(32);
    referee = reader.readUtf16Le(64);
    recorder = reader.readUtf16Le(64);
    narrator = reader.readUtf16Le(64);
    narratorEmail = reader.readUtf16Le(64);
    creator = reader.readUtf16Le(64);
    creatorEmail = reader.readUtf16Le(64);

    // skip 128 bytes
    reader.readBytes(128);
    // skip 42 30 34 00
    reader.readInt();

    type = reader.readInt();
    nature = reader.readUtf16Le(32);
    _result = reader.readInt();
    endMethod = reader.readUtf16Le(32);

    // skip 01 00 00 00 01 00 00 00
    reader.readBytes(8);

    board = reader.readBytes(90);

    // skip FF FF FF FF
    final testMark = reader.readInt();
    if (testMark != 0xFFFFFFFF) return false;

    while (reader.dataMore >= 4) {
      var move = CBL3Move.load(reader);
      moves.add(move);
    }

    return true;
  }

  @override
  String get red => _red ?? '';

  @override
  String get black => _black ?? '';

  @override
  String get event => game ?? '';

  @override
  String get result {
    switch (_result) {
      case 0:
        return '未知';
      case 1:
        return '红胜';
      case 2:
        return '黑胜';
      case 3:
        return '和棋';
      case 4:
        return '多种结果';
    }

    return '${_result ?? 0}';
  }

  @override
  String get startFen {
    if (board == null || board!.length != 90) {
      return Fen.defaultPosition;
    }

    const pieces = {
      0x11: 'R',
      0x12: 'N',
      0x13: 'B',
      0x14: 'A',
      0x15: 'K',
      0x16: 'C',
      0x17: 'P',
      0x21: 'r',
      0x22: 'n',
      0x23: 'b',
      0x24: 'a',
      0x25: 'k',
      0x26: 'c',
      0x27: 'p'
    };

    final transBoard = List<String>.filled(90, Piece.noPiece);

    for (var i = 0; i < 90; i++) {
      final p = board![i];
      if ((p >= 0x11 && p <= 0x17) || (p >= 0x21 && p <= 0x27)) {
        transBoard[i] = pieces[p]!;
      }
    }

    return Fen.fromBoardSate(transBoard);
  }

  @override
  ManualTree? createTree() {
    if (moves.isEmpty) return null;

    if (root == null) {
      var move = moves.removeAt(0);
      root = TreeNode.fromCBL3Move(move);

      var current = root!;

      for (var i = 0; i < moves.length; i++) {
        final move = moves[i];
        final child = TreeNode.fromCBL3Move(move);

        current.addChild(child);
        child.parent = current;
        current = child;

        // have branch moves
        if (move.isLast! && i < moves.length) {
          // reverse find the branch mount point
          current = reverseFindBranchParent(current.parent) ?? root!;
        }
      }
    }

    return ManualTree(root!);
  }

  TreeNode? reverseFindBranchParent(TreeNode? current) {
    while (current != null) {
      CBL3Move move = current.children?.last.moveData!;
      if (move.isBranch!) return current;
      current = current.parent;
    }

    return null;
  }

  // 1-实全，2-摆全，3-实残，4-摆残
  String get typeDesc {
    switch (type) {
      case 1:
        return '实战全局';
      case 2:
        return '摆谱全局';
      case 3:
        return '实战全局';
      case 4:
        return '摆谱残局';
    }

    return '$type';
  }

  @override
  String toString() {
    var info = '';

    if (title.isNotEmpty) {
      info += '棋局标题 $title\n';
    }

    info += '棋局类型 $typeDesc\n';

    if (game != null && game!.isNotEmpty) {
      info += '比赛名称 $game\n';
    }

    if (address != null && address!.isNotEmpty) {
      info += '比赛地点 $address\n';
    }
    if (date != null && date!.isNotEmpty) {
      info += '比赛日期 $date\n';
    }
    if (red.isNotEmpty) {
      info += '红方棋手 $red\n';
    }
    if (black.isNotEmpty) {
      info += '黑方棋手 $black\n';
    }

    info += '比赛结果 $result\n';

    if (narrator != null && narrator!.isNotEmpty) {
      info += '讲评人员 $narrator\n';
    }
    if (narratorEmail != null && narratorEmail!.isNotEmpty) {
      info += '讲评人EMail $narratorEmail\n';
    }
    if (creator != null && creator!.isNotEmpty) {
      info += '创建人 $creator\n';
    }
    if (creatorEmail != null && creatorEmail!.isNotEmpty) {
      info += '创建人EMail $creatorEmail\n';
    }

    if (moves.isNotEmpty && moves[0].comment != null) {
      info += '棋谱说明 ${moves[0].comment}\n';
    }

    return info;
  }

  @override
  Future<bool> writeTo(File file) async => false;
}
