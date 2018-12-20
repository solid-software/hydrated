import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';
import 'package:hydrate/hydrate.dart';

import 'bloc.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppBloc(
      child: MaterialApp(
        title: 'Hydrate Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: MyHomePage(title: 'Hydrate Demo Home Page'),
      ),
    );
  }
}

class MyHomePage extends StatelessWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  Widget build(BuildContext context) {
    final count$ = AppBloc.of(context).count$;

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
        onPressed: () => count$.add(count$.value + 1),
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ),
    );
  }
}
