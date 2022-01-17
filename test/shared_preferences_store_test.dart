import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated/hydrated.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Shared Preferences set mock initial values', () async {
    const key = 'prefs';
    _setMockPersistedValue(key, true);

    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getBool(key);
    expect(value, isTrue);
  });

  group('SharedPreferencesStore', () {
    group('handles unsupported types', () {
      test(
          'when saving a value with an unsupported type, '
          'it throws a StoreError', () {
        final unsupportedTypeValue = Exception('test unsupported value');
        expect(
          () => const SharedPreferencesStore().put('key', unsupportedTypeValue),
          throwsA(isA<StoreError>()),
        );
      });

      test(
          'when getting a value with an unspecified type (dynamic), '
          'it throws an StoreError', () {
        expect(
          // ignore: implicit_dynamic_method
          () => const SharedPreferencesStore().get('key'),
          throwsA(isA<StoreError>()),
        );
      });

      test(
          'when getting a value with an unsupported type, '
          'it throws an StoreError', () {
        expect(
          () => const SharedPreferencesStore().get<Exception>('key'),
          throwsA(isA<StoreError>()),
        );
      });

      test(
          'when SharedPreferences return an unsupported type, '
          'it throws a StoreError', () {
        final unsupportedTypeValue = Exception('test unsupported value');
        _setMockPersistedValue('key', unsupportedTypeValue);
        expect(
          () => const SharedPreferencesStore().get<int>('key'),
          throwsA(isA<StoreError>()),
        );
      });
    });

    group('correctly handles data type', () {
      test('int', () async {
        const initial = 1;
        const changed = 2;
        await _testPersistence<int?>(
          "int",
          initialValue: initial,
          changedValue: changed,
        );
      });

      test('double', () async {
        const initial = 1.1;
        const changed = 2.2;
        await _testPersistence<double?>(
          "double",
          initialValue: initial,
          changedValue: changed,
        );
      });

      test('bool', () async {
        await _testPersistence<bool?>(
          "bool",
          initialValue: true,
          changedValue: false,
        );
      });

      test('String', () async {
        await _testPersistence<String?>(
          "String",
          initialValue: "first",
          changedValue: "second",
        );
      });

      test('List<String>', () async {
        await _testPersistence<List<String>?>(
          "List<String>",
          initialValue: ["a", "b"],
          changedValue: ["c", "d"],
        );
      });
    });
  });
}

void _setMockPersistedValue(String key, Object? value) {
  SharedPreferences.setMockInitialValues({
    if (value != null) "flutter.$key": value,
  });
}

/// The test procedure for a HydratedSubject
Future<void> _testPersistence<T>(
  String key, {
  required T initialValue,
  required T changedValue,
}) async {
  const persistence = SharedPreferencesStore();

  /// null before setting anything
  expect(await persistence.get<T>(key), isNull);

  _setMockPersistedValue(key, initialValue);

  /// restores from pre-existing persisted value
  expect(await persistence.get<T>(key), equals(initialValue));

  /// persists a new value
  await persistence.put(key, changedValue);
  expect(await persistence.get<T>(key), equals(changedValue));

  /// check shared_preferences stored value
  final prefs = await SharedPreferences.getInstance();
  expect(prefs.get(key), equals(changedValue));

  /// remove persisted value
  await persistence.put(key, null as T);
  expect(await persistence.get<T>(key), isNull);
}
