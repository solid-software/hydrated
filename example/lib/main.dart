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

  final _count = HydratedSubject<int>("count", seedValue: 0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
      ),
      body: Center(
        child: StreamBuilder<int>(
          stream: _count,
          initialData: _count.value,
          builder: (context, snap) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('You have pushed the button this many times:'),
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
        child: const Icon(Icons.add),
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
