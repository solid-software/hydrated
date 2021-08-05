library hydrated;

import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/subject_value_wrapper.dart';

typedef _VoidCallback = void Function();

typedef HydrateCallback<T> = T Function(String);
typedef PersistCallback<T> = String? Function(T);

/// A [Subject] that automatically persists its values and hydrates on creation.
///
/// HydratedSubject supports serialized classes
/// and [shared_preferences] types such as:
/// `int`, `double`, `bool`, `String`, and `List<String>`
///
/// Serialized classes are supported by using the
/// `hydrate: (String)=>Class` and
/// `persist: (Class)=>String` constructor arguments.
///
/// Example:
///
/// ```
///   final count$ = HydratedSubject<int>("count", seedValue: 0);
/// ```
///
/// Serialized class example:
///
/// ```
///   final user$ = HydratedSubject<User>(
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
///   final user$ = HydratedSubject<int>(
///     "count",
///     onHydrate: () => loading$.add(false),
///   );
/// ```
class HydratedSubject<T> extends Subject<T> implements ValueStream<T> {
  String _key;
  T? _seedValue;
  SubjectValueWrapper<T>? _wrapper;

  final HydrateCallback<T>? _hydrate;
  final PersistCallback<T>? _persist;
  void Function()? _onHydrate;

  HydratedSubject._(
    this._key,
    this._seedValue,
    this._hydrate,
    this._persist,
    this._onHydrate,
    StreamController<T> controller,
    Stream<T> observable,
    this._wrapper,
  ) : super(controller, observable) {
    _hydrateSubject();
  }

  factory HydratedSubject(
    String key, {
    T? seedValue,
    HydrateCallback<T>? hydrate,
    PersistCallback<T>? persist,
    _VoidCallback? onHydrate,
    _VoidCallback? onListen,
    _VoidCallback? onCancel,
    bool sync: false,
  }) {
    // assert that T is a type compatible with shared_preferences,
    // or that we have hydrate and persist mapping functions
    assert(T == int ||
        T == double ||
        T == bool ||
        T == String ||
        [""] is T ||
        (hydrate != null && persist != null));

    // ignore: close_sinks
    final controller = StreamController<T>.broadcast(
      onListen: onListen,
      onCancel: onCancel,
      sync: sync,
    );

    final wrapper = seedValue != null ? SubjectValueWrapper<T>(value: seedValue) : null;

    return HydratedSubject<T>._(
        key,
        seedValue,
        hydrate,
        persist,
        onHydrate,
        controller,
        Rx.defer<T>(
            () => wrapper == null
                ? controller.stream
                : controller.stream.startWith(wrapper.value!),
            reusable: true),
        wrapper);
  }

  @override
  void onAdd(T event) {
    _wrapper = SubjectValueWrapper<T>(value: event);
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
  set value(T newValue) => onAdd(newValue);

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

    if (this._hydrate != null) {
      final String? persistedValue = prefs.getString(this._key);
      if (persistedValue != null) {
        val = this._hydrate!(persistedValue);
      }
    } else if (T == int)
      val = prefs.getInt(this._key) as T;
    else if (T == double)
      val = prefs.getDouble(this._key) as T;
    else if (T == bool)
      val = prefs.getBool(this._key) as T;
    else if (T == String)
      val = prefs.getString(this._key) as T;
    else if ([""] is T)
      val = prefs.getStringList(this._key) as T;
    else
      Exception(
        'HydratedSubject – shared_preferences returned an invalid type',
      );

    // do not hydrate if the store is empty or matches the seed value
    // TODO: allow writing of seedValue if it is intentional
    if (val != null && val != _seedValue) {
      add(val);
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

  /// A unique key that references a storage container
  /// for a value persisted on the device.
  String get key => this._key;

  @override
  Subject<R> createForwardingSubject<R>({
    _VoidCallback? onListen,
    _VoidCallback? onCancel,
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
