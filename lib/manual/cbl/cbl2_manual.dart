import 'dart:io';
import 'dart:typed_data';

import '../../common/stack.dart';
import '../../common/x_reader.dart';
import '../../cchess/models/piece.dart';
import '../../cchess/utils/fen.dart';
import '../manual_base.dart';
import 'cbl2_move.dart';

/// 棋谱信息 {
/// 初始棋图(32字节)
/// 棋局类型(4字节)
/// 比赛名称(不定长)
/// 开始序数(4字节)
/// 棋局标题(不定长)
/// 相关资源(不定长)
/// Other*(不定长，目前尚未使用，所以为4字节，但在编程处理时请把其作为不定长项处理)
/// 比赛地点(不定长)
/// 比赛日期(不定长)
/// 红方棋手(不定长)
/// 黑方棋手(不定长)
/// 结果(4字节)
/// 讲评人(不定长)
/// 讲评人EMail(不定长)
/// 录入人(不定长)
/// 录入人EMail(不定长)
/// 棋谱说明(不定长)
/// 红方先行(1字节)
/// 创建日期(19字节)
/// 最后更新日期(19字节)
/// }
class CBL2ManualInfo {
  /// 初始棋图：
  /// 初始棋图共用32字节表示，每字节对应一颗棋子，对应关系依次为：
  /// 红：车马相仕帅仕相马车炮炮兵兵兵兵兵
  /// 黑：车马象士将士象马车炮炮卒卒卒卒卒
  /// 每字节的高4位用来表示棋子所处X轴的坐标值，低4位表示棋子所处Y轴的坐标值。
  /// 0070H: 1A 2A 3A 4A 5A 6A 7A 8A-9A 28 88 17 37 57 77 97
  /// 0080H: 11 21 31 41 51 61 71 81-91 23 83 14 34 54 74 94
  /// 上面这段数据表示一个完整的初始棋图。
  ///
  /// 如果不是完整棋图，不存在棋子用 00 表示。

  late Uint8List initBoard;

  /// 棋局类型：
  /// 棋局类型用4字节表示，共有四种棋局类型：
  /// 01 00 00 00 实战的全局
  /// 02 00 00 00 摆谱的全局
  /// 03 00 00 00 实战的残局
  /// 04 00 00 00 摆谱的残局

  int type = 0;
  String matchName = '';

  /// 开始序数：
  /// 开始序数为4字节。在实战的残局中，记谱时的序号并不是从第一手开始的，这时就需要
  /// 使用开始序数这个值。在实战的全局、摆谱的全局和摆谱的残局中，该值恒为01 00 00 00

  int beginIndex = 0;
  String title = '';
  String resource = '';
  String other = '';
  String matchAddress = '';
  String matchDate = '';
  String redPlayer = '';
  String blackPlayer = '';

  /// 结果：
  /// 结果用4字节表示，共有四种结果状态：
  /// 01 00 00 00 红胜
  /// 02 00 00 00 黑胜
  /// 03 00 00 00 和局
  /// 04 00 00 00 未知

  int result = 0;
  String commenter = '';
  String commenterEmail = '';
  String creator = '';
  String creatorEmail = '';
  String comment = '';

  /// 红方先行：
  /// 用1字节表示，值为1红方先行，值为0黑方先行。

  bool redFirst = true;

  String createDate = '';
  String lastUpdate = '';

  CBL2ManualInfo.initWithXReader(XReader reader) {
    final theInitBoard = reader.readBytes(32);
    if (theInitBoard == null) return;

    initBoard = theInitBoard;

    type = reader.readInt(defaultValue: -1)!;

    var length = reader.readInt(defaultValue: -1)!;
    if (length > 0) matchName = reader.readStringX(length) ?? '';

    beginIndex = reader.readInt(defaultValue: -1)!;

    length = reader.readInt(defaultValue: -1)!;
    if (length > 0) title = reader.readStringX(length) ?? '';

    length = reader.readInt(defaultValue: -1)!;
    if (length > 0) resource = reader.readStringX(length) ?? '';

    length = reader.readInt(defaultValue: -1)!;
    if (length > 0) other = reader.readStringX(length) ?? '';

    length = reader.readInt(defaultValue: -1)!;
    if (length > 0) matchAddress = reader.readStringX(length) ?? '';

    length = reader.readInt(defaultValue: -1)!;
    if (length > 0) matchDate = reader.readStringX(length) ?? '';

    length = reader.readInt(defaultValue: -1)!;
    if (length > 0) redPlayer = reader.readStringX(length) ?? '';

    length = reader.readInt(defaultValue: -1)!;
    if (length > 0) blackPlayer = reader.readStringX(length) ?? '';

    result = reader.readInt(defaultValue: -1)!;

    length = reader.readInt(defaultValue: -1)!;
    if (length > 0) commenter = reader.readStringX(length) ?? '';

    length = reader.readInt(defaultValue: -1)!;
    if (length > 0) commenterEmail = reader.readStringX(length) ?? '';

    length = reader.readInt(defaultValue: -1)!;
    if (length > 0) creator = reader.readStringX(length) ?? '';

    length = reader.readInt(defaultValue: -1)!;
    if (length > 0) creatorEmail = reader.readStringX(length) ?? '';

    length = reader.readInt(defaultValue: -1)!;

    if (length > 0) {
      final str = reader.readStringX(length) ?? '';
      comment = str.replaceAll('||', '\n');
    }

    redFirst = (reader.readByte()?.value == 1);

    createDate = reader.readStringX(19) ?? '';

    lastUpdate = reader.readStringX(19) ?? '';
  }

  String startFen() {
    final board = List<String>.filled(90, '');
    for (var i = 0; i < board.length; i++) {
      board[i] = Piece.noPiece;
    }

    const pieces = 'RNBAKABNRCCPPPPPrnbakabnrccppppp';

    for (var i = 0; i < 32; i++) {
      final piece = pieces[i];
      final pos = initBoard[i];
      if (pos == 0) continue; // 不在棋盘上了

      board[CBL2Move.crossIndexOf(pos - 0x11)] = piece;
    }

    return Fen.fromBoardSate(board);
  }

  String typeDesc() {
    switch (type) {
      case 1:
        return '实战全局';
      case 2:
        return '摆谱全局';
      case 3:
        return '实战残局';
      case 4:
        return '摆谱残局';
      default:
        return '未知';
    }
  }

  String resultDesc() {
    switch (result) {
      case 1:
        return '红胜';
      case 2:
        return '黑胜';
      case 3:
        return '和棋';
      default:
        return '*';
    }
  }

  String description() {
    var info = '';

    if (title.isNotEmpty) {
      info += '棋局标题 $title\n';
    }

    info += '棋局类型 ${typeDesc()}\n';

    if (matchName.isNotEmpty) {
      info += '比赛名称 $matchName\n';
    }

    info += '开始序数 $beginIndex\n';

    if (resource.isNotEmpty) {
      info += '相关资源 $resource\n';
    }
    if (other.isNotEmpty) {
      info += '其它 $other\n';
    }
    if (matchAddress.isNotEmpty) {
      info += '比赛地点 $matchAddress\n';
    }
    if (matchDate.isNotEmpty) {
      info += '比赛日期 $matchDate\n';
    }
    if (redPlayer.isNotEmpty) {
      info += '红方棋手 $redPlayer\n';
    }
    if (blackPlayer.isNotEmpty) {
      info += '黑方棋手 $blackPlayer\n';
    }

    info += '比赛结果 ${resultDesc()}\n';

    if (commenter.isNotEmpty) {
      info += '讲评人员 $commenter\n';
    }
    if (commenterEmail.isNotEmpty) {
      info += '讲评人EMail $commenterEmail\n';
    }
    if (creator.isNotEmpty) {
      info += '创建人 $creator\n';
    }
    if (creatorEmail.isNotEmpty) {
      info += '创建人EMail $creatorEmail\n';
    }
    if (comment.isNotEmpty) {
      info += '棋谱说明 $comment\n';
    }

    info += '先行 ${redFirst ? '红方' : '黑方'}\n';

    if (createDate.isNotEmpty) {
      info += '创建日期 $createDate\n';
    }
    if (lastUpdate.isNotEmpty) {
      info += '最后更新 $lastUpdate\n';
    }

    return info;
  }
}

class CBL2MovePack {
  int index;
  TreeNode node;

  CBL2MovePack.initWithIndex(this.index, this.node);
}

/// 棋谱数据的前4字节标明棋谱数据段的大小，该大小包含该4字节（不定长的数据表示法中
/// 仅有该处是包含本身4字节的）。
/// <p/>
/// 除去前4字节，棋谱数据段依次分为三大部分：
/// {
/// 棋谱信息
/// {
/// ...
/// }
/// 行棋数据
/// {
/// 行棋总数(4字节)
/// 行棋1(6字节)
/// {
/// ...
/// }
/// 行棋2(6字节)
/// 行棋3(6字节)
/// ...
/// }
/// 行棋注解数据
/// {
/// 注解1
/// 注解2
/// 注解3
/// ...
/// }
/// }
class CBL2Manual extends Manual {
  List<CBL2Move> moves = [];

  late int length;

  late CBL2ManualInfo info;

  /// 行棋总数用4字节表示，这儿的行棋总数并不表示棋局总回合数，而是包括变着的所有行棋
  /// 总数，在一局没有变着的棋谱中，行棋总数等于棋局总回合数。
  late int moveCount;

  CBL2Manual.initWithXReader(XReader reader) {
    length = reader.readInt() ?? -1;

    info = CBL2ManualInfo.initWithXReader(reader);

    moveCount = reader.readInt() ?? -1;

    for (var i = 0; i < moveCount; i++) {
      final move = CBL2Move.loadWithReader(reader);
      moves.add(move);
    }

    /// 注释和上面的行棋数据一一对应，每条注解结束用 0D 0A 表示，注解中有回车换行时
    /// 用两个连续的管道线符(||)表示。
    /// 在象棋桥中，在注解及说明的字符串中只要是两个连续的管道线符(||)都将被解释为回车换
    /// 行。
    for (var i = 0; i < moveCount; i++) {
      var buffer = <int>[];

      while (true) {
        final b1 = reader.readByte();
        if (b1 == null) break;

        if (b1.value != 13) {
          buffer.add(b1.value);
          continue;
        }

        final b2 = reader.readByte();
        if (b2 == null) break;

        if (b2.value == 10) break;

        buffer.add(b1.value);
        buffer.add(b2.value);
      }

      final move = moves[i];

      if (buffer.isNotEmpty) {
        move.comment = XReader.gbkDecode(Uint8List.fromList(buffer)).replaceAll('||', '\n');
      } else {
        move.comment = '';
      }
    }
  }

  @override
  ManualTree createTree() {
    var lastIndex = 0;
    var redSide = !info.redFirst;

    final root = TreeNode.empty();

    var current = root;

    for (final move in moves) {
      redSide = !redSide;
      move.redSide = redSide;

      if (root.branchCount == 0) {
        current = TreeNode.fromCBL2Move(move);

        root.addChild(current);
        current.parent = root;

        lastIndex = move.index.value;

        continue;
      }

      final index = move.index.value;
      final branch = TreeNode.fromCBL2Move(move);

      if (index <= lastIndex) {
        final parent = findParentWithIndex(index, root);
        if (parent == null) break; // 跳出循环

        parent.addChild(branch);
        branch.parent = parent;

        current = branch;
        lastIndex = index;
      } else {
        current.addChild(branch);
        branch.parent = current;

        current = branch;
        lastIndex = index;
      }
    }

    return ManualTree(root);
  }

  TreeNode? findParentWithIndex(int index, TreeNode startNode) {
    final stack = Stack();

    stack.push(CBL2MovePack.initWithIndex(index, startNode));

    CBL2MovePack p;

    while ((p = stack.pop()) != null) {
      for (var i = 0, length = p.node.branchCount; i < length; i++) {
        final branch = p.node.children![i];
        if (branch.moveIndex == index) return p.node;

        stack.push(CBL2MovePack.initWithIndex(index, branch));
      }
    }

    return null;
  }

  @override
  String toString() => info.description();

  @override
  Future<bool> writeTo(File file) async => false;

  @override
  String get startFen => info.startFen();

  @override
  String get title => info.title;

  @override
  String get red => info.redPlayer;

  @override
  String get black => info.blackPlayer;

  @override
  String get event => info.matchName;

  @override
  String get result => info.resultDesc();
}
