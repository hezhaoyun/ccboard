part of 'int_x.dart';

class Short extends IntX {
  Short(int value) : super(value & 0xFFFF);

  Short operator +(other) {
    if (other is int) return Short(value + other);
    if (other is IntX) return Short(value + other.value);
    return this;
  }

  Short operator -(other) {
    if (other is int) return Short(value - other);
    if (other is IntX) return Short(value - other.value);
    return this;
  }

  Short operator *(other) {
    if (other is int) return Short(value * other);
    if (other is IntX) return Short(value * other.value);
    return this;
  }

  Short operator %(other) {
    if (other is int) return Short(value % other);
    if (other is IntX) return Short(value % other.value);
    return this;
  }

  Short operator &(other) {
    if (other is int) return Short(value & other);
    if (other is IntX) return Short(value & other.value);
    return this;
  }

  Short operator |(other) {
    if (other is int) return Short(value | other);
    if (other is IntX) return Short(value | other.value);
    return this;
  }
}
