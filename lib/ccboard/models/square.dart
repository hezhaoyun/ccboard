class Square {
  final int rank, file;
  Square(this.rank, this.file);

  Square.fromString(String square)
      : rank = square.codeUnitAt(1) - '0'.codeUnitAt(0),
        file = square.codeUnitAt(0) - 'a'.codeUnitAt(0);
}

class SquareInfo {
  final int index;
  final int file, rank;
  final double size;

  SquareInfo(this.index, this.size)
      : file = (index % 9),
        rank = (index / 9).floor();

  @override
  String toString() => String.fromCharCode('a'.codeUnitAt(0) + file) + rank.toString();
}
