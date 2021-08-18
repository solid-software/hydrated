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
  final String _title;

  final _countSubject = HydratedSubject<SerializedClass>(
    persistence: SharedPreferencesPersistence(
      key: "serialized-count",
      hydrate: (value) => SerializedClass.fromJSON(value),
      persist: (value) => value.toJSON,
    ),
    seedValue: SerializedClass(0),
  );

  MyHomePage({
    Key? key,
    required String title,
  })  : _title = title,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    print('Serialized Hydrated Demo');

    return Scaffold(
      appBar: AppBar(
        title: Text(this._title),
      ),
      body: Center(
        child: StreamBuilder<SerializedClass>(
          stream: _countSubject,
          initialData: _countSubject.value,
          builder: (context, snapshot) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('You have pushed the button this many times:'),
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
        child: Icon(Icons.add),
      ),
    );
  }

  void _incrementCounter() {
    final count = _countSubject.value.count + 1;
    _countSubject.add(SerializedClass(count));
  }
}

class SerializedClass {
  final int count;

  const SerializedClass(this.count);

  SerializedClass.fromJSON(String json) : this.count = int.parse(json);

  String get toJSON => count.toString();
}
