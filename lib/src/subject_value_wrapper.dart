import 'package:rxdart/rxdart.dart';

class SubjectValueWrapper<T> {
  SubjectValueWrapper({
    this.value,
    this.errorAndStackTrace,
  });

  final T? value;
  final ErrorAndStackTrace? errorAndStackTrace;
}
