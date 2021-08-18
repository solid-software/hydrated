import 'package:hydrated/src/persistence/persistence_error.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/type_utils.dart';
import 'generic_value_persistence.dart';

/// A callback for encoding an instance of a data class into a String.
typedef StringEncoder<T> = String? Function(T);

/// A callback for reconstructing an instance of a data class from a String.
typedef StringDecoder<T> = T Function(String);

/// An adapter for [SharedPreferences] persistence.
///
/// Supported types:
/// - `int`
/// - `double`
/// - `bool`
/// - `String`
/// - `List<String>`.
/// - data classes via `hydrate` and `persist` callbacks.
class SharedPreferencesPersistence<T> implements GenericValuePersistence<T> {
  final String _key;
  final StringDecoder<T>? _hydrate;
  final StringEncoder<T>? _persist;

  static final _areTypesEqual = TypeUtils.areTypesEqual;

  SharedPreferencesPersistence({
    required String key,
    StringDecoder<T>? hydrate,
    StringEncoder<T>? persist,
  })  : _key = key,
        _hydrate = hydrate,
        _persist = persist,
        // assert that T is a type compatible with shared_preferences,
        // or that we have hydrate and persist mapping functions
        assert(_areTypesEqual<T, int>() ||
            _areTypesEqual<T, int?>() ||
            _areTypesEqual<T, double>() ||
            _areTypesEqual<T, double?>() ||
            _areTypesEqual<T, bool>() ||
            _areTypesEqual<T, bool?>() ||
            _areTypesEqual<T, String>() ||
            _areTypesEqual<T, String?>() ||
            _areTypesEqual<T, List<String>>() ||
            _areTypesEqual<T, List<String>?>() ||
            (hydrate != null && persist != null));

  @override
  Future<T?> get() async {
    final prefs = await _getPrefs();

    T? val;

    if (_hydrate != null) {
      final String? persistedValue = prefs.getString(_key);
      if (persistedValue != null) {
        val = _hydrate!(persistedValue);
      }
    } else if (_areTypesEqual<T, int>() || _areTypesEqual<T, int?>())
      val = prefs.getInt(_key) as T?;
    else if (_areTypesEqual<T, double>() || _areTypesEqual<T, double?>())
      val = prefs.getDouble(_key) as T?;
    else if (_areTypesEqual<T, bool>() || _areTypesEqual<T, bool?>())
      val = prefs.getBool(_key) as T?;
    else if (_areTypesEqual<T, String>() || _areTypesEqual<T, String?>())
      val = prefs.getString(_key) as T?;
    else if (_areTypesEqual<T, List<String>>() ||
        _areTypesEqual<T, List<String>?>())
      val = prefs.getStringList(_key) as T?;
    else
      throw PersistenceError(
        'Shared Preferences returned an invalid type',
      );

    return val;
  }

  @override
  Future<void> put(T value) async {
    final prefs = await _getPrefs();

    if (value is int)
      await prefs.setInt(_key, value);
    else if (value is double)
      await prefs.setDouble(_key, value);
    else if (value is bool)
      await prefs.setBool(_key, value);
    else if (value is String)
      await prefs.setString(_key, value);
    else if (value is List<String>)
      await prefs.setStringList(_key, value);
    else if (value == null)
      prefs.remove(_key);
    else if (_persist != null) {
      final encoded = _persist!(value);
      if (encoded != null) {
        await prefs.setString(_key, encoded);
      } else {
        prefs.remove(_key);
      }
    } else {
      throw PersistenceError(
        'HydratedSubject – value must be int, '
        'double, bool, String, or List<String>',
      );
    }
  }

  Future<SharedPreferences> _getPrefs() => SharedPreferences.getInstance();
}
