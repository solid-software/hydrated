# Hydrated

[![Version](https://img.shields.io/pub/v/hydrated)](https://pub.dev/packages/hydrated)
[![Build](https://img.shields.io/github/workflow/status/lukepighetti/hydrated/Flutter)](https://github.com/lukepighetti/hydrated/actions?query=Flutter)
[![License](https://img.shields.io/github/license/lukepighetti/hydrated)](https://opensource.org/licenses/MIT)

Hydrated provides a Subject that automatically persists to Flutter's local storage and hydrates on creation!


## Easy to consume

All values are persisted with `shared_preferences` and restored with automatic hydration.

```dart
final count$ = HydratedSubject<int>("count", seedValue: 0);

/// count$ will automagically be hydrated with 42 next time it is created
count$.add(42);
```

## Ready for BLoC

```dart
class HydratedBloc {
  final _count$ = HydratedSubject<int>("count", seedValue: 0);

  ValueObservable<int> get count$ => _count$.stream;
  Sink<int> get setCount => _count$.sink;

  dispose() {
    _count$.close();
  }
}
```

## Supports simple types and serialized classes

We support all `shared_preferences` types.

- `int`
- `double`
- `bool`
- `String`
- `List<String>`

```dart
final count$ = HydratedSubject<int>("count");
```

We also support serialized classes with `hydrate` and `persist` arguments.

```dart
final user$ = HydratedSubject<User>(
  "user",
  hydrate: (String s) => User.fromJSON(s),
  persist: (User user) => user.toJSON(),
);
```

## Reliable

Hydrated is mock tested with all supported types and is dogfooded by its creator.

## Extensible

Hydrated supports any key-value data storages -- just implement the `KeyValueStore` interface
and you will be able to use *hive*, *flutter_secure_storage* or any other persistence solution of your choice.

```dart
class MyAwesomeKeyValueStore implements KeyValueStore {
  /// your implementation here...
}

final user = HydratedSubject<User>(
  "user",
  hydrate: (String s) => User.fromJson(s),
  persist: (User user) => user.toJSON(),
  keyValueStore: MyAwesomeKeyValueStore()
);
```

## Demo

<img alt="demo of Hydrated BehaviorSubject between app restarts" src="https://raw.githubusercontent.com/lukepighetti/hydrated/master/doc/hydrated.gif" width="400">

## Original developer

`hydrated` was originally developed by [@lukepighetti](https://github.com/lukepighetti).
