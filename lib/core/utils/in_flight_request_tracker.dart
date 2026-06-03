class InFlightRequestTracker<T> {
  Future<T>? _inFlight;

  void clear() {
    _inFlight = null;
  }

  Future<T> run(Future<T> Function() start) {
    final existing = _inFlight;
    if (existing != null) return existing;

    final future = start();
    _inFlight = future;
    future.then<void>(
      (_) {
        if (identical(_inFlight, future)) {
          _inFlight = null;
        }
      },
      onError: (_, __) {
        if (identical(_inFlight, future)) {
          _inFlight = null;
        }
      },
    );
    return future;
  }
}
