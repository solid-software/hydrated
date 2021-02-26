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
  final String title;

  final count$ = HydratedSubject<SerializedClass>(
    "serialized-count",
    hydrate: (value) => SerializedClass.fromJSON(value),
    persist: (value) => value.toJSON,
    seedValue: SerializedClass(0),
  );

  MyHomePage({Key key, this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print('Serialized Hydrated Demo');

    return Scaffold(
      appBar: AppBar(
        title: Text(this.title),
      ),
      body: Center(
        child: StreamBuilder<SerializedClass>(
          stream: count$,
          initialData: count$.value,
          builder: (context, snap) => Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    'You have pushed the button this many times:',
                  ),
                  Text(
                    '${snap.data.count}',
                    style: Theme.of(context).textTheme.headline4,
                  ),
                ],
              ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final count = count$.value.count + 1;
          count$.add(SerializedClass(count));
        },
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ),
    );
  }
}

class SerializedClass {
  final int count;

  SerializedClass(this.count);

  SerializedClass.fromJSON(String json) : this.count = int.parse(json);

  String get toJSON => count.toString();
}
