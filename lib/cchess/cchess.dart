import 'package:ccboard/cchess/models/position.dart';

import 'utils/fen.dart';
import 'models/move.dart';
import 'utils/rules.dart';

class CChess {
  Position position;
  CChess({String fen = Fen.defaultPosition}) : position = Position.fromFen(fen);

  List<Move> generateMoves(String square) {
    // square: a0, a1, ..., i9, from left to right, from bottom to top
    final file = square[0].codeUnitAt(0) - 'a'.codeUnitAt(0);
    final rank = square[1].codeUnitAt(0) - '0'.codeUnitAt(0);

    /// UI 的左下角是 a0, 右上角是 i9
    /// CChess/Move 内部 index-0 为左上角
    final moves = Rules.enumMovesOf(position, (9 - rank) * 9 + file);

    return moves.map((move) => move.flipCoordinateV()).toList();
  }

  bool move(Move move) => position.move(move.flipCoordinateV());

  String get fen => Fen.fromPosition(position);
}
