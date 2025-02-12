import 'package:ccboard/cchess/models/position.dart';

import 'models/move.dart';
import 'Knowledge/fen.dart';
import 'Knowledge/rules.dart';

class CChess {
  Position _position;
  CChess({String fen = Fen.defaultPosition}) : _position = Position.fromFen(fen);

  void reset() => _position = Position.defaultPosition();

  bool move(Move move) => _position.move(move);

  Move? undo() => _position.undo();

  List<Move> moves() => Rules.enumMoves(_position);

  List<Move> movesOf(String square) => Rules.enumMovesOf(_position, getIndex(square));

  String get(String square) => _position.pieceAt(getIndex(square));

  String indexOf(int index) => _position.pieceAt(index);

  int historyLength() => _position.recorder.historyLength;

  Move? get lastMove => _position.recorder.last;

  bool get inCheckmate => Rules.inCheckmate(_position);

  bool get inLongCheck => _position.inLongCheck();

  bool get gameOver => Rules.inCheckmate(_position) || _position.inLongCheck() || _position.halfMove > 120;

  String get turn => _position.turn;

  String get fen => Fen.fromPosition(_position);

  static int getIndex(String square) {
    ///
    /// square: a0, a1, ..., i9, from left-bottom corner
    ///
    final file = square[0].codeUnitAt(0) - 'a'.codeUnitAt(0);
    final rank = square[1].codeUnitAt(0) - '0'.codeUnitAt(0);

    return file + (9 - rank) * 9;
  }
}
