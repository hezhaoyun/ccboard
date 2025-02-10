import 'arrow.dart';

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
