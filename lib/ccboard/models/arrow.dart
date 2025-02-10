import 'package:flutter/material.dart';
import 'square.dart';

class Arrow {
  final SquareLocation from;
  final SquareLocation to;
  final Color color;

  Arrow({required this.from, required this.to, this.color = Colors.green});
}

class ArrowList {
  static int _lastId = 0;
  late int _id;

  final List<Arrow> value;
  ArrowList(this.value) {
    _updateId();
  }

  int get id => _id;

  void _updateId() => _id = _lastId++;
}
