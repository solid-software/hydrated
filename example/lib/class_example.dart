import 'package:flutter/material.dart';
import 'package:hydrated/hydrated.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hydrated Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Hydrated Demo'),
    );
  }
}

class MyHomePage extends StatelessWidget {
  MyHomePage({
    Key? key,
    required String title,
  })  : _title = title,
        super(key: key);

  final String _title;

  final _countSubject = HydratedSubject<SerializedClass>(
    "serialized-count",
    hydrate: (value) => SerializedClass.fromJSON(value),
    persist: (value) => value.toJSON,
    seedValue: const SerializedClass(0),
  );

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

class SerializedClass {
  const SerializedClass(this.count);

  SerializedClass.fromJSON(String json) : count = int.parse(json);

  final int count;

  String get toJSON => count.toString();
}
