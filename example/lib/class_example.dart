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
  final count$ = HydratedSubject<Data>(
    "count",
    hydrate: (value) => Data.fromJSON(value),
    persist: (value) => value.toJSON,
    seedValue: Data.fromJSON("0"),
  );

  MyHomePage({Key key, this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    this.count$.hydrate();

    return Scaffold(
      appBar: AppBar(
        title: Text(this.title),
      ),
      body: Center(
        child: StreamBuilder<Data>(
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
                    style: Theme.of(context).textTheme.display1,
                  ),
                ],
              ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final count = count$.value.count + 1;
          count$.add(Data.fromJSON(count.toString()));
        },
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ),
    );
  }
}

class Data {
  final int count;

  Data.fromJSON(String json) : this.count = int.parse(json);

  String get toJSON => count.toString();
}
