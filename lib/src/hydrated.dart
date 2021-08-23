import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

import 'persistence/key_value_store.dart';
import 'persistence/persistence_error.dart';
import 'persistence/shared_preferences_persistence.dart';

/// A callback for encoding an instance of a data class into a String.
typedef PersistCallback<T> = String? Function(T);

/// A callback for reconstructing an instance of a data class from a String.
typedef HydrateCallback<T> = T Function(String);

/// A [Subject] that automatically persists its values and hydrates on creation.
///
/// Mimics the behavior of a [BehaviorSubject].
///
/// The set of supported classes depends on the [KeyValueStore] implementation.
/// For a list of types supported by default see [SharedPreferencesPersistence].
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
  final String _key;
  final HydrateCallback<T>? _hydrate;
  final PersistCallback<T>? _persist;
  final BehaviorSubject<T> _subject;
  final VoidCallback? _onHydrate;
  final T? _seedValue;

  final KeyValueStore _persistence;

  /// A unique key that references a storage container
  /// for a value persisted on the device.
  String get key => _key;

  HydratedSubject._(
    this._key,
    this._seedValue,
    this._hydrate,
    this._persist,
    this._onHydrate,
    this._subject,
    this._persistence,
  ) : super(_subject, _subject.stream) {
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
    bool sync = false,
    KeyValueStore persistence = const SharedPreferencesPersistence(),
  }) {
    // ignore: close_sinks
    final subject = seedValue != null
        ? BehaviorSubject<T>.seeded(
            seedValue,
            onListen: onListen,
            onCancel: onCancel,
            sync: sync,
          )
        : BehaviorSubject<T>(
            onListen: onListen,
            onCancel: onCancel,
            sync: sync,
          );

    return HydratedSubject._(
      key,
      seedValue,
      hydrate,
      persist,
      onHydrate,
      subject,
      persistence,
    );
  }

  @override
  void onAdd(T event) {
    _subject.add(event);
    _persistValue(event);
  }

  @override
  ValueStream<T> get stream => this;

  @override
  bool get hasValue => _subject.hasValue;

  @override
  T? get valueOrNull => _subject.valueOrNull;

  /// Get the latest value emitted by the Subject
  @override
  T get value => _subject.value;

  /// Set and emit the new value
  set value(T newValue) => add(value);

  @override
  Object get error => _subject.error;

  @override
  Object? get errorOrNull => _subject.errorOrNull;

  @override
  bool get hasError => _subject.errorOrNull != null;

  @override
  StackTrace? get stackTrace => _subject.stackTrace;

  /// Hydrates the HydratedSubject with a value stored on the user's device.
  ///
  /// Must be called to retrieve values stored on the device.
  Future<void> _hydrateSubject() async {
    try {
      T? val;
      if (_hydrate != null) {
        final persistedValue = await _persistence.get<String>(_key);
        if (persistedValue != null) {
          val = _hydrate!(persistedValue);
        }
      } else {
        val = await _persistence.get<T>(_key);
      }

      // do not hydrate if the store is empty or matches the seed value
      // TODO: allow writing of seedValue if it is intentional
      if (val != null && val != _seedValue) {
        _subject.add(val);
      }

      _onHydrate?.call();
    } on PersistenceError catch (e, s) {
      addError(e, s);
    }
  }

  void _persistValue(T val) async {
    try {
      var persistedVal;
      if (_persist != null) {
        persistedVal = _persist!(val);
        _persistence.put<String>(_key, persistedVal);
      } else {
        persistedVal = val;
        _persistence.put<T>(_key, persistedVal);
      }
    } on PersistenceError catch (e, s) {
      addError(e, s);
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
