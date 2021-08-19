/// A generic key-value persistence interface.
abstract class KeyValueStore {
  /// Save a value to persistence.
  Future<void> put<T>(String key, T value);

  /// Retrieve a value from persistence.
  Future<T?> get<T>(String key);
}
