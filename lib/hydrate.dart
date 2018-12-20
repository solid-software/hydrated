library hydrate;

import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rxdart/rxdart.dart';

class HydratedSubject<T> extends Subject<T> implements ValueObservable<T> {
  String _key;
  T _seedValue;
  _Wrapper<T> _wrapper;

  HydratedSubject._(
    this._key,
    this._seedValue,
    StreamController<T> controller,
    Observable<T> observable,
    this._wrapper,
  ) : super(controller, observable);

  factory HydratedSubject(
    String key, {
    T seedValue,
    void onListen(),
    void onCancel(),
    bool sync: false,
  }) {
    // assert that T is a type compatible with shared_preferences
    // TODO: would prefer a check for List<String> instead of List
    assert(T == int || T == double || T == bool || T == String || T == List);

    // ignore: close_sinks
    final controller = new StreamController<T>.broadcast(
      onListen: onListen,
      onCancel: onCancel,
      sync: sync,
    );

    final wrapper = new _Wrapper<T>(seedValue);

    return new HydratedSubject<T>._(
        key,
        seedValue,
        controller,
        new Observable<T>.defer(
            () => wrapper.latestValue == null
                ? controller.stream
                : new Observable<T>(controller.stream)
                    .startWith(wrapper.latestValue),
            reusable: true),
        wrapper);
  }

  @override
  void onAdd(T event) {
    _wrapper.latestValue = event;
    _persist(event);
  }

  @override
  ValueObservable<T> get stream => this;

  /// Get the latest value emitted by the Subject
  @override
  T get value => _wrapper.latestValue;

  /// Set and emit the new value
  set value(T newValue) => add(newValue);

  /// Hydrates the HydratedSubject with a value stored on the user's device.
  Future<void> hydrate() async {
    final prefs = await SharedPreferences.getInstance();
    final val = prefs.get(this._key);

    if (val != null && val != _seedValue) {
      add(val);
    }
  }

  _persist(T val) async {
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
    else
      Exception(
        "hydrate – value must be int, double, bool, String, or List<String>",
      );
  }
}

class _Wrapper<T> {
  T latestValue;

  _Wrapper(this.latestValue);
}
