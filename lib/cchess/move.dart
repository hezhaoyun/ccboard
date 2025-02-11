import 'piece.dart';
import 'position.dart';
import 'rules.dart';

class Move {
  static const invalidIndex = -1;

  late int from, to, fx, fy, tx, ty;

  String captured = Piece.noPiece;

  // 'move' is the ucci engine's move-string
  late String move;
  String? moveName;

  // 这一步走完后的 FEN 记数，用于悔棋时恢复 FEN 步数 Counter
  String counterMarks = '';

  int? score, depth, nodes, time;
  String? pv;

  Move(this.from, this.to, {this.captured = Piece.noPiece, this.counterMarks = ''}) {
    fx = from % 9;
    fy = from ~/ 9;

    tx = to % 9;
    ty = to ~/ 9;

    if (fx < 0 || 9 < fx || fy < 0 || 9 < fy) {
      throw 'Error: Invalid Move (from:$from, to:$to)';
    }

    move = String.fromCharCode('a'.codeUnitAt(0) + fx) + (9 - fy).toString();
    move += String.fromCharCode('a'.codeUnitAt(0) + tx) + (9 - ty).toString();
  }

  Move.fromCoordinate(this.fx, this.fy, this.tx, this.ty) {
    from = fx + fy * 9;
    to = tx + ty * 9;
    captured = Piece.noPiece;

    move = String.fromCharCode('a'.codeUnitAt(0) + fx) + (9 - fy).toString();
    move += String.fromCharCode('a'.codeUnitAt(0) + tx) + (9 - ty).toString();
  }

  Move.fromUciMove(this.move, {this.score, this.depth, this.nodes, this.time, this.pv}) {
    if (!isOk(move)) {
      throw 'Error: Invalid Move: $move';
    }

    fx = move[0].codeUnitAt(0) - 'a'.codeUnitAt(0);
    fy = 9 - (move[1].codeUnitAt(0) - '0'.codeUnitAt(0));
    tx = move[2].codeUnitAt(0) - 'a'.codeUnitAt(0);
    ty = 9 - (move[3].codeUnitAt(0) - '0'.codeUnitAt(0));

    from = fx + fy * 9;
    to = tx + ty * 9;

    captured = Piece.noPiece;
  }

  String toUciMove() {
    return '${String.fromCharCode('a'.codeUnitAt(0) + fx)}${9 - fy}'
        '${String.fromCharCode('a'.codeUnitAt(0) + tx)}${9 - ty}';
  }

  Move flipCoordinateV() => Move.fromCoordinate(fx, 9 - fy, tx, 9 - ty);

  @override
  String toString() => move;

  static bool isOk(String move) {
    if (move.length < 4) return false;

    final fx = move[0].codeUnitAt(0) - 'a'.codeUnitAt(0);
    final fy = 9 - (move[1].codeUnitAt(0) - '0'.codeUnitAt(0));
    if (fx < 0 || 8 < fx || fy < 0 || 9 < fy) return false;

    final tx = move[2].codeUnitAt(0) - 'a'.codeUnitAt(0);
    final ty = 9 - (move[3].codeUnitAt(0) - '0'.codeUnitAt(0));
    if (tx < 0 || 8 < tx || ty < 0 || 9 < ty) return false;

    return true;
  }
}

class MoveName {
  static const redFileNames = '九八七六五四三二一';
  static const blackFileNames = '１２３４５６７８９';

  static const redDigits = '零一二三四五六七八九';
  static const blackDigits = '０１２３４５６７８９';

  static String? translate(Position position, Move move) {
    final fileNames = [redFileNames, blackFileNames];
    final digits = [redDigits, blackDigits];

    final c = PieceColor.of(position.pieceAt(move.from));
    final sideIndex = (c == PieceColor.red) ? 0 : 1;

    final pieceName = nameOf(position, move);
    if (pieceName == null) return null;

    var result = pieceName;

    if (move.ty == move.fy) {
      result += '平${fileNames[sideIndex][move.tx]}';
    } else {
      final direction = (c == PieceColor.red) ? -1 : 1;
      final dir = ((move.ty - move.fy) * direction > 0) ? '进' : '退';

      final piece = position.pieceAt(move.from);

      final specialPieces = [
        Piece.redKnight,
        Piece.blackKnight,
        Piece.redBishop,
        Piece.blackBishop,
        Piece.redAdvisor,
        Piece.blackAdvisor,
      ];

      String targetPos;

      if (specialPieces.contains(piece)) {
        targetPos = fileNames[sideIndex][move.tx];
      } else {
        targetPos = digits[sideIndex][Rules.abs(move.ty - move.fy)];
      }

      result += '$dir$targetPos';
    }

    return move.moveName = result;
  }

  static String? nameOf(Position position, Move move) {
    final fileNames = [redFileNames, blackFileNames];
    final digits = [redDigits, blackDigits];

    final c = PieceColor.of(position.pieceAt(move.from));
    final sideIndex = (c == PieceColor.red) ? 0 : 1;

    final piece = position.pieceAt(move.from);
    final pieceName = Piece.zhName[piece];

    // 士相由于行动行动路径有限，不会出现同一列两个士相都可以进或退的情况
    // 所以一般不说「前士、前相」之类的，根据「进、退」动作即可判断是前一个还是后一个
    if (piece == Piece.redAdvisor ||
        piece == Piece.redBishop ||
        piece == Piece.blackAdvisor ||
        piece == Piece.blackBishop) {
      return '$pieceName${fileNames[sideIndex][move.fx]}';
    }

    // 此 Map 的 Key 为「列」， Value 为此列上出现所查寻棋子的 y 坐标（rank）列表
    // 返回结果中进行了过滤，如果某一列包含所查寻棋子的数量 < 2，此列不包含在返回结果中
    final files = findPieceSameFile(position, piece);
    final fyIndexes = files[move.fx];

    // 正在动棋的这一列不包含多个同类棋子
    if (fyIndexes == null) {
      return '$pieceName${fileNames[sideIndex][move.fx]}';
    }

    // 只有正在动棋的这一列包含多个同类棋子
    if (files.length == 1) {
      var order = fyIndexes.indexOf(move.fy);
      if (c == PieceColor.black) order = fyIndexes.length - 1 - order;

      if (fyIndexes.length == 2) {
        return '${'前后'[order]}$pieceName';
      }

      if (fyIndexes.length == 3) {
        return '${'前中后'[order]}$pieceName';
      }

      return '${digits[sideIndex][order]}$pieceName';
    }

    // 这种情况表示有两列都有两个或以上正在查寻的棋子
    // 这种情况下，从右列开始为棋子指定序数（从前到后），然后再左列
    if (files.length == 2) {
      final fxIndexes = files.keys.toList();
      fxIndexes.sort((a, b) => a - b);

      // 已经按列的 x 坐标排序，当前动子列是否是在右边的列
      final curFileStart = (move.fx == fxIndexes[1 - sideIndex]);

      if (curFileStart) {
        var order = fyIndexes.indexOf(move.fy);
        if (c == PieceColor.black) order = fyIndexes.length - 1 - order;

        return '${digits[sideIndex][order]}$pieceName';
      } else {
        // 当前列表在左边，后计序数
        final fxOtherFile = fxIndexes[sideIndex];

        var order = fyIndexes.indexOf(move.fy);
        if (c == PieceColor.black) order = fyIndexes.length - 1 - order;

        return '${digits[sideIndex][files[fxOtherFile]!.length + order]}$pieceName';
      }
    }

    return null;
  }

  static Map<int, List<int>> findPieceSameFile(Position position, String piece) {
    final map = <int, List<int>>{};

    for (var rank = 0; rank < 10; rank++) {
      for (var file = 0; file < 9; file++) {
        if (position.pieceAt(rank * 9 + file) == piece) {
          var fyIndexes = map[file] ?? [];
          fyIndexes.add(rank);
          map[file] = fyIndexes;
        }
      }
    }

    final result = <int, List<int>>{};

    map.forEach((k, v) {
      if (v.length > 1) result[k] = v;
    });

    return result;
  }
}
