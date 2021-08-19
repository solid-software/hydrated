class PersistenceError extends Error {
  final String? message;

  PersistenceError(this.message);
}
