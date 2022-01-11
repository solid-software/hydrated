import 'package:flutter/material.dart';
import 'package:hydrated/hydrated.dart';

void main() => runApp(CustomHydrationExample());

/// This is an example showing the usage of [HydratedSubject]
/// with custom persistence and hydration.
class CustomHydrationExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hydrated Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: _MainPage(title: 'Hydrated Demo'),
    );
  }
}

class _MainPage extends StatelessWidget {
  final String _title;

  final _countSubject = HydratedSubject<SerializedClass>(
    "serialized-count",
    hydrate: (value) => SerializedClass.fromJson(value),
    persist: (value) => value.toJSON,
    seedValue: const SerializedClass(0),
  );

  _MainPage({
    Key? key,
    required String title,
  })  : _title = title,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
      ),
      body: Center(
        child: StreamBuilder<SerializedClass>(
          stream: _countSubject,
          initialData: _countSubject.value,
          builder: (context, snapshot) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('You have pushed the button this many times:'),
              Text(
                '${snapshot.data?.count}',
                style: Theme.of(context).textTheme.headline4,
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _incrementCounter() {
    final count = _countSubject.value.count + 1;
    _countSubject.add(SerializedClass(count));
  }
}

/// A sample structured data class.
class SerializedClass {
  /// FAB tap counter.
  final int count;

  /// ADT constructor.
  const SerializedClass(this.count);

  /// Deserialize an instance of a structured data class.
  SerializedClass.fromJson(String json) : count = int.parse(json);

  /// Serialize the data class.
  String get toJSON => count.toString();
}
