import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import '../utils/fen.dart';
import 'game_result.dart';
import 'move.dart';
import 'move_recorder.dart';
import 'piece.dart';
import '../utils/rules.dart';

class Position with FenMixin {
  var result = GameResult.pending;

  late String _sideToMove;
  late List<String> _pieces; // 10 行，9 列
  late MoveRecorder _recorder;

  String _initBoard = '', _initFen = '';
  String? _lastCapturedPosition;

  Position(List<String> pieces, String sideToMove, String counterMarks) {
    init(pieces, sideToMove, counterMarks);
  }

  Position.clone(Position other) {
    deepCopy(other);
  }

  Position.fromFen(String fen) {
    initWithFen(fen);
  }

  Position.defaultPosition() {
    initWithFen(Fen.defaultPosition);
  }

  void initWithFen(String fen) {
    final pieces = piecesOf(fen) ?? [];
    final sideToMove = sideToMoveOf(fen);
    final counterMarks = counterMarksOf(fen);

    _initFen = fen;

    init(pieces, sideToMove, counterMarks);
  }

  init(List<String> pieces, String? sideToMove, String? counterMarks) {
    _pieces = pieces;
    _sideToMove = sideToMove ??= PieceColor.red;
    _recorder = MoveRecorder.parse(counterMarks ?? '0 1');

    updateInitPosition();
  }

  String get initFen => _initFen;
  String get initBoard => _initBoard;

  void updateInitPosition() {
    _lastCapturedPosition = Fen.fromPosition(this);
    _initBoard = toCrManualBoard(this);
  }

  void deepCopy(Position other) {
    _pieces = [];
    for (var piece in other._pieces) {
      _pieces.add(piece);
    }

    _sideToMove = other._sideToMove;

    _recorder = MoveRecorder(
      halfMove: other._recorder.halfMove,
      fullMove: other._recorder.fullMove,
    );

    _initBoard = other._initBoard;
  }

  bool move(Move move, {validate = true}) {
    // 移动是否符合象棋规则
    if (validate && !validateMove(move.from, move.to)) {
      return false;
    }

    // 生成棋步，记录步数
    final captured = _pieces[move.to];

    move.data.captured = captured;
    move.data.counterMarks = _recorder.toString();

    move.data.moveName = MoveName.translate(this, move);
    _recorder.moveIn(move, _sideToMove);

    // 修改棋盘
    _pieces[move.to] = _pieces[move.from];
    _pieces[move.from] = Piece.noPiece;

    // 交换走棋方
    _sideToMove = PieceColor.opponent(_sideToMove);

    // 记录最近一个吃子局面的 FEN，UCCI 引擎需要
    if (captured != Piece.noPiece) {
      _lastCapturedPosition = Fen.fromPosition(this);
    }

    return true;
  }

  // 在判断行棋合法性等环节，要在克隆的棋盘上进行行棋假设，然后检查效果
  // 这种情况下不验证、不记录、不翻译
  void moveTest(Move move, {turnSide = false}) {
    // 修改棋盘
    _pieces[move.to] = _pieces[move.from];
    _pieces[move.from] = Piece.noPiece;

    // 交换走棋方
    if (turnSide) _sideToMove = PieceColor.opponent(_sideToMove);
  }

  Move? undo() {
    final lastMove = _recorder.removeLast();

    if (lastMove != null) {
      _pieces[lastMove.from] = _pieces[lastMove.to];
      _pieces[lastMove.to] = lastMove.data.captured ?? Piece.noPiece;

      _sideToMove = PieceColor.opponent(_sideToMove);

      final counterMarks = MoveRecorder.parse(lastMove.data.counterMarks ?? '');
      _recorder.halfMove = counterMarks.halfMove;
      _recorder.fullMove = counterMarks.fullMove;

      if (lastMove.data.captured != Piece.noPiece) {
        // 查找上一个吃子局面（或开局），NativeEngine 需要
        final tempPosition = Position.clone(this);

        final moves = _recorder.reverseMovesToPrevCapture();
        for (var move in moves) {
          tempPosition._pieces[move.from] = tempPosition._pieces[move.to];
          tempPosition._pieces[move.to] = move.data.captured ?? Piece.noPiece;

          tempPosition._sideToMove = PieceColor.opponent(tempPosition._sideToMove);
        }

        _lastCapturedPosition = Fen.fromPosition(tempPosition);
      }

      result = GameResult.pending;
    }

    return lastMove;
  }

  bool validateMove(int from, int to) {
    // 移动的棋子的选手，应该是当前方
    if (PieceColor.of(_pieces[from]) != _sideToMove) return false;

    return (Rules.isValidMove(this, Move(from, to)));
  }

  Move last9moves(int index) {
    return _recorder.moveAt((_recorder.historyLength - 9) + index);
  }

  bool isLongCheck() {
    if (!appearRepeatPosition()) return false;

    final tempPosition = Position.clone(this);
    for (var i = 0; i < 9; i++) {
      tempPosition.undo();
    }

    tempPosition.move(last9moves(0));
    if (!Rules.beChecked(tempPosition)) return false;

    tempPosition.move(last9moves(1));
    tempPosition.move(last9moves(2));
    if (!Rules.beChecked(tempPosition)) return false;

    tempPosition.move(last9moves(3));
    tempPosition.move(last9moves(4));
    if (!Rules.beChecked(tempPosition)) return false;

    tempPosition.move(last9moves(5));
    tempPosition.move(last9moves(6));
    if (!Rules.beChecked(tempPosition)) return false;

    tempPosition.move(last9moves(7));
    tempPosition.move(last9moves(8));
    if (!Rules.beChecked(tempPosition)) return false;

    return true;
  }

  bool appearRepeatPosition() {
    if (_recorder.historyLength < 9) return false;

    bool same(Move m1, Move m2, [Move? m3]) {
      if (m3 == null) return m1.from == m2.from && m1.to == m2.to;
      return m1.from == m2.from && m1.to == m2.to && m1.from == m3.from && m1.to == m3.to;
    }

    return same(last9moves(0), last9moves(4), last9moves(8)) &&
        same(last9moves(1), last9moves(5)) &&
        same(last9moves(2), last9moves(6)) &&
        same(last9moves(3), last9moves(7));
  }

  Future<bool> saveManual(Directory docdir, String title, String clazz) async {
    final black = '象棋公社';

    final moveList = _recorder.buildMoveListForManual();
    String battleResult;

    switch (result) {
      case GameResult.pending:
        battleResult = '未知';
        break;
      case GameResult.win:
        battleResult = '红胜';
        break;
      case GameResult.lose:
        battleResult = '黑胜';
        break;
      case GameResult.draw:
        battleResult = '和棋';
        break;
    }

    final map = {
      'id': '0',
      'title': title,
      'event': '',
      'class': clazz,
      'red': '',
      'black': black,
      'result': battleResult,
      'init_board': _initBoard,
      'move_list': '[DhtmlXQ_movelist]$moveList[/DhtmlXQ_movelist]',
      'comment_list': '',
    };

    try {
      final contents = jsonEncode(map);

      final file = File('${docdir.path}/saved/$title.crm');
      await file.create(recursive: true);

      await file.writeAsString(contents);
    } catch (e) {
      debugPrint('saveManual: $e');
      return false;
    }

    return true;
  }

  String get infoText => _recorder.buildMoveList();

  List<TextSpan> get infoTextSpans => _recorder.buildMoveListSpans();

  String buildMoveListForManual() => _recorder.buildMoveListForManual();

  // broken setting operation

  int pieceCount() => _pieces.where((piece) => piece != Piece.noPiece).length;

  String pieceAt(int index) => _pieces[index];

  void setPiece(int index, String piece) => _pieces[index] = piece;

  int indexOf(String piece) => _pieces.indexOf(piece);

  String get turn => _sideToMove;
  void turnSide() => _sideToMove = PieceColor.opponent(_sideToMove);

  // broken access to recorder outside

  MoveRecorder get recorder => _recorder;

  Move? get lastMove => _recorder.last;
  int get halfMove => _recorder.halfMove; // 无吃子步数
  int get fullMove => _recorder.fullMove; // 总回合步数
  String get moveCount => _recorder.toString();

  String? get lastCapturedPosition => _lastCapturedPosition;
  String get allMoves => _recorder.allMoves();
  String get movesAfterLastCaptured => _recorder.movesAfterLastCaptured();
}
