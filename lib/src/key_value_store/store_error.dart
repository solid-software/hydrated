/// An error encountered when persisting a value,
/// or restoring it from persistence.
///
/// This is probably a configuration error -- check the `KeyValueStore`
/// implementation and `HydratedSubject` `persist` and `hydrate` callbacks
/// for type compatibility.
class StoreError extends Error {
  /// A description of an error.
  final String message;

  /// A storage error with a [message] describing its details.
  StoreError(this.message);

  /// A storage has encountered an unsupported type.
  StoreError.unsupportedType(String message)
      : message = 'Error storing an unsupported type: $message';
}
