import 'persistence_error.dart';

/// A generic key-value persistence interface.
abstract class KeyValueStore {
  /// Save a value to persistence.
  ///
  /// Passing a `null` should clear the value for this [key].
  ///
  /// Throw a [PersistenceError] if encountering a problem while persisting a value.
  Future<void> put<T>(String key, T? value);

  /// Retrieve a value from persistence.
  ///
  /// Throw a [PersistenceError] if encountering a problem while restoring a value from the storage.
  Future<T?> get<T>(String key);
}
