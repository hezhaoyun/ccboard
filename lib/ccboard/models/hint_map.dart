import 'package:flutter/material.dart';

typedef HintBuilder = Widget Function(double size);

class HintMap {
  static int _lastId = 0;
  final String key;
  late int _id;
  Map<int, Map<int, HintBuilder?>> board = {};

  int get id => _id;

  HintMap({this.key = ''}) {
    _updateId();

    for (var i = 0; i < 10; i++) {
      board[i] = {};
      for (var j = 0; j < 9; j++) {
        board[i]![j] = null;
      }
    }
  }

  void _updateId() => _id = _lastId++;

  HintMap set(int rank, int file, HintBuilder? widget) {
    board[rank]![file] = widget;
    return this;
  }

  HintBuilder? getHint(int rank, int file) => board[rank]![file];
}
