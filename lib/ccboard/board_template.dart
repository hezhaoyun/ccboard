import 'package:image/image.dart' as pi;

import 'package:flutter/material.dart';

import '../cchess/piece.dart';

class BoardTemplate {
  static const kCacheKeyBoardArea = 'key-board-area';
  static const kValidImageSize = Size(810, 1138);
  static const kBoardArea = Rect.fromLTWH(50, 50, 710, 860);
  static const kBoardLayoutArea = Rect.fromLTWH(61, 98, 688, 765);
  static const kPiecesArea = Rect.fromLTWH(50, 960, 448, 128);
  static const kBgColorArea = Rect.fromLTWH(548, 960, 212, 128);

  final _cache = <String, MemoryImage>{};
  pi.Image? _texture, _piecesArea;
  Color? bgColor;

  BoardTemplate._internal();
  static final BoardTemplate _instance = BoardTemplate._internal();
  factory BoardTemplate() => _instance;

  Future<void> load(String textureFile) async {
    // clear cache
    _cache.clear();
    _piecesArea = null;

    _texture = await pi.decodePngFile(textureFile);

    final xbase = _texture!.width ~/ kValidImageSize.width;

    final pixel = _texture!.getPixel(
      kBgColorArea.center.dx.toInt() * xbase,
      kBgColorArea.center.dy.toInt() * xbase,
    );

    bgColor = Color.fromARGB(
      pixel.a.toInt(),
      pixel.r.toInt(),
      pixel.g.toInt(),
      pixel.b.toInt(),
    );
  }

  MemoryImage? getBoardImage() {
    if (_texture == null) return null;

    if (_cache.containsKey(kCacheKeyBoardArea)) {
      return _cache[kCacheKeyBoardArea];
    }

    final xbase = _texture!.width ~/ kValidImageSize.width;

    final image = pi.copyCrop(
      _texture!,
      x: kBoardArea.left.toInt() * xbase,
      y: kBoardArea.top.toInt() * xbase,
      width: kBoardArea.width.toInt() * xbase,
      height: kBoardArea.height.toInt() * xbase,
    );

    final memImage = MemoryImage(pi.encodePng(image));
    _cache[kCacheKeyBoardArea] = memImage;

    return memImage;
  }

  MemoryImage? getPieceImage(String piece) {
    if (_texture == null) return null;

    if (_cache.containsKey(piece)) return _cache[piece];

    final piecesArea = _makesurePiecesArea();
    if (piecesArea == null) return null;

    final pieceWidth = piecesArea.width ~/ 7;
    if (piecesArea.height != (pieceWidth * 2).toInt()) return null;

    var pos = const Offset(-1, -1);

    switch (piece) {
      case Piece.redRook:
        pos = Offset.zero;
        break;
      case Piece.redKnight:
        pos = const Offset(1, 0);
        break;
      case Piece.redBishop:
        pos = const Offset(2, 0);
        break;
      case Piece.redAdvisor:
        pos = const Offset(3, 0);
        break;
      case Piece.redKing:
        pos = const Offset(4, 0);
        break;
      case Piece.redCanon:
        pos = const Offset(5, 0);
        break;
      case Piece.redPawn:
        pos = const Offset(6, 0);
        break;
      case Piece.blackRook:
        pos = const Offset(0, 1);
        break;
      case Piece.blackKnight:
        pos = const Offset(1, 1);
        break;
      case Piece.blackBishop:
        pos = const Offset(2, 1);
        break;
      case Piece.blackAdvisor:
        pos = const Offset(3, 1);
        break;
      case Piece.blackKing:
        pos = const Offset(4, 1);
        break;
      case Piece.blackCanon:
        pos = const Offset(5, 1);
        break;
      case Piece.blackPawn:
        pos = const Offset(6, 1);
        break;

      default:
        return null;
    }

    final image = pi.copyCrop(
      piecesArea,
      x: pos.dx.toInt() * pieceWidth,
      y: pos.dy.toInt() * pieceWidth,
      width: pieceWidth,
      height: pieceWidth,
    );

    final memImage = MemoryImage(pi.encodePng(image));
    _cache[piece] = memImage;

    return memImage;
  }

  pi.Image? _makesurePiecesArea() {
    if (_texture == null) return null;

    final xbase = _texture!.width ~/ kValidImageSize.width;

    _piecesArea ??= pi.copyCrop(
      _texture!,
      x: kPiecesArea.left.toInt() * xbase,
      y: kPiecesArea.top.toInt() * xbase,
      width: kPiecesArea.width.toInt() * xbase,
      height: kPiecesArea.height.toInt() * xbase,
    );

    return _piecesArea;
  }
}
