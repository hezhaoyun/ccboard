class Square {
  final int rank, file;
  Square(this.rank, this.file);

  Square.fromString(String square)
      : rank = square.codeUnitAt(1) - '1'.codeUnitAt(0) + 1,
        file = square.codeUnitAt(0) - 'a'.codeUnitAt(0) + 1;

  int get rankIndex => rank - 1;
  int get fileIndex => file - 1;
}

class SquareInfo {
  final int index;
  final int file, rank;
  final double size;

  SquareInfo(this.index, this.size)
      : file = ((index % 9) + 1),
        rank = ((index / 9).floor() + 1);

  @override
  String toString() => String.fromCharCode('a'.codeUnitAt(0) + (file - 1)) + rank.toString();
}
