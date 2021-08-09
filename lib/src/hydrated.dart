import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hydrated/src/utils/typing_utils.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'model/subject_value_wrapper.dart';

/// A callback for encoding an instance of a data class into a String.
typedef PersistCallback<T> = String? Function(T);

/// A callback for reconstructing an instance of a data class from a String.
typedef HydrateCallback<T> = T Function(String);

/// A [Subject] that automatically persists its values and hydrates on creation.
///
/// HydratedSubject supports serialized classes and [shared_preferences] types
/// such as:
/// - `int`
/// - `double`
/// - `bool`
/// - `String`
/// - `List<String>`.
///
/// Serialized classes are supported by using the following `hydrate` and
/// `persist` combination:
///
/// ```
/// hydrate: (String)=>Class
/// persist: (Class)=>String
/// ```
///
/// Example:
///
/// ```
///   final count = HydratedSubject<int>("count", seedValue: 0);
/// ```
///
/// Serialized class example:
///
/// ```
///   final user = HydratedSubject<User>(
///     "user",
///     hydrate: (String s) => User.fromJSON(s),
///     persist: (User user) => user.toJSON(),
///     seedValue: User.empty(),
///   );
/// ```
///
/// Hydration is performed automatically and is asynchronous.
/// The `onHydrate` callback is called when hydration is complete.
///
/// ```
///   final user = HydratedSubject<int>(
///     "count",
///     onHydrate: () => loading.add(false),
///   );
/// ```
class HydratedSubject<T> extends Subject<T> implements ValueStream<T> {
  static final bool Function<T1, T2>() _areTypesEqual =
      TypingUtils.areTypesEqual;

  final String _key;
  final HydrateCallback<T>? _hydrate;
  final PersistCallback<T>? _persist;
  final VoidCallback? _onHydrate;
  final T? _seedValue;
  final StreamController<T> _controller;

  SubjectValueWrapper<T>? _wrapper;

  HydratedSubject._(
    this._key,
    this._seedValue,
    this._hydrate,
    this._persist,
    this._onHydrate,
    this._controller,
    Stream<T> observable,
    this._wrapper,
  ) : super(_controller, observable) {
    _hydrateSubject();
  }

  factory HydratedSubject(
    String key, {
    T? seedValue,
    HydrateCallback<T>? hydrate,
    PersistCallback<T>? persist,
    VoidCallback? onHydrate,
    VoidCallback? onListen,
    VoidCallback? onCancel,
    bool sync: false,
  }) {
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

    // ignore: close_sinks
    final StreamController<T> controller = StreamController.broadcast(
      onListen: onListen,
      onCancel: onCancel,
      sync: sync,
    );

    final wrapper =
        seedValue != null ? SubjectValueWrapper(value: seedValue) : null;

    return HydratedSubject._(
        key,
        seedValue,
        hydrate,
        persist,
        onHydrate,
        controller,
        Rx.defer(
            () => wrapper == null
                ? controller.stream
                : controller.stream.startWith(wrapper.value!),
            reusable: true),
        wrapper);
  }

  /// A unique key that references a storage container
  /// for a value persisted on the device.
  String get key => _key;

  @override
  void onAdd(T event) {
    _wrapper = SubjectValueWrapper(value: event);
    _persistValue(event);
  }

  @override
  ValueStream<T> get stream => this;

  @override
  bool get hasValue => _wrapper?.value != null;

  @override
  T? get valueOrNull => _wrapper?.value;

  /// Get the latest value emitted by the Subject
  @override
  T get value =>
      hasValue ? _wrapper!.value! : throw ValueStreamError.hasNoValue();

  /// Set and emit the new value
  set value(T newValue) => add(newValue);

  @override
  Object get error => hasError
      ? _wrapper!.errorAndStackTrace!
      : throw ValueStreamError.hasNoError();

  @override
  Object? get errorOrNull => _wrapper?.errorAndStackTrace;

  @override
  bool get hasError => _wrapper?.errorAndStackTrace != null;

  @override
  StackTrace? get stackTrace => _wrapper?.errorAndStackTrace?.stackTrace;

  /// Hydrates the HydratedSubject with a value stored on the user's device.
  ///
  /// Must be called to retrieve values stored on the device.
  Future<void> _hydrateSubject() async {
    final prefs = await SharedPreferences.getInstance();

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
      Exception(
        'HydratedSubject – shared_preferences returned an invalid type',
      );

    // do not hydrate if the store is empty or matches the seed value
    // TODO: allow writing of seedValue if it is intentional
    if (val != null && val != _seedValue) {
      _wrapper = SubjectValueWrapper(value: val);
      _controller.add(val);
    }

    _onHydrate?.call();
  }

  void _persistValue(T val) async {
    final prefs = await SharedPreferences.getInstance();

    if (val is int)
      await prefs.setInt(_key, val);
    else if (val is double)
      await prefs.setDouble(_key, val);
    else if (val is bool)
      await prefs.setBool(_key, val);
    else if (val is String)
      await prefs.setString(_key, val);
    else if (val is List<String>)
      await prefs.setStringList(_key, val);
    else if (val == null)
      prefs.remove(_key);
    else if (_persist != null) {
      final encoded = _persist!(val);
      if (encoded != null) {
        await prefs.setString(_key, encoded);
      } else {
        prefs.remove(_key);
      }
    } else {
      final error = Exception(
        'HydratedSubject – value must be int, '
        'double, bool, String, or List<String>',
      );
      final errorAndTrace = ErrorAndStackTrace(error, StackTrace.current);
      _wrapper = SubjectValueWrapper(errorAndStackTrace: errorAndTrace);
    }
  }

  @override
  Subject<R> createForwardingSubject<R>({
    VoidCallback? onListen,
    VoidCallback? onCancel,
    bool sync = false,
    HydrateCallback<R>? hydrate,
    PersistCallback<R?>? persist,
  }) {
    return HydratedSubject(
      _key,
      onListen: onListen,
      onCancel: onCancel,
      sync: sync,
      hydrate: hydrate,
      persist: persist,
    );
  }
}
