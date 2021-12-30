import 'package:hydrated/src/key_value_store/key_value_store.dart';
import 'package:hydrated/src/key_value_store/store_error.dart';
import 'package:hydrated/src/utils/type_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// An adapter for [SharedPreferences] persistence.
///
/// Supported types:
/// - `int`
/// - `double`
/// - `bool`
/// - `String`
/// - `List<String>`.
class SharedPreferencesStore implements KeyValueStore {
  /// Create an instance of [SharedPreferences] storage wrapper.
  const SharedPreferencesStore();

  static const _areTypesEqual = TypeUtils.areTypesEqual;

  @override
  Future<T?> get<T>(String key) async {
    _ensureSupportedType<T>();
    final prefs = await _getPrefs();

    T? val;

    try {
      if (_areTypesEqual<T, int>() || _areTypesEqual<T, int?>()) {
        val = prefs.getInt(key) as T?;
      } else if (_areTypesEqual<T, double>() || _areTypesEqual<T, double?>()) {
        val = prefs.getDouble(key) as T?;
      } else if (_areTypesEqual<T, bool>() || _areTypesEqual<T, bool?>()) {
        val = prefs.getBool(key) as T?;
      } else if (_areTypesEqual<T, String>() || _areTypesEqual<T, String?>()) {
        val = prefs.getString(key) as T?;
      } else if (_areTypesEqual<T, List<String>>() ||
          _areTypesEqual<T, List<String>?>()) {
        val = prefs.getStringList(key) as T?;
      }
    } catch (e) {
      throw StoreError(
        'Error retrieving value from SharedPreferences: $e',
      );
    }

    return val;
  }

  @override
  Future<void> put<T>(String key, T? value) async {
    _ensureSupportedType<T>();
    final prefs = await _getPrefs();

    if (value == null) {
      await prefs.remove(key);
    } else if (value is int) {
      await prefs.setInt(key, value);
    } else if (value is double) {
      await prefs.setDouble(key, value);
    } else if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    } else if (value is List<String>) {
      await prefs.setStringList(key, value);
    }
  }

  void _ensureSupportedType<T>() {
    if (_areTypesEqual<T, int>() ||
        _areTypesEqual<T, int?>() ||
        _areTypesEqual<T, double>() ||
        _areTypesEqual<T, double?>() ||
        _areTypesEqual<T, bool>() ||
        _areTypesEqual<T, bool?>() ||
        _areTypesEqual<T, String>() ||
        _areTypesEqual<T, String?>() ||
        _areTypesEqual<T, List<String>>() ||
        _areTypesEqual<T, List<String>?>()) {
      return;
    } else {
      throw StoreError.unsupportedType(
        '$T type is not supported by SharedPreferences.',
      );
    }
  }

  Future<SharedPreferences> _getPrefs() => SharedPreferences.getInstance();
}
