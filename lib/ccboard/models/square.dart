class SquareLocation {
  final int rank;
  final int file;

  SquareLocation(this.rank, this.file);

  SquareLocation.fromString(String square)
    : rank = square.codeUnitAt(1) - '1'.codeUnitAt(0) + 1,
      file = square.codeUnitAt(0) - 'a'.codeUnitAt(0) + 1;

  int get rankIndex {
    return rank - 1;
  }

  int get fileIndex {
    return file - 1;
  }
}

class SquareInfo {
  final int index;
  final int file;
  final int rank;
  final double size;

  // TODO: change to adapt to Chinese Chess
  SquareInfo(this.index, this.size) : file = ((index % 8) + 1), rank = ((index / 8).floor() + 1);

  @override
  String toString() => String.fromCharCode('a'.codeUnitAt(0) + (file - 1)) + rank.toString();
}
