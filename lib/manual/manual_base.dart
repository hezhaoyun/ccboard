import 'dart:io';

import 'package:flutter/foundation.dart';

import 'cbl/cbl2_move.dart';
import 'cbl/cbl3_move.dart';
import 'xqf/xqf_base.dart';

abstract class Manual {
  ManualTree? createTree();

  Future<bool> writeTo(File file);

  String get startFen => '';
  String get red => '';
  String get black => '';
  String get event => '';
  String get result => '';

  String get title => '';
  set title(String title) {}

  String get filePath => '';
  set filePath(String filePath) {}

  Key? data;
}

class TreeNode {
  int moveIndex = -1;
  late int from, to;

  TreeNode? parent;
  String? comment;
  List<TreeNode>? children;
  String? moveName;
  dynamic moveData;

  TreeNode(this.moveIndex, this.from, this.to);

  TreeNode.fromXQFMove(XQFMove move) {
    moveIndex = move.index.value;
    from = XQFMove.crossIndexOf(move.from);
    to = XQFMove.crossIndexOf(move.to);
    comment = move.comment;
    moveData = move;
  }

  TreeNode.fromCBL2Move(CBL2Move move) {
    moveIndex = move.index.value;
    from = move.from;
    to = move.to;
    comment = move.comment;
    moveData = move;
  }

  TreeNode.fromCBL3Move(CBL3Move move) {
    from = move.from!;
    to = move.to!;
    comment = move.comment;
    moveData = move;
  }

  TreeNode.empty({this.comment});

  void addChild(TreeNode node) {
    children ??= [];
    children!.add(node);
  }

  int get branchCount => (children == null) ? 0 : children!.length;

  @override
  String toString() => moveName ?? '$from => $to';
}

class ManualTree {
  late TreeNode _root, _current;

  ManualTree(TreeNode node) {
    _current = _root = node;
  }

  List<TreeNode> nextMoves() => _current.children ?? [];

  TreeNode? prevMove() {
    if (_current.parent != null) {
      _current = _current.parent!;
      return _current;
    }

    return null;
  }

  List<TreeNode>? peekNextMoves() => _current.children;

  void selectBranch(int index) => _current = _current.children![index];

  void rewind() => _current = _root;

  String currentBranchesLink() {
    // 从 _current 节点向 _root 节点逆向遍历，找到从第一步开始，
    // 每一步选择的分枝的索引值，生成一个列表并返回
    final link = <int>[];

    var p = _current;
    while (p != _root) {
      link.insert(0, p.parent!.children!.indexOf(p));
      p = p.parent!;
    }

    return link.join('-');
  }

  bool get atStartPoint => _current == _root;

  bool get hasMoveBranches => _current.children != null && _current.children!.length > 1;

  String? get moveComment => _current.comment;
}
