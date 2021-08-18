/// A generic persistence interface for a single [T] value.
abstract class GenericValuePersistence<T> {
  /// Save a value to persistence.
  Future<void> put(T value);

  /// Retrieve a value from persistence.
  Future<T?> get();
}
