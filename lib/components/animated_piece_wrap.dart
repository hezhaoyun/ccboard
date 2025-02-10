import 'package:flutter/material.dart';
import '../models/chess_state.dart';

class AnimatedPieceWrap extends StatefulWidget {
  final Widget child;
  final StateEntry stateEntry;
  final double squareSize;
  final bool animated;

  const AnimatedPieceWrap({
    super.key,
    required this.child,
    required this.stateEntry,
    required this.squareSize,
    required this.animated,
  });

  @override
  State<AnimatedPieceWrap> createState() => _AnimatedPieceWrapState();
}

class _AnimatedPieceWrapState extends State<AnimatedPieceWrap> {
  int rank = 0;
  int file = 0;

  @override
  void initState() {
    if (widget.animated) {
      SquarePosition? pos = widget.stateEntry.lastPosition();
      if (pos != null) {
        rank = pos.rank;
        file = pos.file;
      } else {
        rank = widget.stateEntry.position.rank;
        file = widget.stateEntry.position.file;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          rank = widget.stateEntry.position.rank;
          file = widget.stateEntry.position.file;
        });
      });
    } else {
      rank = widget.stateEntry.position.rank;
      file = widget.stateEntry.position.file;
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double left = (file) * widget.squareSize;
    double bottom = (rank) * widget.squareSize;

    return AnimatedPositioned(
      key: Key("${widget.stateEntry.getKey()}_a"),
      curve: Curves.easeInOut,
      duration: const Duration(milliseconds: 200),
      bottom: bottom,
      left: left,
      child: widget.child,
    );
  }
}
