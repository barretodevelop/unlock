extension Slices<E> on List<E> {
  /// Retorna uma lista de listas, onde cada sublista tem no máximo [size] elementos.
  /// Útil para queries 'whereIn' do Firestore que têm um limite.
  List<List<E>> slices(int size) {
    if (size <= 0) throw ArgumentError('size must be positive');
    final result = <List<E>>[];
    for (var i = 0; i < length; i += size) {
      result.add(sublist(i, i + size > length ? length : i + size));
    }
    return result;
  }
}
