import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppBloc extends InheritedWidget {
  final _bloc = _Bloc();

  AppBloc({Key key, Widget child}) : super(key: key, child: child);

  static _Bloc of(BuildContext context) =>
      (context.inheritFromWidgetOfExactType(AppBloc) as AppBloc)._bloc;

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) => true;
}

class _Bloc {
  BehaviorSubject<int> count$; // must be null or it resets progress

  _Bloc() {
    this.count$ = hydrated("count", BehaviorSubject<int>());
  }

  dispose() {
    count$.close();
  }
}

StreamController<int> hydrated(
  String key,
  StreamController<int> controller, {
  int seedValue,
}) {
  hydrate() async {
    final prefs = await SharedPreferences.getInstance();
    final val = prefs.getInt(key);
    if (val != null && val != seedValue) {
      controller.add(val);
    }
  }

  persist(int val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, val);
  }

  hydrate();
  controller.stream.listen(persist);

  return controller;
}
