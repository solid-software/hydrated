import 'package:flutter_test/flutter_test.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:hydrate/hydrate.dart';

void main() {
  test('shared preferences', () async {
    SharedPreferences.setMockInitialValues({
      "flutter.prefs": "works",
    });

    final prefs = await SharedPreferences.getInstance();

    final value = prefs.getString("prefs");
    expect(value, equals("works"));
  });

  test('hydrated int', () async {
    SharedPreferences.setMockInitialValues({
      "flutter.int": 1,
    });

    /// null before hydrate
    final subject = HydratedSubject<int>("int");
    expect(subject.value == null, equals(true));

    /// properly hydrates
    await subject.hydrate();
    expect(subject.value == 1, equals(true));

    /// clean up
    subject.close();
  });
}
