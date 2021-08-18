import 'dart:async';
import 'dart:convert';

import 'package:equatable/equatable.dart';
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

  group('HydratedSubject', () {
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

      test('SerializedClass', () async {
        const key = 'SerializedClass';
        final first = SerializedClass(true, 24);
        _setMockPersistedValue(key, first.toJSON());

        final persistence = SharedPreferencesPersistence<SerializedClass>(
          key: key,
          hydrate: (s) => SerializedClass.fromJSON(s),
          persist: (c) => c.toJSON(),
        );

        final second = SerializedClass(false, 42);

        /// restores from pre-existing persisted value
        expect(await persistence.get(), equals(first));

        /// persist a new value
        persistence.put(second);
        expect(await persistence.get(), equals(second));

        /// check shared_preferences stored value
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.get(key), equals('{"value":false,"count":42}'));
      });
    });
  });
}

/// An example of a class that serializes to and from a string
class SerializedClass extends Equatable {
  final bool value;
  final int count;

  SerializedClass(this.value, this.count);

  factory SerializedClass.fromJSON(String s) {
    final map = jsonDecode(s);

    return SerializedClass(
      map['value'],
      map['count'],
    );
  }

  String toJSON() => jsonEncode({
        'value': this.value,
        'count': this.count,
      });

  @override
  List<Object?> get props => [value, count];
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
  final persistence = SharedPreferencesPersistence<T>(key: key);

  /// null before setting anything
  expect(await persistence.get(), isNull);

  _setMockPersistedValue(key, first);

  /// restores from pre-existing persisted value
  expect(await persistence.get(), equals(first));

  /// persists a new value
  await persistence.put(second);
  expect(await persistence.get(), equals(second));

  /// check shared_preferences stored value
  final prefs = await SharedPreferences.getInstance();
  expect(prefs.get(key), equals(second));

  /// remove persisted value
  await persistence.put(null as T);
  expect(await persistence.get(), isNull);
}
