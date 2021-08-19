/// A generic persistence interface for a single [T] value.
abstract class GenericValuePersistence {
  /// Save a value to persistence.
  Future<void> put<T>(String key, T value);

  /// Retrieve a value from persistence.
  Future<T?> get<T>(String key);
}
