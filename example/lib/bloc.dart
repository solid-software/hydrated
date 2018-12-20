import 'package:flutter/widgets.dart';
import "hydrated.dart";

class AppBloc extends InheritedWidget {
  final _bloc = _Bloc();

  AppBloc({Key key, Widget child}) : super(key: key, child: child);

  static _Bloc of(BuildContext context) =>
      (context.inheritFromWidgetOfExactType(AppBloc) as AppBloc)._bloc;

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) => true;
}

class _Bloc {
  final count$ = HydratedSubject<int>("count3", seedValue: 0);

  _Bloc() {
    this.count$.hydrate();
  }

  dispose() {
    count$.close();
  }
}
