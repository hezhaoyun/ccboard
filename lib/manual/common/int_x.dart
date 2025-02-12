library int_x;

part 'byte.dart';
part 'short.dart';

abstract class IntX {
  final int value;
  IntX(this.value);

  @override
  bool operator ==(other) {
    if (this == other) return true;
    if (other is int) return value == other;
    if (other is IntX) return value == other.value;
    return false;
  }

  bool operator >(other) {
    if (other is int) return value > other;
    if (other is IntX) return value > other.value;
    return false;
  }

  bool operator <(other) {
    if (other is int) return value < other;
    if (other is IntX) return value < other.value;
    return false;
  }

  bool operator >=(other) {
    if (other is int) return value >= other;
    if (other is IntX) return value >= other.value;
    return false;
  }

  bool operator <=(other) {
    if (other is int) return value <= other;
    if (other is IntX) return value <= other.value;
    return false;
  }

  @override
  String toString() => '$value';

  @override
  int get hashCode => super.hashCode + 0;
}
