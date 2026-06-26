import 'dart:collection';

import 'iterable.dart';

typedef ValueCallback<T> = T Function();

class FixedList<T> {
  final int maxLength;
  final ListQueue<T> _queue;

  FixedList(this.maxLength, {List<T>? list})
      : _queue = maxLength > 0 ? ListQueue(maxLength) : ListQueue() {
    if (list != null) {
      if (maxLength > 0) {
        final start = list.length > maxLength ? list.length - maxLength : 0;
        for (var i = start; i < list.length; i++) {
          _queue.addLast(list[i]);
        }
      } else {
        for (final item in list) {
          _queue.addLast(item);
        }
      }
    }
  }

  void add(T item) {
    if (maxLength > 0 && _queue.length >= maxLength) {
      _queue.removeFirst();
    }
    _queue.addLast(item);
  }

  void clear() {
    _queue.clear();
  }

  List<T> get list => List.unmodifiable(_queue);

  int get length => _queue.length;

  T operator [](int index) => _queue.elementAt(index);

  FixedList<T> copyWith() {
    return FixedList(maxLength, list: _queue.toList());
  }
}

class FixedMap<K, V> {
  int maxLength;
  late Map<K, V> _map;

  FixedMap(this.maxLength, {Map<K, V>? map}) {
    _map = map ?? {};
  }

  V updateCacheValue(K key, ValueCallback<V> callback) {
    final realValue = _map.updateCacheValue(
      key,
      callback,
    );
    _adjustMap();
    return realValue;
  }

  void clear() {
    _map.clear();
  }

  void updateMaxLength(int size) {
    maxLength = size;
    _adjustMap();
  }

  void updateMap(Map<K, V> map) {
    _map = map;
    _adjustMap();
  }

  void _adjustMap() {
    if (_map.length > maxLength) {
      _map = Map.fromEntries(
        map.entries.toList()..truncate(maxLength),
      );
    }
  }

  V? get(K key) => _map[key];

  bool containsKey(K key) => _map.containsKey(key);

  int get length => _map.length;

  Map<K, V> get map => Map.unmodifiable(_map);
}
