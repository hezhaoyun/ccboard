import 'package:flutter/material.dart';
import '../models/square.dart';
import 'animated_piece_wrap.dart';
import '../models/board_orientation.dart';
import '../models/chess_state.dart';
import '../models/ui_adapter.dart';

class Pieces extends StatelessWidget {
  final double size;
  final UIAdapter uiAdapter;
  final ChessState state;
  final BoardOrientation orientation;
  final void Function(SquareInfo square, String piece)? onPieceTap;
  final void Function(SquareInfo square, String piece)? onPieceStartDrag;
  final void Function(SquareInfo square)? onEmptyFieldTap;
  final bool animated;
  final bool disableDrag;
  final bool ghostOnDrag;
  final bool turnTopPlayerPieces;

  const Pieces({
    super.key,
    required this.size,
    required this.uiAdapter,
    required this.state,
    this.onPieceTap,
    this.onEmptyFieldTap,
    this.onPieceStartDrag,
    required this.animated,
    required this.orientation,
    required this.disableDrag,
    required this.ghostOnDrag,
    required this.turnTopPlayerPieces,
  });

  @override
  Widget build(BuildContext context) {
    double squareSize = size / 9;

    return Stack(
      children: (List<int>.generate(90, (i) => i)).map((i) {
        SquareInfo info = SquareInfo(i, squareSize);
        StateEntry pieceEntry = state.getEntry(info.rank, info.file);

        double left = info.file * squareSize;
        double bottom = info.rank * squareSize;

        if (pieceEntry.piece == '') {
          return Positioned(
            key: Key('piece_${info}_none'),
            bottom: bottom,
            left: left,
            child: GestureDetector(
              onTapDown: onEmptyFieldTap != null ? (_) => onEmptyFieldTap!(info) : null,
              child: Container(color: Colors.transparent, width: squareSize, height: squareSize),
            ),
          );
        }

        Widget pieceWidget = uiAdapter.get(pieceEntry.piece)(squareSize);

        bool isBlackPiece = pieceEntry.piece.toLowerCase() == pieceEntry.piece;
        bool shouldTurnPiece = turnTopPlayerPieces &&
            ((orientation == BoardOrientation.black && !isBlackPiece) ||
                (orientation == BoardOrientation.white && isBlackPiece));

        return AnimatedPieceWrap(
          key: Key(pieceEntry.getKey()),
          squareSize: squareSize,
          stateEntry: pieceEntry,
          animated: animated,
          child: GestureDetector(
            onTapDown: onPieceTap != null ? (_) => onPieceTap!(info, pieceEntry.piece) : null,
            child: RotatedBox(
              quarterTurns: ((orientation == BoardOrientation.black) ? 2 : 0) + (shouldTurnPiece ? 2 : 0),
              child: disableDrag
                  ? pieceWidget
                  : Draggable<SquareInfo>(
                      onDragStarted: onPieceStartDrag != null ? () => onPieceStartDrag!(info, pieceEntry.piece) : null,
                      childWhenDragging: ghostOnDrag ? Opacity(opacity: 0.2, child: pieceWidget) : const SizedBox(),
                      data: info,
                      feedback: pieceWidget,
                      child: pieceWidget,
                    ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
