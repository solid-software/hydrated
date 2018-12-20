import 'package:flutter_test/flutter_test.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:hydrate/hydrate.dart';

void main() {
  SharedPreferences.setMockInitialValues({
    "flutter.prefs": true,
    "flutter.int": 1,
  });

  test('shared preferences', () async {
    final prefs = await SharedPreferences.getInstance();

    final value = prefs.getBool("prefs");
    expect(value, equals(true));
  });

  test('int', () async {
    /// null before hydrate
    final subject = HydratedSubject<int>("int");
    expect(subject.value, equals(null));

    /// properly hydrates
    await subject.hydrate();
    expect(subject.value, equals(1));

    /// add values
    subject.add(2);
    expect(subject.value, equals(2));

    /// check value in store
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt("int"), equals(2));

    /// clean up
    subject.close();
  });
}
