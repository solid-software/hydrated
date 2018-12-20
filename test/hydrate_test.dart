import 'package:flutter_test/flutter_test.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:hydrate/hydrate.dart';

void main() {
  SharedPreferences.setMockInitialValues({
    "flutter.prefs": true,
    "flutter.int": 1,
    "flutter.double": 1.1,
    "flutter.bool": true,
    "flutter.String": "first",
    // "flutter.List<String>": ["a", "b"],
  });

  test('shared preferences', () async {
    final prefs = await SharedPreferences.getInstance();

    final value = prefs.getBool("prefs");
    expect(value, equals(true));
  });

  test('int', () async {
    final subject = HydratedSubject<int>("int");
    await testHydrated<int>(subject, 1, 2);
  });

  test('double', () async {
    final subject = HydratedSubject<double>("double");
    await testHydrated<double>(subject, 1.1, 2.2);
  });

  test('bool', () async {
    final subject = HydratedSubject<bool>("bool");
    await testHydrated<bool>(subject, true, false);
  });

  test('String', () async {
    final subject = HydratedSubject<String>("String");
    await testHydrated<String>(subject, "first", "second");
  });

  // test('List<String>', () async {
  //   final subject = HydratedSubject<List>("List<String>");
  //   testHydrated<List>(subject, ["a", "b"], ["b", "c"]);
  // });
}

Future<void> testHydrated<T>(
  HydratedSubject<T> subject,
  T first,
  T second,
) async {
  /// null before hydrate
  expect(subject.value, equals(null));

  /// properly hydrates
  await subject.hydrate();
  expect(subject.value, equals(first));

  /// add values
  subject.add(second);
  expect(subject.value, equals(second));

  /// check value in store
  final prefs = await SharedPreferences.getInstance();
  expect(prefs.get(subject.key), equals(second));

  /// clean up
  subject.close();
}
