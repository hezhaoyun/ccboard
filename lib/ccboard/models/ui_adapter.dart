import 'package:flutter/material.dart';

import '../board_template.dart';

typedef PieceBuilder = Widget Function(double size);

class UIAdapter {
  final ImageProvider board;
  final PieceBuilder R;
  final PieceBuilder N;
  final PieceBuilder B;
  final PieceBuilder A;
  final PieceBuilder K;
  final PieceBuilder C;
  final PieceBuilder P;
  final PieceBuilder r;
  final PieceBuilder n;
  final PieceBuilder b;
  final PieceBuilder a;
  final PieceBuilder k;
  final PieceBuilder c;
  final PieceBuilder p;

  UIAdapter({
    required this.board,
    required this.R,
    required this.N,
    required this.B,
    required this.A,
    required this.K,
    required this.C,
    required this.P,
    required this.r,
    required this.n,
    required this.b,
    required this.a,
    required this.k,
    required this.c,
    required this.p,
  });

  PieceBuilder get(String notation) {
    switch (notation) {
      case 'R':
        return R;
      case 'N':
        return N;
      case 'B':
        return B;
      case 'A':
        return A;
      case 'K':
        return K;
      case 'C':
        return C;
      case 'P':
        return P;
      case 'r':
        return r;
      case 'n':
        return n;
      case 'b':
        return b;
      case 'a':
        return a;
      case 'k':
        return k;
      case 'c':
        return c;
      case 'p':
        return p;
      default:
        throw Exception('Invalid piece notation: "$notation".');
    }
  }

  double realBoardWidth(double fullBoardWidth) {
    final scale = fullBoardWidth / BoardTemplate.kBoardArea.width;
    return BoardTemplate.kBoardLayoutArea.width * scale;
  }

  EdgeInsets innerBoardPadding(double fullBoardWidth) {
    final scale = fullBoardWidth / BoardTemplate.kBoardArea.width;
    final fullBoardHeight = BoardTemplate.kBoardArea.height * scale;
    final realBoardWidth = BoardTemplate.kBoardLayoutArea.width * scale;
    final realBoardHeight = BoardTemplate.kBoardLayoutArea.height * scale;

    final hPadding = (fullBoardWidth - realBoardWidth) / 2;
    final vPadding = (fullBoardHeight - realBoardHeight) / 2;
    return EdgeInsets.symmetric(horizontal: hPadding, vertical: vPadding);
  }
}
