enum StateEntryDelta { removed, none, added, replaced }

class StateEntry {
  final String piece;
  final SquarePosition position;
  final ChessState state;

  StateEntry(this.piece, this.position, this.state);

  SquarePosition? lastPosition() {
    StateEntryDelta delta = state.getDelta(piece, state.last?._board[position.rank]?[position.file]?.piece ?? '');
    return delta == StateEntryDelta.added || delta == StateEntryDelta.replaced ? state.findFrom(piece) : null;
  }

  String getKey() => 'ste_${position}_$piece';
}

class SquarePosition {
  final int rank;
  final int file;

  SquarePosition(this.rank, this.file);

  @override
  String toString() => '$rank$file';
}

class ChessState {
  static int zero = '0'.codeUnitAt(0);
  static int nine = '9'.codeUnitAt(0);
  static int space = ' '.codeUnitAt(0);

  final ChessState? last;
  final String fen;
  late final Map<int, Map<int, StateEntry>> _board;

  ChessState(this.fen, {this.last}) {
    Map<int, Map<int, StateEntry>> board = {};

    if (fen == '') {
      for (var i = 0; i < 10; i++) {
        board[i] = {};
        for (var j = 0; j < 9; j++) {
          board[i]![j] = StateEntry('', SquarePosition(i, j), this);
        }
      }
    } else {
      int rank = 0;
      for (var fenRank in fen.split('/')) {
        int file = 0;
        int currRank = 9 - rank;
        board[currRank] = {};

        for (var i = 0; i < fenRank.length; i++) {
          int piece = fenRank.codeUnitAt(i);
          if (piece == space) break;

          if (piece >= zero && piece <= nine) {
            for (int j = 0; j < piece - zero; j++) {
              board[currRank]![file] = StateEntry('', SquarePosition(currRank, file), this);
              file++;
            }
          } else {
            String pieceNotation = String.fromCharCode(piece);
            board[currRank]![file] = StateEntry(pieceNotation, SquarePosition(currRank, file), this);
            file++;
          }
        }
        rank++;
      }
    }

    _board = board;
  }

  StateEntryDelta getDelta(String piece, String lastPiece) {
    if (piece == lastPiece) return StateEntryDelta.none;
    if (lastPiece == '') return StateEntryDelta.added;
    if (piece == '') return StateEntryDelta.removed;
    return StateEntryDelta.replaced;
  }

  StateEntry getEntry(int rank, int file) => _board[rank]![file]!;

  SquarePosition? findFrom(String piece) {
    if (last == null) return null;

    for (var rank in _board.entries) {
      for (var file in rank.value.entries) {
        if (file.value.piece == '' && last!._board[rank.key]![file.key]!.piece == piece) {
          return SquarePosition(rank.key, file.key);
        }
      }
    }
    return null;
  }
}
