library hydrated;

import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rxdart/rxdart.dart';

/// A [BehaviorSubject] that automatically persists its values and is asynchrously hydrated.
///
/// Hydrate with the async method [HydratedSubject.hydrate()].
///
/// HydratedSubject supports the same types as [shared_preferences] such as: `int`, `double`, `bool`, `String`, and `List<String>`
///
/// Example:
///
/// ```
///   final count$ = HydratedSubject<int>("count", seedValue: 0);
///   await count$.hydrate();
/// ```

class HydratedSubject<T> extends AbstractHydratedSubject<T>
    implements ValueObservable<T> {
  HydratedSubject._(
    String _key,
    T _seedValue,
    T Function(String value) _hydrate,
    String Function(T value) _persist,
    StreamController<T> controller,
    Observable<T> observable,
    _Wrapper<T> _wrapper,
  ) : super(_key, _seedValue, _hydrate, _persist, controller, observable,
            _wrapper);

  factory HydratedSubject(
    String key, {
    T seedValue,
    T Function(String value) hydrate,
    String Function(T value) persist,
    void onListen(),
    void onCancel(),
    bool sync: false,
  }) {
    // assert that T is a type compatible with shared_preferences
    assert(T == int ||
        T == double ||
        T == bool ||
        T == String ||
        [""] is T ||
        (hydrate != null && persist != null));

    final setup = HydratedSetup(seedValue, onListen, onCancel, sync);

    return HydratedSubject<T>._(key, seedValue, hydrate, persist,
        setup.controller, setup.observable, setup.wrapper);
  }

  /// Hydrates the HydratedSubject with a value stored on the user's device.
  ///
  /// Must be called to retrieve values stored on the device.
  @override
  Future<void> hydrate() async {
    final prefs = await SharedPreferences.getInstance();

    var val;

    if (T == int)
      val = prefs.getInt(this._key);
    else if (T == double)
      val = prefs.getDouble(this._key);
    else if (T == bool)
      val = prefs.getBool(this._key);
    else if (T == String)
      val = prefs.getString(this._key);
    else if ([""] is T)
      val = prefs.getStringList(this._key);
    else if (this._hydrate != null)
      val = this._hydrate(prefs.getString(this._key));
    else
      Exception(
        "HydratedSubject – shared_preferences returned an invalid type",
      );

    // do not hydrate if the store is empty or matches the seed value
    if (val != null && val != _seedValue) {
      print("added");
      add(val);
    }
  }

  @override
  _persistValue(T val) async {
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
    else if (this._persist != null)
      await prefs.setString(_key, this._persist(val));
    else
      Exception(
        "HydratedSubject – value must be int, double, bool, String, or List<String>",
      );
  }
}

abstract class AbstractHydratedSubject<T> extends Subject<T>
    implements ValueObservable<T> {
  String _key;
  T _seedValue;
  _Wrapper<T> _wrapper;

  T Function(String value) _hydrate;
  String Function(T value) _persist;

  AbstractHydratedSubject(
    this._key,
    this._seedValue,
    this._hydrate,
    this._persist,
    StreamController<T> controller,
    Observable<T> observable,
    this._wrapper,
  ) : super(controller, observable);

  @override
  void onAdd(T event) {
    _wrapper.latestValue = event;
    _persistValue(event);
  }

  @override
  ValueObservable<T> get stream => this;

  /// Get the latest value emitted by the Subject
  @override
  T get value => _wrapper.latestValue;

  /// Set and emit the new value
  set value(T newValue) => add(newValue);

  /// Hydrates the HydratedSubject with a value stored on the user's device.
  ///
  /// Must be called to retrieve values stored on the device.
  Future<void> hydrate();

  _persistValue(T val);

  /// A unique key that references a storage container for a value persisted on the device.
  String get key => this._key;
}

class HydratedSetup<T> {
  // ignore: close_sinks
  StreamController<T> controller;
  _Wrapper<T> wrapper;
  Observable<T> observable;

  HydratedSetup(T seedValue, void onListen(), void onCancel(), bool sync) {
    // ignore: close_sinks
    controller = StreamController<T>.broadcast(
      onListen: onListen,
      onCancel: onCancel,
      sync: sync,
    );

    wrapper = _Wrapper<T>(seedValue);

    observable = Observable<T>.defer(
        () => wrapper.latestValue == null
            ? controller.stream
            : Observable<T>(controller.stream).startWith(wrapper.latestValue),
        reusable: true);
  }
}

class _Wrapper<T> {
  T latestValue;

  _Wrapper(this.latestValue);
}
