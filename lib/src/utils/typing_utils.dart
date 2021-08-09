typedef TypeComparisonFunction = bool Function<T1, T2>();

class TypingUtils {
  static bool areTypesEqual<T1, T2>() {
    return T1 == T2;
  }
}