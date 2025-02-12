import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../cchess/Knowledge/fen.dart';
import 'base/manual_base.dart';

class Moves {
  // 默认分枝，对应的编号为0（省略）
  // [DhtmlXQ_movelist]774772427967706289798081[/DhtmlXQ_movelist]

  // 表示从默认（0）分枝的第 2 步上增加的变着，编号为 1
  // [DhtmlXQ_move_0_2_1]12427967102289790010[/DhtmlXQ_move_0_2_1]

  // 表示从编号为 1 的变着的第 7 步上增加的变着，编号为 3
  // [DhtmlXQ_move_1_7_3]19071017[/DhtmlXQ_move_1_7_3]

  late int _baseBranchNo; // 所基于的变着编号
  late int _startIndex; // 所基于的变着序列的第几步
  late int _branchNo; // 此变着编号

  final String _list;

  // 计算在此列表中的招法过些
  int _index = 0;

  Moves(String header, this._list) {
    // 0 是 cloud manual 唯一列表名，而 DhtmlXQ_movelist 是原来的 .crm 的唯一着法列表名
    if (header == '0' || header == 'DhtmlXQ_movelist') {
      // default branch-0
      _baseBranchNo = -1;
      _startIndex = 1;
      _branchNo = 0;
    } else {
      // DhtmlXQ_move_0_47_1
      final re = RegExp(r'(\d+)_(\d+)_(\d+)');
      final match = re.firstMatch(header);

      if (match != null) {
        _baseBranchNo = int.parse(match.group(1)!);
        _startIndex = int.parse(match.group(2)!);
        _branchNo = int.parse(match.group(3)!);
      }
    }
  }

  TreeNode? nextMove() {
    if (_index * 4 >= _list.length) return null;

    final from = int.parse(_list.substring(4 * _index, 4 * _index + 2));
    final to = int.parse(_list.substring(4 * _index + 2, 4 * (_index + 1)));

    final fromRow = from % 10, fromCol = from ~/ 10;
    final toRow = to % 10, toCol = to ~/ 10;

    final node = TreeNode(_startIndex + _index, fromRow * 9 + fromCol, toRow * 9 + toCol);

    _index++;

    return node;
  }

  void rewindMoveIndex() => _index = 0;
}

class Comment {
  // 初始状态的注释
  // comment0:balabala

  // 默认分枝的第一步的注释
  // comment1:balabala

  // 编号为 1 的变着的第 2 步的注释
  // comment1_2:balabala

  // 编号为 2 的变着的第 5 步的注释
  // comment2_5:balabala

  late int baseBranchNo, moveIndex;
  String comment;

  Comment(String header, this.comment) {
    if (header.contains('_')) {
      final re = RegExp(r'(\d+)_(\d+)');
      final match = re.firstMatch(header);

      if (match != null) {
        baseBranchNo = int.parse(match.group(1)!);
        moveIndex = int.parse(match.group(2)!);
      }
    } else {
      final re = RegExp(r'(\d+)');
      final match = re.firstMatch(header);

      if (match != null) {
        baseBranchNo = 0;
        moveIndex = int.parse(match.group(1)!);
      }
    }

    comment = comment.replaceAll('||', '\n');
  }
}

class CRManual implements Manual {
  late int id;
  late String initBoard, clazz;

  dynamic movesData, commentsData;

  @override
  late String title, event, red, black, result, startFen;

  // lazy loading
  List<Moves> movesList = [];
  List<Comment> comments = [];

  final Map<String, dynamic> _values;

  CRManual(this._values) {
    try {
      id = int.parse(_values['id']);
    } catch (e) {
      id = 0;
    }

    title = _values['title'];
    event = _values['event'];
    clazz = _values['class'] ?? _values['clazz'] ?? '';

    red = _values['red'];
    black = _values['black'];

    result = _values['result'];

    // cloud manual 格式更新，对之前老用户保存的对局格式 .crm 作兼容：
    // 前者是 cloud manual 的格式，后者是老版本的 .crm 的格式
    // cloud manual 中 movelist 是数组，而 .crm 中 move_list 是字符串
    // cloud manual 中 comments 是数组，而 .crm 中 comment_list 是字符串

    initBoard = _values['binit'] ?? _values['init_board'] ?? '';
    movesData = _values['movelist'] ?? _values['move_list'] ?? '';
    commentsData = _values['comments'] ?? _values['comment_list'] ?? '';

    startFen = Fen.fromCrManualBoard(initBoard);
  }

  @override
  ManualTree? createTree() {
    movesList = fetchMoves();
    comments = fetchComments();

    if (movesList.isEmpty) return null;

    final master = movesList[0]; // default branch
    final root = TreeNode.empty();

    visitMoveList(master, root);

    return ManualTree(root);
  }

  void visitMoveList(Moves master, TreeNode baseNode) {
    var node = master.nextMove(), parent = baseNode;

    while (node != null) {
      node.parent = parent;
      parent.addChild(node);

      node.comment = findComment(master._branchNo, node.moveIndex);

      final branches = findBranches(master._branchNo, node.moveIndex);

      for (var branch in branches) {
        // 找到的分枝的第一个节点，是当前节点的兄弟节点而非子节点
        visitMoveList(branch, node.parent!);
      }

      parent = node;
      node = master.nextMove();
    }
  }

  List<Moves> fetchMoves() {
    if (movesData == null) return [];

    final result = <Moves>[];

    if (movesData is String) {
      // .crm
      final re = RegExp(r'\[(.+?)\](.+)\[/\1\]');
      final matches = re.allMatches(movesData);
      for (var m in matches) {
        result.add(Moves(m.group(1)!, m.group(2)!));
      }
    } else {
      // cloud manual
      movesData.forEach((ml) {
        final segments = ml.split('::');
        if (segments.length == 2) {
          result.add(Moves(segments[0], segments[1]));
        }
      });
    }

    result.sort((a, b) => a._branchNo - b._branchNo);

    return result;
  }

  List<Comment> fetchComments() {
    if (commentsData == null) return [];

    final result = <Comment>[];

    if (commentsData is String) {
      // .crm
      final lines = commentsData.split('=|=');
      lines.forEach((c) {
        final segments = c.split(':');
        if (segments.length == 2) {
          result.add(Comment(segments[0], segments[1]));
        }
      });
    } else {
      // cloud
      commentsData.forEach((c) {
        final segments = c.split('::');
        if (segments.length == 2) {
          result.add(Comment(segments[0], segments[1]));
        }
      });
    }

    result.sort((a, b) => (a.baseBranchNo * 1000 + a.moveIndex) - (b.baseBranchNo * 1000 - b.moveIndex));

    return result;
  }

  List<Moves> findBranches(int branchNo, int moveIndex) {
    var mls = <Moves>[];

    for (var i = 1; i < movesList.length; i++) {
      final ml = movesList[i];
      if (ml._baseBranchNo == branchNo && ml._startIndex == moveIndex) {
        mls.add(ml);
      }
    }

    return mls;
  }

  String findComment(int branchNo, int moveIndex) {
    for (var i = 0; i < comments.length; i++) {
      final c = comments[i];
      if (c.baseBranchNo == branchNo && c.moveIndex == moveIndex) {
        return c.comment;
      }
    }

    return '';
  }

  @override
  Future<bool> writeTo(File file) async {
    final map = {
      'id': id,
      'title': title,
      'event': event,
      'class': clazz,
      'red': red,
      'black': black,
      'result': result,
      'init_board': initBoard,
      'move_list': movesData,
      'comment_list': commentsData,
    };

    final contents = jsonEncode(map);

    try {
      await file.writeAsString(contents);
    } catch (e) {
      debugPrint(e.toString());
      return false;
    }

    return true;
  }

  @override
  String toString() {
    var desc = title;

    if (event.isNotEmpty) desc += '\n$event';
    if (clazz.isNotEmpty) {
      desc += '\n类型 $clazz';
    }
    if (red.isNotEmpty && black.isNotEmpty) desc += '\n$red vs $black';
    if (result.isNotEmpty) {
      desc += '\n结果 $result';
    }

    return desc;
  }

  @override
  Key? data;

  @override
  String get filePath => _values['filePath'];

  @override
  set filePath(String filePath) => _values['filePath'] = filePath;
}
