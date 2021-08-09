import 'package:rxdart/rxdart.dart';

class SubjectValueWrapper<T> {
  final T? value;
  final ErrorAndStackTrace? errorAndStackTrace;

  SubjectValueWrapper({
    this.value,
    this.errorAndStackTrace,
  });
}
