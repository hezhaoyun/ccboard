import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'common/int_x.dart';
import 'common/stack.dart';
import 'common/x_reader.dart';
import '../cchess/models/piece.dart';
import '../cchess/Knowledge/fen.dart';
import 'base/manual_base.dart';
import 'xqf/xqf_base.dart';
import 'xqf/xqf_tools.dart';

class XQFMovePack {
  XQFMove move;
  TreeNode parent;
  XQFMovePack({required this.move, required this.parent});
}

class XQFManual implements Manual {
  @override
  late String filePath;
  late XQFHeader header;
  late XQFMove root;
  late Byte keyBoard, keyFrom, keyTo;
  late Short keyRemarkSize;

  XQFManual() {
    root = XQFMove.empty();
  }

  Future<void> loadFile(String filePath, {useAssets = false}) async {
    Uint8List bytes;
    this.filePath = filePath;

    if (useAssets) {
      final content = await rootBundle.load(filePath);
      bytes = content.buffer.asUint8List();
    } else {
      final file = File(filePath);
      bytes = await file.readAsBytes();
    }

    loadFromData(bytes);
  }

  @override
  ManualTree? createTree() {
    if (!root.hasLeftChild) return null;

    final rootNode = TreeNode.empty(comment: root.comment);

    final stack = Stack<XQFMovePack>();
    stack.push(XQFMovePack(move: root.leftChild!, parent: rootNode));

    while (stack.isNotEmpty) {
      final p = stack.pop();

      final node = TreeNode.fromXQFMove(p.move);

      p.parent.addChild(node);
      node.parent = p.parent;

      if (p.move.leftChild != null) {
        stack.push(XQFMovePack(move: p.move.leftChild!, parent: node));
      }

      var child = p.move.rightChild;

      while (child != null) {
        final branch = TreeNode.fromXQFMove(child);

        p.parent.addChild(branch);
        branch.parent = p.parent;

        if (child.leftChild != null) {
          stack.push(XQFMovePack(move: child.leftChild!, parent: branch));
        }

        child = child.rightChild;
      }
    }

    return ManualTree(rootNode);
  }

  @override
  Future<bool> writeTo(File file) async {
    final origin = File(filePath);

    try {
      final bytes = await origin.readAsBytes();
      await file.writeAsBytes(bytes);
    } catch (e) {
      debugPrint(e.toString());
      return false;
    }

    return true;
  }

  void loadFromData(Uint8List data) {
    final reader = XReader(data);
    final stream = XQFStream(reader);

    final keyData = Uint8List(4);
    stream.setKeyBytes(keyData);

    header = stream.readHeader();
    if (validateFormat() != 0) return;

    calcSecurityKeys();
    calcRootBoard();
    calcStreamKeys(stream);

    root.moveNo = header.moveNo;

    loadMovesFromStream(stream);
  }

  int validateFormat() {
    if (header.version > 0x12) {
      debugPrint('XQF File version is too height!');
      return -1;
    }

    if (header.signature.value != ('X'.codeUnitAt(0) + ('Q'.codeUnitAt(0) << 8))) {
      debugPrint('Format Error!');
      return -1;
    }

    if (!header.isKeysSumZero) {
      debugPrint('Format Error!');
      return -3;
    }

    return 0;
  }

  void calcSecurityKeys() {
    // 兼容1.0以前的版本
    if (header.version <= 10) {
      keyBoard = Byte(0);
      keyFrom = Byte(0);
      keyTo = Byte(0);
      keyRemarkSize = Short(0);

      return;
    }

    // 以下是密码计算公式
    var bk = header.keyPos;
    keyBoard = (((((bk * bk) * 3 + 9) * 3 + 8) * 2 + 1) * 3 + 8) * bk;

    bk = header.keyFrom;
    keyFrom = (((((bk * bk) * 3 + 9) * 3 + 8) * 2 + 1) * 3 + 8) * keyBoard;

    bk = header.keyTo;
    keyTo = (((((bk * bk) * 3 + 9) * 3 + 8) * 2 + 1) * 3 + 8) * keyFrom;

    var wk = header.keySum.value * 256 + header.keyPos.value;
    keyRemarkSize = Short((wk % 32000) + 767);
  }

  void calcRootBoard() {
    final board = root.board;
    // Byte *ptr = [board mutableBytes];

    final headBoard = header.board!;
    // const Byte *headBoardPtr = [headBoard bytes];

    // 棋子位置循环移动
    for (var i = 0; i < 32; i++) {
      if (header.version >= 12) {
        board[((i + keyBoard.value + 1) % 32)] = headBoard[i];
      } else {
        board[i] = headBoard[i];
      }
    }

    // 棋子位置解密
    for (var i = 0; i < 32; i++) {
      board[i] -= keyBoard.value;
      // For 1.2 or higher
      if (board[i] > 89) board[i] = 0xFF;
    }
  }

  void calcStreamKeys(XQFStream stream) {
    final bytes = <int>[
      ((header.keySum & header.keyMask) | header.keyA).value,
      ((header.keyPos & header.keyMask) | header.keyB).value,
      ((header.keyFrom & header.keyMask) | header.keyC).value,
      ((header.keyTo & header.keyMask) | header.keyD).value
    ];

    final keyBytes = Uint8List.fromList(bytes);

    stream.setKeyBytes(keyBytes);
  }

  void loadMovesFromStream(XQFStream stream) {
    final stack = Stack<XQFMove>();

    stack.push(root);

    while (stack.isNotEmpty) {
      final move = stack.pop();

      loadMove(move, stream);

      /// 因为 Stack 后进选出，所以还是深度优先

      if (move.hasRightChild) {
        // brother node
        stack.push(XQFMove(move.board, move.prevMove, move, null));
      }

      if (move.hasLeftChild) {
        // child node
        stack.push(XQFMove(move.board, move, null, move));
      }
    }
  }

  void loadMove(XQFMove move, XQFStream stream) {
    final node = readNodeFromStream(stream);

    move.orgFrom = node.from - 0x18 - keyFrom;
    move.orgTo = node.to - 0x20 - keyTo;

    move.comment = node.comment;
    move.childTag = node.childTag.value;

    if (move != root) {
      move.moveNo = move.prevMove.moveNo + 1;
      move.board = Uint8List(move.prevMove.board.length);

      for (var i = 0; i < move.board.length; i++) {
        move.board[i] = move.prevMove.board[i];
      }

      doMoveOnBoard(move.board, move.orgFrom.value, move.orgTo.value);
    }
  }

  void doMoveOnBoard(Uint8List board, int from, int to) {
    final fromIndex = indexOnBoard(board, from), toIndex = indexOnBoard(board, to);

    if (fromIndex < 0) {
      throw 'Error - doMove: Bad from index!';
    }

    board[fromIndex] = to;
    if (toIndex > -1) board[toIndex] = -1;
  }

  StoreNode readNodeFromStream(XQFStream stream) {
    final node = stream.readNodePart();

    var commentSize = 0;

    if (header.version <= 10) {
      var flag = 0;
      final childTag = node.childTag.value;

      if ((childTag & 0xF0) != 0) flag |= 0x80;
      if ((childTag & 0x0F) != 0) flag |= 0x40;

      node.childTag = Byte(flag);
      commentSize = stream.readNodeCommentSize();
    } else {
      var childTag = node.childTag.value;
      childTag &= 0xE0;
      node.childTag = Byte(childTag);

      if ((childTag & 0x20) != 0) {
        commentSize = stream.readNodeCommentSize();
      }
    }

    if (commentSize > 0) {
      final realSize = commentSize - keyRemarkSize.value;
      node.comment = stream.readComment(realSize);
    }

    return node;
  }

  static int indexOnBoard(Uint8List board, int pos) {
    for (var i = 0, length = board.length; i < length; i++) {
      if (board[i] == pos) return i;
    }

    return -1;
  }

  @override
  String get startFen {
    final initBoard = root.board;

    final board = List<String>.filled(90, '');
    for (var i = 0; i < board.length; i++) {
      board[i] = Piece.noPiece;
    }

    const pieces = 'RNBAKABNRCCPPPPPrnbakabnrccppppp';

    for (var i = 0; i < 32; i++) {
      final piece = pieces[i];
      final pos = initBoard[i];
      if (pos == 0xFF) continue; // 不在棋盘上了

      board[XQFMove.crossIndexOf(pos)] = piece;
    }

    return Fen.fromBoardSate(board);
  }

  @override
  String get title => header.titleA.isNotEmpty ? header.titleA : header.titleB;

  @override
  String get event => header.matchName;

  @override
  String get red => header.redPlayer;

  @override
  String get black => header.blackPlayer;

  @override
  String get result => header.resultDesc;

  @override
  String toString() => header.description;

  @override
  Key? data;

  @override
  set title(String title) {}
}
