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
