// ignore_for_file: close_sinks
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated/hydrated.dart';

typedef _GetOverride = Future<dynamic> Function(String key);
typedef _PutOverride = Future<void> Function(String key, dynamic value);

class _InMemoryKeyValueStore implements KeyValueStore {
  final Map<String, dynamic> store = {};

  _GetOverride? getOverride;
  @override
  Future<T?> get<T>(String key) async {
    if (getOverride != null) return getOverride!(key) as Future<T?>;
    return store[key] as T?;
  }

  _PutOverride? putOverride;
  @override
  Future<void> put<T>(String key, T? value) async {
    if (putOverride != null) {
      putOverride!(key, value);
      return;
    }
    store[key] = value;
  }
}

class TestDataClass {
  final int value;

  TestDataClass(this.value);

  static TestDataClass fromJson(Map<String, Object?> json) =>
      TestDataClass(json['value'] as int);

  Map<String, Object?> toJson() => {'value': value};
}

void main() {
  const key = 'key';
  late _InMemoryKeyValueStore mockKeyValueStore;
  setUp(() {
    mockKeyValueStore = _InMemoryKeyValueStore();
  });

  group('HydratedSubject', () {
    group('hydration', () {
      test('Tries to hydrate upon instantiation', () {
        mockKeyValueStore.getOverride = expectAsync1((_) async {}, count: 1);

        HydratedSubject<int>(key, persistence: mockKeyValueStore);
      });

      test(
          'Given persisted value is present, when it hydrates, it emits the value',
          () {
        mockKeyValueStore.getOverride = (_) async => 42;
        final subject =
            HydratedSubject<int>(key, persistence: mockKeyValueStore);

        expect(subject, emits(42));
      });

      test('Given persisted value is null, when it hydrates, it emits nothing',
          () {
        mockKeyValueStore.getOverride = (_) async => null;
        final subject =
            HydratedSubject<int>(key, persistence: mockKeyValueStore);

        expect(subject, neverEmits(anything));
        subject.close();
      });

      test(
          'Given `hydrate` is supplied, but `persist` is ommited, it throws an AssertionError',
          () {
        expect(() {
          HydratedSubject(key,
              persistence: mockKeyValueStore, hydrate: (_) => 1);
        }, throwsA(isA<AssertionError>()));
      });

      test(
          'Given `persist` is supplied, but `hydrate` is ommited, it throws an AssertionError',
          () {
        expect(() {
          HydratedSubject(key,
              persistence: mockKeyValueStore, persist: (_) => '');
        }, throwsA(isA<AssertionError>()));
      });

      test('uses hydrate callback, and emits the output of the callback', () {
        const testPersistedValue = '24';
        const testHydratedValue = 42;
        mockKeyValueStore.getOverride = (_) async => testPersistedValue;

        final hydrateCallback = expectAsync1((String persistedValue) {
          expect(persistedValue, equals(testPersistedValue));
          return testHydratedValue;
        }, count: 1);

        final subject = HydratedSubject<int>(
          key,
          persistence: mockKeyValueStore,
          hydrate: hydrateCallback,
          persist: (_) => '',
        );

        expect(subject, emits(testHydratedValue));
      });
    });

    test('when adding a value, it saves the value with the key-value store',
        () {
      const testValue = 42;
      mockKeyValueStore.putOverride = expectAsync2((key, value) async {
        expect(value, equals(testValue));
      }, count: 1);
      final subject = HydratedSubject<int>(key, persistence: mockKeyValueStore);

      subject.add(testValue);
    });

    test(
        'when adding a value, it uses the `persist` callback, and saves the output of this callback',
        () {
      const testAddedValue = 42;
      const testPersistedValue = '24';

      final persistCallback = expectAsync1((int value) {
        expect(value, equals(testAddedValue));
        return testPersistedValue;
      }, count: 1);

      mockKeyValueStore.putOverride = expectAsync2((key, value) async {
        expect(value, isA<String>());
        expect(value, equals(testPersistedValue));
      }, count: 1);
      final subject = HydratedSubject<int>(
        key,
        persistence: mockKeyValueStore,
        hydrate: (_) => 1,
        persist: persistCallback,
      );

      subject.add(testAddedValue);
    });
  });
}
