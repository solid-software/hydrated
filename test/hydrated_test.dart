import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated/hydrated.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  SharedPreferences.setMockInitialValues({
    "flutter.prefs": true,
    "flutter.int": 1,
    "flutter.double": 1.1,
    "flutter.bool": true,
    "flutter.String": "first",
    "flutter.List<String>": ["a", "b"],
    "flutter.SerializedClass": '{"value":true,"count":42}'
  });

  test('shared preferences', () async {
    final prefs = await SharedPreferences.getInstance();

    final value = prefs.getBool("prefs");
    expect(value, equals(true));
  });

  test('int', () async {
    await testHydrated<int>("int", 1, 2);
  });

  test('double', () async {
    await testHydrated<double>("double", 1.1, 2.2);
  });

  test('bool', () async {
    await testHydrated<bool>("bool", true, false);
  });

  test('String', () async {
    await testHydrated<String>("String", "first", "second");
  });

  test('List<String>', () async {
    testHydrated<List<String>>("List<String>", ["a", "b"], ["c", "d"]);
  });

  test('SerializedClass', () async {
    final completer = Completer();

    final subject = HydratedSubject<SerializedClass>(
      "SerializedClass",
      hydrate: (s) => SerializedClass.fromJSON(s),
      persist: (c) => c == null ? '' : c.toJSON(),
      onHydrate: () => completer.complete(),
    );

    final second = SerializedClass(false, 42);

    /// null before hydrate
    expect(subject.value, equals(null));

    /// properly hydrates
    await completer.future;
    expect(subject.value?.value, equals(true));
    expect(subject.value?.count, equals(42));

    /// add values
    subject.add(second);
    expect(subject.value?.value, equals(false));
    expect(subject.value?.count, equals(42));

    /// check value in store
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.get(subject.key), equals('{"value":false,"count":42}'));

    /// clean up
    subject.close();
  });
}

/// An example of a class that serializes to and from a string
class SerializedClass {
  late final bool value;
  late final int count;

  SerializedClass(this.value, this.count);

  SerializedClass.fromJSON(String s) {
    final map = jsonDecode(s);

    this.value = map['value'];
    this.count = map['count'];
  }

  String toJSON() => jsonEncode({
        'value': this.value,
        'count': this.count,
      });
}

/// The test procedure for a HydratedSubject
Future<void> testHydrated<T>(
  String key,
  T first,
  T second,
) async {
  final completer = Completer();

  final subject = HydratedSubject<T>(
    key,
    onHydrate: () => completer.complete(),
  );

  /// null before hydrate
  expect(subject.value, equals(null));
  expect(subject.hasValue, equals(false));

  /// properly hydrates
  await completer.future;
  expect(subject.value, equals(first));
  expect(subject.hasValue, equals(true));

  /// add values
  subject.add(second);
  expect(subject.value, equals(second));
  expect(subject.hasValue, equals(true));

  /// check value in store
  final prefs = await SharedPreferences.getInstance();
  expect(prefs.get(subject.key), equals(second));

  /// clean up
  subject.close();
}
