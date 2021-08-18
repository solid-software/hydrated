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
  final _count = HydratedSubject<int>(
    persistence: SharedPreferencesPersistence(key: "count"),
    seedValue: 0,
  );

  MyHomePage({
    Key? key,
    required String title,
  })  : _title = title,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(this._title),
      ),
      body: Center(
        child: StreamBuilder<int>(
          stream: _count,
          initialData: _count.value,
          builder: (context, snap) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('You have pushed the button this many times:'),
              Text(
                '${snap.data}',
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
    _count.value++;
  }

  void dispose() {
    _count.close();
  }
}
