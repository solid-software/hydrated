/// Utilities for working with Dart type system.
class TypeUtils {
  /// Check two types for equality.
  ///
  /// Returns `true` if types match exactly, taking nullable types into account.
  ///
  /// Example outputs:
  /// ```
  /// TypeUtils.areTypesEqual<int, int>() == true
  /// TypeUtils.areTypesEqual<int, int?>() == false
  /// ```
  static bool areTypesEqual<T1, T2>() {
    return T1 == T2;
  }
}
