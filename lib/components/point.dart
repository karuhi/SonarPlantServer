//import 'dart:math' as Math;

class Point {
  static Point zero = Point.setValue(0, 0);

//  static Math.Random _random;

  int x = 0, y = 0;

  Point();

  Point.setValue(this.x, this.y);

  Point.setPoint(Point p)
      : x = p.x,
        y = p.y;

//  factory Point.random(int maxX, int maxY) {
//    _random ??= Math.Random();
//    Point p = Point();
//    p.x = _random.nextInt(maxX);
//    p.y = _random.nextInt(maxY);
//    return p;
//  }

  void setValue(int x, int y) {
    this.x = x;
    this.y = y;
  }

  void setPoint(Point p) {
    x = p.x;
    y = p.y;
  }

  Point clone() {
    return Point.setPoint(this);
  }

  @override
  int get hashCode {
    return y << (y.bitLength >> 1) | x; // 大きな値が入らないのでこれで十分のはず
  }

  @override
  String toString() {
    return '{x: $x, y: $y}';
  }

  @override
  bool operator ==(other) {
    if (other is Point) return x == other.x && y == other.y;
    if (other is int) return x == other && y == other;
    if (other is List<int>) return x == other[0] && y == other[1];
    throw TypeError();
  }

  Point operator +(other) {
    if (other is Point) return Point.setValue(x + other.x, y + other.y);
    if (other is int) return Point.setValue(x + other, y + other);
    if (other is List<int>) return Point.setValue(x + other[0], y + other[1]);
    throw TypeError();
  }

  Point operator -(other) {
    if (other is Point) return Point.setValue(x - other.x, y - other.y);
    if (other is int) return Point.setValue(x - other, y - other);
    if (other is List<int>) return Point.setValue(x - other[0], y - other[1]);
    throw TypeError();
  }

  bool operator <(other) {
    if (other is Point) return x < other.x && y < other.y;
    if (other is num) return x < other && y < other;
    if (other is List<int>) return x < other[0] && y < other[1];
    throw TypeError();
  }

  bool operator <=(other) {
    if (other is Point) return x <= other.x && y <= other.y;
    if (other is num) return x <= other && y <= other;
    if (other is List<int>) return x <= other[0] && y <= other[1];
    throw TypeError();
  }

  bool operator >(other) {
    if (other is Point) return x > other.x && y > other.y;
    if (other is num) return x > other && y > other;
    if (other is List<int>) return x > other[0] && y > other[1];
    throw TypeError();
  }

  bool operator >=(other) {
    if (other is Point) return x >= other.x && y >= other.y;
    if (other is num) return x >= other && y >= other;
    if (other is List<int>) return x >= other[0] && y >= other[1];
    throw TypeError();
  }
}
