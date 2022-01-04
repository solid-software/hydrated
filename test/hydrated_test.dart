// ignore_for_file: close_sinks, avoid-late-keyword,
// ignore_for_file: implicit_dynamic_function, implicit_dynamic_parameter

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated/hydrated.dart';

typedef GetOverride = Future<dynamic> Function(String key);
typedef PutOverride = Future<void> Function(String key, dynamic value);

class _InMemoryKeyValueStore implements KeyValueStore {
  final Map<String, Object?> store = {};

  GetOverride? getOverride;
  @override
  Future<T?> get<T>(String key) async {
    final _getOverride = getOverride;
    if (_getOverride != null) return _getOverride(key) as Future<T?>;

    return store[key] as T?;
  }

  PutOverride? putOverride;
  @override
  Future<void> put<T>(String key, T? value) async {
    final _putOverride = putOverride;
    if (_putOverride != null) {
      await _putOverride(key, value);

      return;
    }
    store[key] = value;
  }
}

class TestDataClass {
  const TestDataClass(this.value);

  factory TestDataClass.fromJson(Map<String, Object?> json) =>
      TestDataClass(json['value'] as int);

  final int value;

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

        HydratedSubject<int>(key, keyValueStore: mockKeyValueStore);
      });

      test(
          'Given persisted value is present, when it hydrates, '
          'it emits the value', () {
        const testValue = 42;
        mockKeyValueStore.getOverride = (_) async => testValue;
        final subject =
            HydratedSubject<int>(key, keyValueStore: mockKeyValueStore);

        expect(subject, emits(testValue));
      });

      test('Given persisted value is null, when it hydrates, it emits nothing',
          () {
        mockKeyValueStore.getOverride = (_) async => null;
        final subject =
            HydratedSubject<int>(key, keyValueStore: mockKeyValueStore);

        expect(subject, neverEmits(anything));
        subject.close();
      });

      test(
          'Given `hydrate` is supplied, but `persist` is ommited, '
          'it throws an AssertionError', () {
        expect(
          () {
            HydratedSubject(
              key,
              keyValueStore: mockKeyValueStore,
              hydrate: (_) => 1,
            );
          },
          throwsA(isA<AssertionError>()),
        );
      });

      test(
          'Given `persist` is supplied, but `hydrate` is ommited, '
          'it throws an AssertionError', () {
        expect(
          () {
            HydratedSubject(
              key,
              keyValueStore: mockKeyValueStore,
              persist: (_) => '',
            );
          },
          throwsA(isA<AssertionError>()),
        );
      });

      test('uses hydrate callback, and emits the output of the callback', () {
        const testPersistedValue = '24';
        const testHydratedValue = 42;
        mockKeyValueStore.getOverride = (_) async => testPersistedValue;

        final hydrateCallback = expectAsync1(
          (String persistedValue) {
            expect(persistedValue, equals(testPersistedValue));

            return testHydratedValue;
          },
          count: 1,
        );

        final subject = HydratedSubject<int>(
          key,
          keyValueStore: mockKeyValueStore,
          hydrate: hydrateCallback,
          persist: (_) => '',
        );

        expect(subject, emits(testHydratedValue));
      });
    });

    test('exposes the persistence key', () {
      final subject =
          HydratedSubject<int>(key, keyValueStore: mockKeyValueStore);

      expect(subject.key, key);
    });

    test('when adding a value, it saves the value with the key-value store',
        () {
      const testValue = 42;
      mockKeyValueStore.putOverride = expectAsync2(
        (key, dynamic value) async {
          expect(value, equals(testValue));
        },
        count: 1,
      );
      final subject =
          HydratedSubject<int>(key, keyValueStore: mockKeyValueStore);

      subject.add(testValue);
    });

    test(
        'when adding a value, '
        'it uses the `persist` callback, '
        'and saves the output of this callback', () {
      const testAddedValue = 42;
      const testPersistedValue = '24';

      final persistCallback = expectAsync1(
        (int value) {
          expect(value, equals(testAddedValue));

          return testPersistedValue;
        },
        count: 1,
      );

      mockKeyValueStore.putOverride = expectAsync2(
        (key, value) async {
          expect(value, isA<String>());
          expect(value, equals(testPersistedValue));
        },
        count: 1,
      );
      final subject = HydratedSubject<int>(
        key,
        keyValueStore: mockKeyValueStore,
        hydrate: (_) => 1,
        persist: persistCallback,
      );

      subject.add(testAddedValue);
    });

    group('persistence error handling', () {
      test(
          'given persistence interface `get` throws a StoreError, '
          'it emits the error through the stream', () {
        mockKeyValueStore.getOverride = (_) async => throw StoreError('test');
        final subject =
            HydratedSubject<int>(key, keyValueStore: mockKeyValueStore);

        expect(subject, emitsError(isA<StoreError>()));
      });

      test(
          'given persistence interface `get` throws an Exception, '
          'constructing the HydratedSubject throws '
          'an asynchronous uncatchable error', () {
        mockKeyValueStore.getOverride = (_) async => throw Exception('test');
        runZonedGuarded(
          () {
            final completer = Completer<void>();
            HydratedSubject<int>(
              key,
              keyValueStore: mockKeyValueStore,
              onHydrate: completer.complete,
            );

            return completer.future;
          },
          expectAsync2(
            (error, _) {
              expect(error, isA<Exception>());
            },
            count: 1,
          ),
        );
      });

      test(
          'given persistence interface put throws a StoreError, '
          'it emits the error through the stream', () async {
        const testValue = 42;
        mockKeyValueStore.putOverride =
            (_, dynamic __) => throw StoreError('test');
        final subject =
            HydratedSubject<int>(key, keyValueStore: mockKeyValueStore);

        final expectation = expectLater(
          subject,
          emitsInOrder(<Matcher>[
            equals(42),
            emitsError(isA<StoreError>()),
          ]),
        );
        subject.add(testValue);

        await expectation;
      });
    });
  });
}
