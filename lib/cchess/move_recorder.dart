import 'package:flutter/material.dart';

import 'move.dart';
import 'piece.dart';

class MoveRecorder {
  // 无吃子步数、总回合数
  var halfMove = 0, fullMove = 0;
  final _history = <Move>[];

  MoveRecorder({this.halfMove = 0, this.fullMove = 0});

  MoveRecorder.parse(String marks) {
    final segments = marks.split(' ');

    if (segments.length != 2) {
      throw 'Error: Invalid Counter Marks: $marks';
    }

    halfMove = int.parse(segments[0]);
    fullMove = int.parse(segments[1]);
  }

  MoveRecorder.copy(MoveRecorder other) {
    halfMove = other.halfMove;
    fullMove = other.fullMove;
  }

  void moveIn(Move move, String pieceColor) {
    if (move.captured != Piece.noPiece) {
      halfMove = 0;
    } else {
      halfMove++;
    }

    if (fullMove == 0) {
      fullMove++;
    } else if (pieceColor == PieceColor.black) {
      fullMove++;
    }

    _history.add(move);
  }

  Move? removeLast() => (_history.isEmpty) ? null : _history.removeLast();

  Move? get last => _history.isEmpty ? null : _history.last;

  List<Move> reverseMovesToPrevCapture() {
    var moves = <Move>[];

    for (var i = _history.length - 1; i >= 0; i--) {
      if (_history[i].captured != Piece.noPiece) break;
      moves.add(_history[i]);
    }

    return moves;
  }

  String movesAfterLastCaptured() {
    var moves = '', posAfterLastCaptured = -1;

    for (var i = _history.length - 1; i >= 0; i--) {
      if (_history[i].captured != Piece.noPiece) {
        posAfterLastCaptured = i;
        break;
      }
    }

    for (var i = posAfterLastCaptured + 1; i < _history.length; i++) {
      moves += ' ${_history[i].move}';
    }

    return moves.isNotEmpty ? moves.substring(1) : '';
  }

  String allMoves() {
    var moves = '';

    for (var i = 0; i < _history.length; i++) {
      moves += ' ${_history[i].move}';
    }

    return moves.isNotEmpty ? moves.substring(1) : '';
  }

  String buildMoveList() {
    var moveList = '';

    for (var i = 0; i < _history.length; i += 2) {
      final n = (i / 2 + 1).toInt();
      final np = '${n < 10 ? ' ' : ''}$n';

      moveList += '$np. ${_history[i].moveName}';

      if (i + 1 < _history.length) {
        moveList += '　${_history[i + 1].moveName}\n';
      }
    }

    if (moveList.isEmpty) {
      moveList = '--';
    }

    return moveList;
  }

  List<TextSpan> buildMoveListSpans({Color? textColor}) {
    final spans = <TextSpan>[];

    if (_history.isEmpty) {
      spans.add(const TextSpan(text: '--'));
      return spans;
    }

    final isBlack = MoveName.blackDigits.contains(_history[0].moveName![3]);
    final styleRed = TextStyle(fontSize: 14, color: textColor, backgroundColor: const Color(0x44FF0000));
    final styleBlack = TextStyle(fontSize: 14, color: textColor, backgroundColor: const Color(0x44000000));
    final styleSpace = TextStyle(fontSize: 14, color: textColor);

    for (var i = 0; i < _history.length; i += 2) {
      final n = (i / 2 + 1).toInt();
      final np = '${n < 10 ? ' ' : ''}$n. ';

      spans.add(TextSpan(text: np, style: styleSpace));
      spans.add(TextSpan(text: _history[i].moveName, style: isBlack ? styleBlack : styleRed));

      spans.add(TextSpan(text: '　', style: styleSpace));

      if (i + 1 < _history.length) {
        spans.add(TextSpan(text: _history[i + 1].moveName, style: isBlack ? styleRed : styleBlack));
        spans.add(const TextSpan(text: '\n'));
      }
    }

    return spans;
  }

  String buildMoveListForManual() {
    var result = '';

    for (var move in _history) {
      result += '${move.fx}${move.fy}${move.tx}${move.ty}';
    }

    return result;
  }

  int get historyLength => _history.length;

  Move moveAt(int index) => _history[index];

  @override
  String toString() => '$halfMove $fullMove';
}
