import 'piece.dart';
import 'position.dart';
import '../utils/rules.dart';

class Move {
  /// UCI move as follow:
  ///
  /// a9 b9 c9 d9 e9 f9 g9 h9 i9
  /// a8 b8 c8 d8 e8 f8 g8 h8 i8
  /// a7 b7 c7 d7 e7 f7 g7 h7 i7
  /// a6 b6 c6 d6 e6 f6 g6 h6 i6
  /// a5 b5 c5 d5 e5 f5 g5 h5 i5
  /// a4 b4 c4 d4 e4 f4 g4 h4 i4
  /// a3 b3 c3 d3 e3 f3 g3 h3 i3
  /// a2 b2 c2 d2 e2 f2 g2 h2 i2
  /// a1 b1 c1 d1 e1 f1 g1 h1 i1
  /// a0 b0 c0 d0 e0 f0 g0 h0 i0

  /// Index used in cchess:
  ///
  ///  0  1  2  3  4  5  6  7  8
  ///  9 10 11 12 13 14 15 16 17
  /// 18 19 20 21 22 23 24 25 26
  /// 27 28 29 30 31 32 33 34 35
  /// 36 37 38 39 40 41 42 43 44
  /// 45 46 47 48 49 50 51 52 53
  /// 54 55 56 57 58 59 60 61 62
  /// 63 64 65 66 67 68 69 70 71
  /// 72 73 74 75 76 77 78 79 80
  /// 81 82 83 84 85 86 87 88 89

  late int from, to; // index in cchess
  final data = MoveData();

  Move(this.from, this.to, {MoveData? add}) {
    if (!isValidIndex(from) || !isValidIndex(to)) throw 'Error: Invalid Move: $from $to';
    data.merge(add);
  }

  Move.fromUci(String uci, {MoveData? add}) {
    if (!isValidUci(uci)) throw 'Error: Invalid Move: $uci';

    final fx = uci[0].codeUnitAt(0) - 'a'.codeUnitAt(0);
    final fy = 9 - (uci[1].codeUnitAt(0) - '0'.codeUnitAt(0));
    final tx = uci[2].codeUnitAt(0) - 'a'.codeUnitAt(0);
    final ty = 9 - (uci[3].codeUnitAt(0) - '0'.codeUnitAt(0));

    from = fx + fy * 9;
    to = tx + ty * 9;

    data.merge(add);
  }

  (int, int, int, int) get coordinate {
    final fx = from % 9, fy = from ~/ 9;
    final tx = to % 9, ty = to ~/ 9;
    return (fx, fy, tx, ty);
  }

  (int, int, int, int) get coordinateLB {
    final (fx, fy, tx, ty) = coordinate;
    return (fx, 9 - fy, tx, 9 - ty);
  }

  String get uci {
    final (fx, fy, tx, ty) = coordinate;
    final from = String.fromCharCode('a'.codeUnitAt(0) + fx) + (9 - fy).toString();
    final to = String.fromCharCode('a'.codeUnitAt(0) + tx) + (9 - ty).toString();
    return '$from$to';
  }

  @override
  String toString() => uci;

  static int toCoordinateLB(int index) => index % 9 + (9 - index ~/ 9) * 9;

  static bool isValidUci(String uci) {
    if (uci.length < 4) return false;

    final fx = uci[0].codeUnitAt(0) - 'a'.codeUnitAt(0);
    final fy = 9 - (uci[1].codeUnitAt(0) - '0'.codeUnitAt(0));
    final tx = uci[2].codeUnitAt(0) - 'a'.codeUnitAt(0);
    final ty = 9 - (uci[3].codeUnitAt(0) - '0'.codeUnitAt(0));

    if (fx < 0 || 8 < fx || fy < 0 || 9 < fy) return false;
    if (tx < 0 || 8 < tx || ty < 0 || 9 < ty) return false;

    return true;
  }

  static bool isValidIndex(int index) => index >= 0 && index <= 89;
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
    final (fx, fy, tx, ty) = move.coordinate;

    if (ty == fy) {
      result += '平${fileNames[sideIndex][tx]}';
    } else {
      final direction = (c == PieceColor.red) ? -1 : 1;
      final dir = ((ty - fy) * direction > 0) ? '进' : '退';

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
        targetPos = fileNames[sideIndex][tx];
      } else {
        targetPos = digits[sideIndex][Rules.abs(ty - fy)];
      }

      result += '$dir$targetPos';
    }

    return move.data.moveName = result;
  }

  static String? nameOf(Position position, Move move) {
    final fileNames = [redFileNames, blackFileNames];
    final digits = [redDigits, blackDigits];

    final c = PieceColor.of(position.pieceAt(move.from));
    final sideIndex = (c == PieceColor.red) ? 0 : 1;

    final piece = position.pieceAt(move.from);
    final pieceName = Piece.zhName[piece];

    final (fx, fy, tx, ty) = move.coordinate;

    // 士相由于行动行动路径有限，不会出现同一列两个士相都可以进或退的情况
    // 所以一般不说「前士、前相」之类的，根据「进、退」动作即可判断是前一个还是后一个
    if (piece == Piece.redAdvisor ||
        piece == Piece.redBishop ||
        piece == Piece.blackAdvisor ||
        piece == Piece.blackBishop) {
      return '$pieceName${fileNames[sideIndex][tx]}';
    }

    // 此 Map 的 Key 为「列」， Value 为此列上出现所查寻棋子的 y 坐标（rank）列表
    // 返回结果中进行了过滤，如果某一列包含所查寻棋子的数量 < 2，此列不包含在返回结果中
    final files = findPieceSameFile(position, piece);
    final fyIndexes = files[fx];

    // 正在动棋的这一列不包含多个同类棋子
    if (fyIndexes == null) {
      return '$pieceName${fileNames[sideIndex][tx]}';
    }

    // 只有正在动棋的这一列包含多个同类棋子
    if (files.length == 1) {
      var order = fyIndexes.indexOf(fy);
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
      final curFileStart = (fx == fxIndexes[1 - sideIndex]);

      if (curFileStart) {
        var order = fyIndexes.indexOf(fy);
        if (c == PieceColor.black) order = fyIndexes.length - 1 - order;

        return '${digits[sideIndex][order]}$pieceName';
      } else {
        // 当前列表在左边，后计序数
        final fxOtherFile = fxIndexes[sideIndex];

        var order = fyIndexes.indexOf(fy);
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

class MoveData {
  String? captured;
  String? moveName;
  String? counterMarks;
  int? score, depth, nodes, time;
  String? pv;

  void merge(MoveData? other) {
    if (other == null) return;

    if (other.captured != null) captured = other.captured;
    if (other.moveName != null) moveName = other.moveName;
    if (other.counterMarks != null) counterMarks = other.counterMarks;
    if (other.score != null) score = other.score;
    if (other.depth != null) depth = other.depth;
    if (other.nodes != null) nodes = other.nodes;
    if (other.time != null) time = other.time;
    if (other.pv != null) pv = other.pv;
  }
}
