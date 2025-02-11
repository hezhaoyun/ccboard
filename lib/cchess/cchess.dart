import 'package:ccboard/cchess/position.dart';

import 'fen.dart';
import 'move.dart';
import 'piece.dart';
import 'rules.dart';

class CChess {
  Position position;
  CChess({String fen = Fen.defaultPosition}) : position = Position.fromFen(fen);

  List<Move> generateMoves(String square) {
    // square: a0, a1, ..., i9, from left to right, from bottom to top
    final file = square[0].codeUnitAt(0) - 'a'.codeUnitAt(0);
    final rank = square[1].codeUnitAt(0) - '0'.codeUnitAt(0);

    /// 坐标转换: 从左下角开始, 转换为从左上角开始
    final index = (9 - rank) * 9 + file;

    final piece = position.pieceAt(index);
    if (PieceColor.of(piece) != position.sideToMove) return [];

    final moves = Rules.enumMovesOf(position, index);

    /// 坐标转换: 从左上角开始, 转换为从左下角开始
    return moves.map((move) => Move.fromCoordinate(move.tx, 9 - move.ty, move.tx, 9 - move.ty)).toList();
  }

  bool move(Move move) => position.move(move);

  String get fen => Fen.fromPosition(position);
}
