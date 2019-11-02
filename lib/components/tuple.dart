class Tuple<T1, T2> {
  T1 item1;
  T2 item2;

  Tuple();

  Tuple.setValue(T1 item1, T2 item2)
      : item1 = item1,
        item2 = item2;

  void set(T1 item1, T2 item2) {
    this.item1 = item1;
    this.item2 = item2;
  }

  @override
  String toString() {
    return '{item1: $item1, item2: $item2}';
  }

  @override
  bool operator ==(other) {
    return item1 == other.item1 && item2 == other.item2;
  }
}

class Tuple3<T1, T2, T3> {
  T1 item1;
  T2 item2;
  T3 item3;

  Tuple3();

  Tuple3.setValue(T1 item1, T2 item2, T3 item3)
      : item1 = item1,
        item2 = item2,
        item3 = item3;

  @override
  String toString() {
    return '{item1: $item1, item2: $item2, item3: $item3}';
  }

  @override
  bool operator ==(other) {
    return item1 == other.item1 && item2 == other.item2 && item3 == other.item3;
  }
}
