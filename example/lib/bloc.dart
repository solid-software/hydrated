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
  final count$ = BehaviorSubject<int>(seedValue: 0);

  _Bloc() {
    hydrate();
    this.count$.listen(persist);
  }

  persist(int val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt("count", val);
  }

  hydrate() async {
    final prefs = await SharedPreferences.getInstance();
    final val = prefs.getInt("count");
    if (val != null) {
      this.count$.add(val);
    }
  }

  dispose() {
    count$.close();
  }
}
