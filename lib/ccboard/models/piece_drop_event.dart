import 'square.dart';

class PieceDropEvent {
  final SquareInfo from;
  final SquareInfo to;

  PieceDropEvent(this.from, this.to);
}
