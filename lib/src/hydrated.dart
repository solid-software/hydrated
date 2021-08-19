import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hydrated/src/persistence/generic_value_persistence.dart';
import 'package:hydrated/src/persistence/persistence_error.dart';
import 'package:hydrated/src/persistence/shared_preferences_persistence.dart';
import 'package:rxdart/rxdart.dart';

/// A callback for encoding an instance of a data class into a String.
typedef PersistCallback<T> = String? Function(T);

/// A callback for reconstructing an instance of a data class from a String.
typedef HydrateCallback<T> = T Function(String);

/// A [Subject] that automatically persists its values and hydrates on creation.
///
/// Mimics the behavior of a [BehaviorSubject].
///
/// The set of supported classes depends on the [GenericValuePersistence] implementation.
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
  final BehaviorSubject<T> _subject;
  final VoidCallback? _onHydrate;
  final T? _seedValue;

  final GenericValuePersistence<T> _persistence;

  HydratedSubject._(
    this._seedValue,
    this._onHydrate,
    this._subject,
    this._persistence,
  ) : super(_subject, _subject.stream) {
    _hydrateSubject();
  }

  factory HydratedSubject.custom({
    required GenericValuePersistence<T> persistence,
    T? seedValue,
    VoidCallback? onHydrate,
    VoidCallback? onListen,
    VoidCallback? onCancel,
    bool sync = false,
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
      seedValue,
      onHydrate,
      subject,
      persistence,
    );
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
    final persistenceInterface = SharedPreferencesPersistence(
      key: key,
      hydrate: hydrate,
      persist: persist,
    );

    return HydratedSubject.custom(
      persistence: persistenceInterface,
      onHydrate: onHydrate,
      onCancel: onCancel,
      onListen: onListen,
      sync: sync,
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
      final val = await _persistence.get();

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
      _persistence.put(val);
    } on PersistenceError catch (e, s) {
      addError(e, s);
    }
  }

  @override
  Subject<R> createForwardingSubject<R>({
    VoidCallback? onListen,
    VoidCallback? onCancel,
    bool sync = false,
    GenericValuePersistence<R>? persistence,
  }) {
    return HydratedSubject.custom(
      onListen: onListen,
      onCancel: onCancel,
      sync: sync,
      persistence: persistence!,
    );
  }
}
