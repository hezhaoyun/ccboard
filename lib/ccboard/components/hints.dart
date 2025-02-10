import 'package:flutter/material.dart';
import '../models/hint_map.dart';
import '../models/square.dart';

class Hints extends StatelessWidget {
  final double size;
  final HintMap hints;

  const Hints({super.key, required this.size, required this.hints});

  @override
  Widget build(BuildContext context) {
    double squareSize = size / 9;

    return Stack(
      children: (List<int>.generate(90, (i) => i + 1)).map((i) {
        final info = SquareInfo(i - 1, squareSize);

        final left = (info.file - 1) * squareSize;
        final bottom = (info.rank - 1) * squareSize;
        final hint = hints.getHint(info.rank, info.file);

        return Positioned(bottom: bottom, left: left, child: hint != null ? hint(squareSize) : const SizedBox());
      }).toList(),
    );
  }
}

class MoveHint extends StatelessWidget {
  final double size;
  final Color color;
  final VoidCallback? onPressed;

  const MoveHint({super.key, required this.size, this.color = Colors.tealAccent, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final hintSize = size * 0.2;

    return GestureDetector(
      onTapDown: onPressed != null ? (_) => onPressed!() : null,
      child: Container(
        width: size,
        height: size,
        color: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: hintSize,
              height: hintSize,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(hintSize)),
            ),
          ],
        ),
      ),
    );
  }
}
