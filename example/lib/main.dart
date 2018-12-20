import 'package:flutter/material.dart';
import 'package:hydrate/hydrate.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hydrate Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Hydrate Demo'),
    );
  }
}

class MyHomePage extends StatelessWidget {
  final String title;
  final count$ = HydratedSubject<int>("count", seedValue: 0);

  MyHomePage({Key key, this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    this.count$.hydrate();

    return Scaffold(
      appBar: AppBar(
        title: Text(this.title),
      ),
      body: Center(
        child: StreamBuilder<int>(
          stream: count$,
          initialData: count$.value,
          builder: (context, snap) => Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    'You have pushed the button this many times:',
                  ),
                  Text(
                    '${snap.data}',
                    style: Theme.of(context).textTheme.display1,
                  ),
                ],
              ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => count$.value++,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ),
    );
  }
}
