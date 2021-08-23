/// An error encountered when persisting a value, or restoring it from persistence.
class PersistenceError extends Error {
  /// A description of an error.
  final String message;

  /// A persistence error with a [message] describing its details.
  PersistenceError(this.message);
}
