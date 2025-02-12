part of 'int_x.dart';

class Byte extends IntX {
  Byte(int value) : super(value & 0xFF);

  Byte operator +(other) {
    if (other is int) return Byte(value + other);
    if (other is IntX) return Byte(value + other.value);
    return this;
  }

  Byte operator -(other) {
    if (other is int) return Byte(value - other);
    if (other is IntX) return Byte(value - other.value);
    return this;
  }

  Byte operator *(other) {
    if (other is int) return Byte(value * other);
    if (other is IntX) return Byte(value * other.value);
    return this;
  }

  Byte operator %(other) {
    if (other is int) return Byte(value % other);
    if (other is IntX) return Byte(value % other.value);
    return this;
  }

  Byte operator &(other) {
    if (other is int) return Byte(value & other);
    if (other is IntX) return Byte(value & other.value);
    return this;
  }

  Byte operator |(other) {
    if (other is int) return Byte(value | other);
    if (other is IntX) return Byte(value | other.value);
    return this;
  }
}
