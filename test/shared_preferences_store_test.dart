import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated/hydrated.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Shared Preferences set mock initial values', () async {
    final key = 'prefs';
    _setMockPersistedValue(key, true);

    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getBool(key);
    expect(value, isTrue);
  });

  group('SharedPreferencesStore', () {
    group('handles unsupported types', () {
      test(
          'when saving a value with an unsupported type, it throws an AssertionError',
          () {
        final unsupportedTypeValue = Exception('test unsupported value');
        expect(
          () => SharedPreferencesStore().put('key', unsupportedTypeValue),
          throwsA(isA<AssertionError>()),
        );
      });

      test(
          'when getting a value with an unspecified type (dynamic), it throws an AssertionError',
          () {
        expect(
          () => SharedPreferencesStore().get('key'),
          throwsA(isA<AssertionError>()),
        );
      });

      test(
          'when getting a value with an unsupported type, it throws an AssertionError',
          () {
        expect(
          () => SharedPreferencesStore().get<Exception>('key'),
          throwsA(isA<AssertionError>()),
        );
      });

      test(
          'when SharedPreferences return an unsupported type, it throws a PersistenceError',
          () {
        final unsupportedTypeValue = Exception('test unsupported value');
        _setMockPersistedValue('key', unsupportedTypeValue);
        expect(
          () => SharedPreferencesStore().get<int>('key'),
          throwsA(isA<PersistenceError>()),
        );
      });
    });

    group('correctly handles data type', () {
      test('int', () async {
        await _testPersistence<int?>("int", 1, 2);
      });

      test('double', () async {
        await _testPersistence<double?>("double", 1.1, 2.2);
      });

      test('bool', () async {
        await _testPersistence<bool?>("bool", true, false);
      });

      test('String', () async {
        await _testPersistence<String?>("String", "first", "second");
      });

      test('List<String>', () async {
        _testPersistence<List<String>?>("List<String>", ["a", "b"], ["c", "d"]);
      });
    });
  });
}

void _setMockPersistedValue(String key, dynamic value) {
  SharedPreferences.setMockInitialValues({
    "flutter.$key": value,
  });
}

/// The test procedure for a HydratedSubject
Future<void> _testPersistence<T>(
  String key,
  T first,
  T second,
) async {
  final persistence = SharedPreferencesStore();

  /// null before setting anything
  expect(await persistence.get<T>(key), isNull);

  _setMockPersistedValue(key, first);

  /// restores from pre-existing persisted value
  expect(await persistence.get<T>(key), equals(first));

  /// persists a new value
  await persistence.put(key, second);
  expect(await persistence.get<T>(key), equals(second));

  /// check shared_preferences stored value
  final prefs = await SharedPreferences.getInstance();
  expect(prefs.get(key), equals(second));

  /// remove persisted value
  await persistence.put(key, null as T);
  expect(await persistence.get<T>(key), isNull);
}
