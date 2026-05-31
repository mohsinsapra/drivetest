class SmartUtils {
  SmartUtils._();

  /// Returns sizes of each chunk. Single-element list means no chunking.
  ///
  /// Rules:
  ///   total <= 10  -> [total]       (no split)
  ///   total <= 20  -> target = 10
  ///   total >  20  -> target = 15
  ///
  /// Remainder is distributed one-per-chunk from the front.
  static List<int> computeSmartSizes(int total) {
    if (total <= 10) return [total];
    final targetSize = total <= 20 ? 10 : 15;
    final count = (total / targetSize).ceil();
    final base = total ~/ count;
    final remainder = total % count;
    return List.generate(count, (i) => base + (i < remainder ? 1 : 0));
  }

  /// Returns the start index in the full question list for [chunkIndex].
  static int smartOffset(List<int> sizes, int chunkIndex) =>
      sizes.take(chunkIndex).fold(0, (a, b) => a + b);
}
