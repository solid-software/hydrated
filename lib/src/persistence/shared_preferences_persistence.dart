import 'package:hydrated/src/persistence/persistence_error.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/type_utils.dart';
import 'generic_value_persistence.dart';

/// An adapter for [SharedPreferences] persistence.
///
/// Supported types:
/// - `int`
/// - `double`
/// - `bool`
/// - `String`
/// - `List<String>`.
class SharedPreferencesPersistence implements GenericValuePersistence {
  static final _areTypesEqual = TypeUtils.areTypesEqual;

  const SharedPreferencesPersistence();

  @override
  Future<T?> get<T>(String key) async {
    _assertSupportedType<T>();
    final prefs = await _getPrefs();

    T? val;

    if (_areTypesEqual<T, int>() || _areTypesEqual<T, int?>())
      val = prefs.getInt(key) as T?;
    else if (_areTypesEqual<T, double>() || _areTypesEqual<T, double?>())
      val = prefs.getDouble(key) as T?;
    else if (_areTypesEqual<T, bool>() || _areTypesEqual<T, bool?>())
      val = prefs.getBool(key) as T?;
    else if (_areTypesEqual<T, String>() || _areTypesEqual<T, String?>())
      val = prefs.getString(key) as T?;
    else if (_areTypesEqual<T, List<String>>() ||
        _areTypesEqual<T, List<String>?>())
      val = prefs.getStringList(key) as T?;
    else
      throw PersistenceError(
        'Shared Preferences returned an invalid type',
      );

    return val;
  }

  @override
  Future<void> put<T>(String key, T value) async {
    _assertSupportedType<T>();
    final prefs = await _getPrefs();

    if (value is int)
      await prefs.setInt(key, value);
    else if (value is double)
      await prefs.setDouble(key, value);
    else if (value is bool)
      await prefs.setBool(key, value);
    else if (value is String)
      await prefs.setString(key, value);
    else if (value is List<String>)
      await prefs.setStringList(key, value);
    else if (value == null)
      prefs.remove(key);
    else {
      throw PersistenceError(
        'HydratedSubject – value must be int, '
        'double, bool, String, or List<String>',
      );
    }
  }

  void _assertSupportedType<T>() {
    assert(
        _areTypesEqual<T, int>() ||
            _areTypesEqual<T, int?>() ||
            _areTypesEqual<T, double>() ||
            _areTypesEqual<T, double?>() ||
            _areTypesEqual<T, bool>() ||
            _areTypesEqual<T, bool?>() ||
            _areTypesEqual<T, String>() ||
            _areTypesEqual<T, String?>() ||
            _areTypesEqual<T, List<String>>() ||
            _areTypesEqual<T, List<String>?>(),
        '$T type is not supported by SharedPreferences.');
  }

  Future<SharedPreferences> _getPrefs() => SharedPreferences.getInstance();
}
