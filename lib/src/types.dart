typedef JsonClassBuilder<T> = T Function(dynamic map);
typedef JsonClassWithKeyBuilder<T> = T Function(
  dynamic map, {
  required String key,
});

typedef JsonClassListBuilder<T> = List<T> Function(Iterable<dynamic> list);
