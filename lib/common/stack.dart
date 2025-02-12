class Stack<T> {
  final List<T> _data = [];

  void push(T item) => _data.add(item);
  T pop() => _data.removeLast();

  bool get isEmpty => _data.isEmpty;
  bool get isNotEmpty => _data.isNotEmpty;
}
