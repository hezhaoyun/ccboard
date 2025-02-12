import 'package:ccboard/cchess/models/position.dart';

import 'utils/fen.dart';
import 'models/move.dart';
import 'utils/rules.dart';

class CChess {
  Position position;
  CChess({String fen = Fen.defaultPosition}) : position = Position.fromFen(fen);

  List<Move> generateMoves(String square) {
    /// square: a0, a1, ..., i9, from left-bottom corner
    final file = square[0].codeUnitAt(0) - 'a'.codeUnitAt(0);
    final rank = square[1].codeUnitAt(0) - '0'.codeUnitAt(0);

    final index = (9 - rank) * 9 + file;
    return Rules.enumMovesOf(position, index);
  }

  bool move(Move move) => position.move(move);

  String get fen => Fen.fromPosition(position);
}
