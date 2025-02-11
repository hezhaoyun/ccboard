import 'package:ccboard/cchess/position.dart';

import 'fen.dart';
import 'move.dart';
import 'piece.dart';
import 'rules.dart';

class CChess {
  Position position;
  CChess({String fen = Fen.defaultPosition}) : position = Position.fromFen(fen);

  List<Move> generateMoves(String square) {
    // square: a0, a1, ..., i9
    final file = square[0].codeUnitAt(0) - 'a'.codeUnitAt(0);
    final rank = square[1].codeUnitAt(0) - '0'.codeUnitAt(0);
    final index = rank * 9 + file;

    final piece = position.pieceAt(index);
    if (PieceColor.of(piece) != position.sideToMove) return [];

    return Rules.enumMovesOf(position, index);
  }

  bool move(Move move) => position.move(move);

  String get fen => Fen.fromPosition(position);
}
