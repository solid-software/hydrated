import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hydrated/src/key_value_store/key_value_store.dart';
import 'package:hydrated/src/key_value_store/shared_preferences_store.dart';
import 'package:rxdart/rxdart.dart';

/// A callback for encoding an instance of a data class into a String.
typedef PersistCallback<T> = String? Function(T);

/// A callback for reconstructing an instance of a data class from a String.
typedef HydrateCallback<T> = T Function(String);

/// A [Subject] that automatically persists its values and hydrates on creation.
///
/// Mimics the behavior of a [BehaviorSubject].
///
/// The set of supported classes depends on the [KeyValueStore] implementation.
/// For a list of types supported by default see [SharedPreferencesStore].
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
///     hydrate: (String s) => User.fromJson(s),
///     persist: (User user) => user.toJSON(),
///     seedValue: User.empty(),
///   );
/// ```
///
/// Hydration is performed automatically and is asynchronously.
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

  /// Create an instance of a [HydratedSubject] that will persist
  /// values of type [T] by the provided [key] using the [keyValueStore].
  ///
  /// The [seedValue], if specified is emitted immediately after instantiating
  /// the subject.
  ///
  /// When used with structured data, [hydrate] and [persist] callbacks
  /// must both be provided.
  factory HydratedSubject(
    String key, {
    T? seedValue,
    HydrateCallback<T>? hydrate,
    PersistCallback<T>? persist,
    VoidCallback? onHydrate,
    VoidCallback? onListen,
    VoidCallback? onCancel,
    bool sync = false,
    KeyValueStore keyValueStore = const SharedPreferencesStore(),
  }) {
    assert(
      (hydrate == null && persist == null) ||
          (hydrate != null && persist != null),
      '`hydrate` and `persist` callbacks must both be present.',
    );
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
      keyValueStore,
    );
  }

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

  @override
  void onAdd(T event) {
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
  set value(T newValue) => add(newValue);

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
      final hydrate = _hydrate;
      if (hydrate != null) {
        final persistedValue = await _persistence.get<String>(_key);
        if (persistedValue != null) {
          val = hydrate(persistedValue);
        }
      } else {
        val = await _persistence.get<T?>(_key);
      }

      // do not hydrate if the store is empty or matches the seed value
      // TODO: allow writing of seedValue if it is intentional
      if (val != null && val != _seedValue) {
        _subject.add(val);
      }

      _onHydrate?.call();
    } catch (e, s) {
      addError(e, s);
    }
  }

  Future<void> _persistValue(T val) async {
    try {
      final persist = _persist;
      if (persist != null) {
        final serializedValue = persist(val);
        await _persistence.put<String>(_key, serializedValue);
      } else {
        await _persistence.put<T>(_key, val);
      }
    } catch (e, s) {
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
