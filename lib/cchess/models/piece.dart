class PieceColor {
  static const unknown = '-';
  static const red = 'w';
  static const black = 'b';

  static String of(String piece) {
    if ('RNBAKCP'.contains(piece)) return red;
    if ('rnbakcp'.contains(piece)) return black;
    return unknown;
  }

  static bool sameColor(String p1, String p2) => of(p1) == of(p2);

  static String opponent(String pieceColor) {
    if (pieceColor == red) return black;
    if (pieceColor == black) return red;
    return pieceColor;
  }
}

class Piece {
  static const noPiece = ' ';
  static const redRook = 'R';
  static const redKnight = 'N';
  static const redBishop = 'B';
  static const redAdvisor = 'A';
  static const redKing = 'K';
  static const redCanon = 'C';
  static const redPawn = 'P';
  static const blackRook = 'r';
  static const blackKnight = 'n';
  static const blackBishop = 'b';
  static const blackAdvisor = 'a';
  static const blackKing = 'k';
  static const blackCanon = 'c';
  static const blackPawn = 'p';

  static const zhName = {
    noPiece: '',
    redRook: '车',
    redKnight: '马',
    redBishop: '相',
    redAdvisor: '仕',
    redKing: '帅',
    redCanon: '炮',
    redPawn: '兵',
    blackRook: '车',
    blackKnight: '马',
    blackBishop: '象',
    blackAdvisor: '士',
    blackKing: '将',
    blackCanon: '炮',
    blackPawn: '卒',
  };

  static bool isRed(String c) => 'RNBAKCP'.contains(c);

  static bool isBlack(String c) => 'rnbakcp'.contains(c);

  static List<String> values = [
    noPiece,
    redRook,
    redKnight,
    redBishop,
    redAdvisor,
    redKing,
    redCanon,
    redPawn,
    blackRook,
    blackKnight,
    blackBishop,
    blackAdvisor,
    blackKing,
    blackCanon,
    blackPawn,
  ];
}
