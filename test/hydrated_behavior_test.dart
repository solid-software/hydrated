// ignore_for_file: close_sinks
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated/hydrated.dart';
import 'package:rxdart/rxdart.dart';

class StubKeyValueStore implements KeyValueStore {
  @override
  Future<T?> get<T>(String key) {
    return Future<T>.value(null);
  }

  @override
  Future<void> put<T>(String key, T? value) async {}
}

void main() {
  final throwsValueStreamError = throwsA(isA<ValueStreamError>());

  late StubKeyValueStore mockKeyValueStore;
  setUp(() {
    mockKeyValueStore = StubKeyValueStore();
  });
  group('HydratedSubject', () {
    test('emits the most recently emitted item to every subscriber', () async {
      final unseeded =
              HydratedSubject<int?>('key', keyValueStore: mockKeyValueStore),
          seeded = HydratedSubject<int?>('key',
              seedValue: 0, keyValueStore: mockKeyValueStore);

      unseeded.add(1);
      unseeded.add(2);
      unseeded.add(3);

      seeded.add(1);
      seeded.add(2);
      seeded.add(3);

      await expectLater(unseeded.stream, emits(3));
      await expectLater(unseeded.stream, emits(3));
      await expectLater(unseeded.stream, emits(3));

      await expectLater(seeded.stream, emits(3));
      await expectLater(seeded.stream, emits(3));
      await expectLater(seeded.stream, emits(3));
    });

    test('emits the most recently emitted null item to every subscriber',
        () async {
      final unseeded =
              HydratedSubject<int?>('key', keyValueStore: mockKeyValueStore),
          seeded = HydratedSubject<int?>('key',
              seedValue: 0, keyValueStore: mockKeyValueStore);

      unseeded.add(1);
      unseeded.add(2);
      unseeded.add(null);

      seeded.add(1);
      seeded.add(2);
      seeded.add(null);

      await expectLater(unseeded.stream, emits(isNull));
      await expectLater(unseeded.stream, emits(isNull));
      await expectLater(unseeded.stream, emits(isNull));

      await expectLater(seeded.stream, emits(isNull));
      await expectLater(seeded.stream, emits(isNull));
      await expectLater(seeded.stream, emits(isNull));
    });

    test(
        'emits the most recently emitted item to every subscriber that subscribe to the subject directly',
        () async {
      final unseeded =
              HydratedSubject<int?>('key', keyValueStore: mockKeyValueStore),
          seeded = HydratedSubject<int?>('key',
              seedValue: 0, keyValueStore: mockKeyValueStore);

      unseeded.add(1);
      unseeded.add(2);
      unseeded.add(3);

      seeded.add(1);
      seeded.add(2);
      seeded.add(3);

      await expectLater(unseeded, emits(3));
      await expectLater(unseeded, emits(3));
      await expectLater(unseeded, emits(3));

      await expectLater(seeded, emits(3));
      await expectLater(seeded, emits(3));
      await expectLater(seeded, emits(3));
    });

    test('emits errors to every subscriber', () async {
      final unseeded =
              HydratedSubject<int?>('key', keyValueStore: mockKeyValueStore),
          seeded = HydratedSubject<int?>('key',
              seedValue: 0, keyValueStore: mockKeyValueStore);

      unseeded.add(1);
      unseeded.add(2);
      unseeded.add(3);
      unseeded.addError(Exception('oh noes!'));

      seeded.add(1);
      seeded.add(2);
      seeded.add(3);
      seeded.addError(Exception('oh noes!'));

      await expectLater(unseeded.stream, emitsError(isException));
      await expectLater(unseeded.stream, emitsError(isException));
      await expectLater(unseeded.stream, emitsError(isException));

      await expectLater(seeded.stream, emitsError(isException));
      await expectLater(seeded.stream, emitsError(isException));
      await expectLater(seeded.stream, emitsError(isException));
    });

    test('emits event after error to every subscriber', () async {
      final unseeded =
              HydratedSubject<int?>('key', keyValueStore: mockKeyValueStore),
          seeded = HydratedSubject<int?>('key',
              seedValue: 0, keyValueStore: mockKeyValueStore);

      unseeded.add(1);
      unseeded.add(2);
      unseeded.addError(Exception('oh noes!'));
      unseeded.add(3);

      seeded.add(1);
      seeded.add(2);
      seeded.addError(Exception('oh noes!'));
      seeded.add(3);

      await expectLater(unseeded.stream, emits(3));
      await expectLater(unseeded.stream, emits(3));
      await expectLater(unseeded.stream, emits(3));

      await expectLater(seeded.stream, emits(3));
      await expectLater(seeded.stream, emits(3));
      await expectLater(seeded.stream, emits(3));
    });

    test('emits errors to every subscriber', () async {
      final unseeded =
              HydratedSubject<int?>('key', keyValueStore: mockKeyValueStore),
          seeded = HydratedSubject<int?>('key',
              seedValue: 0, keyValueStore: mockKeyValueStore);
      final exception = Exception('oh noes!');

      unseeded.add(1);
      unseeded.add(2);
      unseeded.add(3);
      unseeded.addError(exception);

      seeded.add(1);
      seeded.add(2);
      seeded.add(3);
      seeded.addError(exception);

      expect(unseeded.value, 3);
      expect(unseeded.valueOrNull, 3);
      expect(unseeded.hasValue, true);

      expect(unseeded.error, exception);
      expect(unseeded.errorOrNull, exception);
      expect(unseeded.hasError, true);

      await expectLater(unseeded, emitsError(exception));
      await expectLater(unseeded, emitsError(exception));
      await expectLater(unseeded, emitsError(exception));

      expect(seeded.value, 3);
      expect(seeded.valueOrNull, 3);
      expect(seeded.hasValue, true);

      expect(seeded.error, exception);
      expect(seeded.errorOrNull, exception);
      expect(seeded.hasError, true);

      await expectLater(seeded, emitsError(exception));
      await expectLater(seeded, emitsError(exception));
      await expectLater(seeded, emitsError(exception));
    });

    test('can synchronously get the latest value', () {
      final unseeded =
              HydratedSubject<int?>('key', keyValueStore: mockKeyValueStore),
          seeded = HydratedSubject<int?>('key',
              seedValue: 0, keyValueStore: mockKeyValueStore);

      unseeded.add(1);
      unseeded.add(2);
      unseeded.add(3);

      seeded.add(1);
      seeded.add(2);
      seeded.add(3);

      expect(unseeded.value, 3);
      expect(unseeded.valueOrNull, 3);
      expect(unseeded.hasValue, true);

      expect(seeded.value, 3);
      expect(seeded.valueOrNull, 3);
      expect(seeded.hasValue, true);
    });

    test('can synchronously get the latest null value', () async {
      final unseeded =
              HydratedSubject<int?>('key', keyValueStore: mockKeyValueStore),
          seeded = HydratedSubject<int?>('key',
              seedValue: 0, keyValueStore: mockKeyValueStore);

      unseeded.add(1);
      unseeded.add(2);
      unseeded.add(null);

      seeded.add(1);
      seeded.add(2);
      seeded.add(null);

      expect(unseeded.value, isNull);
      expect(unseeded.valueOrNull, isNull);
      expect(unseeded.hasValue, true);

      expect(seeded.value, isNull);
      expect(seeded.valueOrNull, isNull);
      expect(seeded.hasValue, true);
    });

    test('emits the seed item if no new items have been emitted', () async {
      final subject = HydratedSubject<int?>('key',
          seedValue: 1, keyValueStore: mockKeyValueStore);

      await expectLater(subject.stream, emits(1));
      await expectLater(subject.stream, emits(1));
      await expectLater(subject.stream, emits(1));
    });

    test('can synchronously get the initial value', () {
      final subject = HydratedSubject<int?>('key',
          seedValue: 1, keyValueStore: mockKeyValueStore);

      expect(subject.value, 1);
      expect(subject.valueOrNull, 1);
      expect(subject.hasValue, true);
    });

    test('cannot synchronously get the initial null value', () {
      final subject = HydratedSubject<int?>('key',
          seedValue: null, keyValueStore: mockKeyValueStore);

      expect(subject.hasValue, false);
      expect(subject.valueOrNull, null);
    });

    test('initial value is null when no value has been emitted', () {
      final subject =
          HydratedSubject<int?>('key', keyValueStore: mockKeyValueStore);

      expect(() => subject.value, throwsValueStreamError);
      expect(subject.valueOrNull, null);
      expect(subject.hasValue, false);
    });

    test('emits done event to listeners when the subject is closed', () async {
      final unseeded =
              HydratedSubject<int?>('key', keyValueStore: mockKeyValueStore),
          seeded = HydratedSubject<int?>('key',
              seedValue: 0, keyValueStore: mockKeyValueStore);

      await expectLater(unseeded.isClosed, isFalse);
      await expectLater(seeded.isClosed, isFalse);

      unseeded.add(1);
      scheduleMicrotask(() => unseeded.close());

      seeded.add(1);
      scheduleMicrotask(() => seeded.close());

      await expectLater(unseeded.stream, emitsInOrder(<dynamic>[1, emitsDone]));
      await expectLater(unseeded.isClosed, isTrue);

      await expectLater(seeded.stream, emitsInOrder(<dynamic>[1, emitsDone]));
      await expectLater(seeded.isClosed, isTrue);
    });

    test('emits error events to subscribers', () async {
      final unseeded =
              HydratedSubject<int?>('key', keyValueStore: mockKeyValueStore),
          seeded = HydratedSubject<int?>('key',
              seedValue: 0, keyValueStore: mockKeyValueStore);

      scheduleMicrotask(() => unseeded.addError(Exception()));
      scheduleMicrotask(() => seeded.addError(Exception()));

      await expectLater(unseeded.stream, emitsError(isException));
      await expectLater(seeded.stream, emitsError(isException));
    });

    test('replays the previously emitted items from addStream', () async {
      final unseeded =
              HydratedSubject<int?>('key', keyValueStore: mockKeyValueStore),
          seeded = HydratedSubject<int?>('key',
              seedValue: 0, keyValueStore: mockKeyValueStore);

      await unseeded.addStream(Stream.fromIterable(const [1, 2, 3]));
      await seeded.addStream(Stream.fromIterable(const [1, 2, 3]));

      await expectLater(unseeded.stream, emits(3));
      await expectLater(unseeded.stream, emits(3));
      await expectLater(unseeded.stream, emits(3));

      await expectLater(seeded.stream, emits(3));
      await expectLater(seeded.stream, emits(3));
      await expectLater(seeded.stream, emits(3));
    });

    test('replays the previously emitted errors from addStream', () async {
      final unseeded =
              HydratedSubject<int?>('key', keyValueStore: mockKeyValueStore),
          seeded = HydratedSubject<int?>('key',
              seedValue: 0, keyValueStore: mockKeyValueStore);

      await unseeded.addStream(Stream<int?>.error('error'),
          cancelOnError: false);
      await seeded.addStream(Stream<int?>.error('error'), cancelOnError: false);

      await expectLater(unseeded.stream, emitsError('error'));
      await expectLater(unseeded.stream, emitsError('error'));
    });

    test('allows items to be added once addStream is complete', () async {
      final subject =
          HydratedSubject<int?>('key', keyValueStore: mockKeyValueStore);

      await subject.addStream(Stream.fromIterable(const [1, 2]));
      subject.add(3);

      await expectLater(subject.stream, emits(3));
    });

    test('allows items to be added once addStream completes with an error',
        () async {
      final subject =
          HydratedSubject<void>('key', keyValueStore: mockKeyValueStore);

      subject
          .addStream(Stream<void>.error(Exception()), cancelOnError: true)
          .whenComplete(() => subject.add(1));

      await expectLater(subject.stream,
          emitsInOrder(<StreamMatcher>[emitsError(isException), emits(1)]));
    });

    test('does not allow events to be added when addStream is active',
        () async {
      final subject =
          HydratedSubject<int?>('key', keyValueStore: mockKeyValueStore);

      // Purposely don't wait for the future to complete, then try to add items

      subject.addStream(Stream.fromIterable(const [1, 2, 3]));

      await expectLater(() => subject.add(1), throwsStateError);
    });

    test('does not allow errors to be added when addStream is active',
        () async {
      final subject =
          HydratedSubject<int?>('key', keyValueStore: mockKeyValueStore);

      // Purposely don't wait for the future to complete, then try to add items

      subject.addStream(Stream.fromIterable(const [1, 2, 3]));

      await expectLater(() => subject.addError(Error()), throwsStateError);
    });

    test('does not allow subject to be closed when addStream is active',
        () async {
      final subject =
          HydratedSubject<int?>('key', keyValueStore: mockKeyValueStore);

      // Purposely don't wait for the future to complete, then try to add items

      subject.addStream(Stream.fromIterable(const [1, 2, 3]));

      await expectLater(() => subject.close(), throwsStateError);
    });

    test(
        'does not allow addStream to add items when previous addStream is active',
        () async {
      final subject =
          HydratedSubject<int?>('key', keyValueStore: mockKeyValueStore);

      // Purposely don't wait for the future to complete, then try to add items

      subject.addStream(Stream.fromIterable(const [1, 2, 3]));

      await expectLater(() => subject.addStream(Stream.fromIterable(const [1])),
          throwsStateError);
    });

    test('returns onListen callback set in constructor', () async {
      final testOnListen = () {};

      final subject = HydratedSubject<void>('key',
          onListen: testOnListen, keyValueStore: mockKeyValueStore);

      await expectLater(subject.onListen, testOnListen);
    });

    test('sets onListen callback', () async {
      final testOnListen = () {};

      final subject =
          HydratedSubject<void>('key', keyValueStore: mockKeyValueStore);

      await expectLater(subject.onListen, isNull);

      subject.onListen = testOnListen;

      await expectLater(subject.onListen, testOnListen);
    });

    test('returns onCancel callback set in constructor', () async {
      final onCancel = () => Future<void>.value(null);

      final subject = HydratedSubject<void>('key',
          onCancel: onCancel, keyValueStore: mockKeyValueStore);

      await expectLater(subject.onCancel, onCancel);
    });

    test('sets onCancel callback', () async {
      final testOnCancel = () {};

      final subject =
          HydratedSubject<void>('key', keyValueStore: mockKeyValueStore);

      await expectLater(subject.onCancel, isNull);

      subject.onCancel = testOnCancel;

      await expectLater(subject.onCancel, testOnCancel);
    });

    test('reports if a listener is present', () async {
      final subject =
          HydratedSubject<int?>('key', keyValueStore: mockKeyValueStore);

      await expectLater(subject.hasListener, isFalse);

      subject.stream.listen(null);

      await expectLater(subject.hasListener, isTrue);
    });

    test('onPause unsupported', () {
      final subject =
          HydratedSubject<int?>('key', keyValueStore: mockKeyValueStore);

      expect(subject.isPaused, isFalse);
      expect(() => subject.onPause, throwsUnsupportedError);
      expect(() => subject.onPause = () {}, throwsUnsupportedError);
    });

    test('onResume unsupported', () {
      final subject =
          HydratedSubject<int?>('key', keyValueStore: mockKeyValueStore);

      expect(() => subject.onResume, throwsUnsupportedError);
      expect(() => subject.onResume = () {}, throwsUnsupportedError);
    });

    test('returns controller sink', () async {
      final subject =
          HydratedSubject<int?>('key', keyValueStore: mockKeyValueStore);

      await expectLater(subject.sink, TypeMatcher<EventSink<int?>>());
    });

    test('correctly closes done Future', () async {
      final subject =
          HydratedSubject<void>('key', keyValueStore: mockKeyValueStore);

      scheduleMicrotask(() => subject.close());

      await expectLater(subject.done, completes);
    });

    test('can be listened to multiple times', () async {
      final subject = HydratedSubject('key',
          seedValue: 1, keyValueStore: mockKeyValueStore);
      final stream = subject.stream;

      await expectLater(stream, emits(1));
      await expectLater(stream, emits(1));
    });

    test('always returns the same stream', () async {
      final subject =
          HydratedSubject<int?>('key', keyValueStore: mockKeyValueStore);

      await expectLater(subject.stream, equals(subject.stream));
    });

    test('adding to sink has same behavior as adding to Subject itself',
        () async {
      final subject =
          HydratedSubject<int?>('key', keyValueStore: mockKeyValueStore);

      subject.sink.add(1);

      expect(subject.value, 1);

      subject.sink.add(2);
      subject.sink.add(3);

      await expectLater(subject.stream, emits(3));
      await expectLater(subject.stream, emits(3));
      await expectLater(subject.stream, emits(3));
    });

    test('setter `value=` has same behavior as adding to Subject', () async {
      final subject = HydratedSubject<int?>('key',
          seedValue: 0, keyValueStore: mockKeyValueStore);

      subject.value = 1;

      // await pumpEventQueue();

      expect(subject.value, 1);

      subject.value = 2;
      subject.value = 3;
      // await pumpEventQueue();

      await expectLater(subject.stream, emits(3));
      await expectLater(subject.stream, emits(3));
      await expectLater(subject.stream, emits(3));
    });

    test('is always treated as a broadcast Stream', () async {
      final subject =
          HydratedSubject<int?>('key', keyValueStore: mockKeyValueStore);
      final stream = subject.asyncMap((event) => Future.value(event));

      expect(subject.isBroadcast, isTrue);
      expect(stream.isBroadcast, isTrue);
    });

    test('hasValue returns false for an empty subject', () {
      final subject =
          HydratedSubject<int?>('key', keyValueStore: mockKeyValueStore);

      expect(subject.hasValue, isFalse);
    });

    test('hasValue returns true for a seeded subject with non-null seed', () {
      final subject = HydratedSubject<int?>('key',
          seedValue: 1, keyValueStore: mockKeyValueStore);

      expect(subject.hasValue, isTrue);
    });

    test('hasValue returns false for a seeded subject with null seed', () {
      final subject = HydratedSubject<int?>('key',
          seedValue: null, keyValueStore: mockKeyValueStore);

      expect(subject.hasValue, isFalse);
    });

    test('hasValue returns true for an unseeded subject after an emission', () {
      final subject =
          HydratedSubject<int?>('key', keyValueStore: mockKeyValueStore);

      subject.add(1);

      expect(subject.hasValue, isTrue);
    });

    test('hasError returns false for an empty subject', () {
      final subject =
          HydratedSubject<int?>('key', keyValueStore: mockKeyValueStore);

      expect(subject.hasError, isFalse);
    });

    test('hasError returns false for a seeded subject with non-null seed', () {
      final subject = HydratedSubject<int?>('key',
          seedValue: 1, keyValueStore: mockKeyValueStore);

      expect(subject.hasError, isFalse);
    });

    test('hasError returns false for a seeded subject with null seed', () {
      final subject = HydratedSubject<int?>('key',
          seedValue: null, keyValueStore: mockKeyValueStore);

      expect(subject.hasError, isFalse);
    });

    test('hasError returns false for an unseeded subject after an emission',
        () {
      final subject =
          HydratedSubject<int?>('key', keyValueStore: mockKeyValueStore);

      subject.add(1);

      expect(subject.hasError, isFalse);
    });

    test('hasError returns true for an unseeded subject after addError', () {
      final subject =
          HydratedSubject<int?>('key', keyValueStore: mockKeyValueStore);

      subject.add(1);
      subject.addError('error');

      expect(subject.hasError, isTrue);
    });

    test('hasError returns true for a seeded subject after addError', () {
      final subject = HydratedSubject<int?>('key',
          seedValue: 1, keyValueStore: mockKeyValueStore);

      subject.addError('error');

      expect(subject.hasError, isTrue);
    });

    test('error returns null for an empty subject', () {
      final subject =
          HydratedSubject<int?>('key', keyValueStore: mockKeyValueStore);

      expect(subject.hasError, isFalse);
      expect(subject.errorOrNull, isNull);
      expect(() => subject.error, throwsValueStreamError);
    });

    test('error returns null for a seeded subject with non-null seed', () {
      final subject = HydratedSubject<int?>('key',
          seedValue: 1, keyValueStore: mockKeyValueStore);

      expect(subject.hasError, isFalse);
      expect(subject.errorOrNull, isNull);
      expect(() => subject.error, throwsValueStreamError);
    });

    test('error returns null for a seeded subject with null seed', () {
      final subject = HydratedSubject<int?>('key',
          seedValue: null, keyValueStore: mockKeyValueStore);

      expect(subject.hasError, isFalse);
      expect(subject.errorOrNull, isNull);
      expect(() => subject.error, throwsValueStreamError);
    });

    test('can synchronously get the latest error', () async {
      final unseeded =
              HydratedSubject<int?>('key', keyValueStore: mockKeyValueStore),
          seeded = HydratedSubject<int?>('key',
              seedValue: 0, keyValueStore: mockKeyValueStore);

      unseeded.add(1);
      unseeded.add(2);
      unseeded.add(3);
      expect(unseeded.hasError, isFalse);
      expect(unseeded.errorOrNull, isNull);
      expect(() => unseeded.error, throwsValueStreamError);

      unseeded.addError(Exception('oh noes!'));
      expect(unseeded.hasError, isTrue);
      expect(unseeded.errorOrNull, isException);
      expect(unseeded.error, isException);

      seeded.add(1);
      seeded.add(2);
      seeded.add(3);
      expect(seeded.hasError, isFalse);
      expect(seeded.errorOrNull, isNull);
      expect(() => seeded.error, throwsValueStreamError);

      seeded.addError(Exception('oh noes!'));
      expect(seeded.hasError, isTrue);
      expect(seeded.errorOrNull, isException);
      expect(seeded.error, isException);
    });

    test('emits event after error to every subscriber', () async {
      final unseeded =
              HydratedSubject<int?>('key', keyValueStore: mockKeyValueStore),
          seeded = HydratedSubject<int?>('key',
              seedValue: 0, keyValueStore: mockKeyValueStore);

      unseeded.add(1);
      unseeded.add(2);
      unseeded.addError(Exception('oh noes!'));
      expect(unseeded.hasError, isTrue);
      expect(unseeded.errorOrNull, isException);
      expect(unseeded.error, isException);
      unseeded.add(3);
      expect(unseeded.hasError, isTrue);
      expect(unseeded.errorOrNull, isException);
      expect(unseeded.error, isException);

      seeded.add(1);
      seeded.add(2);
      seeded.addError(Exception('oh noes!'));
      expect(seeded.hasError, isTrue);
      expect(seeded.errorOrNull, isException);
      expect(seeded.error, isException);
      seeded.add(3);
      expect(seeded.hasError, isTrue);
      expect(seeded.errorOrNull, isException);
      expect(seeded.error, isException);
    });
    group('override built-in', () {
      test('where', () {
        {
          var hydratedSubject = HydratedSubject('key',
              seedValue: 1, keyValueStore: mockKeyValueStore);

          var stream = hydratedSubject.where((event) => event.isOdd);
          expect(stream, emitsInOrder(<int?>[1, 3]));

          hydratedSubject.add(2);
          hydratedSubject.add(3);
        }

        {
          var hydratedSubject =
              HydratedSubject<int?>('key', keyValueStore: mockKeyValueStore);

          var stream = hydratedSubject.where((event) => event?.isOdd ?? false);
          expect(stream, emitsInOrder(<int?>[1, 3]));

          hydratedSubject.add(1);
          hydratedSubject.add(2);
          hydratedSubject.add(3);
        }
      });

      test('map', () {
        {
          var hydratedSubject = HydratedSubject('key',
              seedValue: 1, keyValueStore: mockKeyValueStore);

          var mapped = hydratedSubject.map((event) => event + 1);
          expect(mapped, emitsInOrder(<int?>[2, 3]));

          hydratedSubject.add(2);
        }

        {
          var hydratedSubject =
              HydratedSubject<int?>('key', keyValueStore: mockKeyValueStore);

          var mapped = hydratedSubject.map((event) => (event ?? 0) + 1);
          expect(mapped, emitsInOrder(<int?>[2, 3]));

          hydratedSubject.add(1);
          hydratedSubject.add(2);
        }
      });

      test('asyncMap', () {
        {
          var hydratedSubject = HydratedSubject('key',
              seedValue: 1, keyValueStore: mockKeyValueStore);

          var mapped =
              hydratedSubject.asyncMap((event) => Future.value(event + 1));
          expect(mapped, emitsInOrder(<int?>[2, 3]));

          hydratedSubject.add(2);
        }

        {
          var hydratedSubject =
              HydratedSubject<int?>('key', keyValueStore: mockKeyValueStore);

          var mapped = hydratedSubject
              .asyncMap((event) => Future.value((event ?? 0) + 1));
          expect(mapped, emitsInOrder(<int?>[2, 3]));

          hydratedSubject.add(1);
          hydratedSubject.add(2);
        }
      });

      test('asyncExpand', () {
        {
          var hydratedSubject = HydratedSubject('key',
              seedValue: 1, keyValueStore: mockKeyValueStore);

          var stream =
              hydratedSubject.asyncExpand((event) => Stream.value(event + 1));
          expect(stream, emitsInOrder(<int?>[2, 3]));

          hydratedSubject.add(2);
        }

        {
          var hydratedSubject =
              HydratedSubject<int?>('key', keyValueStore: mockKeyValueStore);

          var stream =
              hydratedSubject.asyncExpand((event) => Stream.value(event! + 1));
          expect(stream, emitsInOrder(<int?>[2, 3]));

          hydratedSubject.add(1);
          hydratedSubject.add(2);
        }
      });

      test('handleError', () {
        {
          var hydratedSubject = HydratedSubject('key',
              seedValue: 1, keyValueStore: mockKeyValueStore);

          var stream = hydratedSubject.handleError(
            expectAsync1<void, dynamic>(
              (dynamic e) => expect(e, isException),
              count: 1,
            ),
          );

          expect(
            stream,
            emitsInOrder(<int?>[1, 2]),
          );

          hydratedSubject.addError(Exception());
          hydratedSubject.add(2);
        }

        {
          var hydratedSubject =
              HydratedSubject<int?>('key', keyValueStore: mockKeyValueStore);

          var stream = hydratedSubject.handleError(
            expectAsync1<void, dynamic>(
              (dynamic e) => expect(e, isException),
              count: 1,
            ),
          );

          expect(
            stream,
            emitsInOrder(<int?>[1, 2]),
          );

          hydratedSubject.add(1);
          hydratedSubject.addError(Exception());
          hydratedSubject.add(2);
        }
      });

      test('expand', () {
        {
          var hydratedSubject = HydratedSubject('key',
              seedValue: 1, keyValueStore: mockKeyValueStore);

          var stream = hydratedSubject.expand((event) => [event + 1]);
          expect(stream, emitsInOrder(<int?>[2, 3]));

          hydratedSubject.add(2);
        }

        {
          var hydratedSubject =
              HydratedSubject<int?>('key', keyValueStore: mockKeyValueStore);

          var stream = hydratedSubject.expand((event) => [event! + 1]);
          expect(stream, emitsInOrder(<int?>[2, 3]));

          hydratedSubject.add(1);
          hydratedSubject.add(2);
        }
      });

      test('transform', () {
        {
          var hydratedSubject = HydratedSubject('key',
              seedValue: 1, keyValueStore: mockKeyValueStore);

          var stream = hydratedSubject.transform(
              IntervalStreamTransformer(const Duration(milliseconds: 100)));
          expect(stream, emitsInOrder(<int?>[1, 2]));

          hydratedSubject.add(2);
        }

        {
          var hydratedSubject =
              HydratedSubject<int?>('key', keyValueStore: mockKeyValueStore);

          var stream = hydratedSubject.transform(
              IntervalStreamTransformer(const Duration(milliseconds: 100)));
          expect(stream, emitsInOrder(<int?>[1, 2]));

          hydratedSubject.add(1);
          hydratedSubject.add(2);
        }
      });

      test('cast', () {
        {
          var hydratedSubject = HydratedSubject<Object>('key',
              seedValue: 1, keyValueStore: mockKeyValueStore);

          var stream = hydratedSubject.cast<int?>();
          expect(stream, emitsInOrder(<int?>[1, 2]));

          hydratedSubject.add(2);
        }

        {
          var hydratedSubject =
              HydratedSubject<Object>('key', keyValueStore: mockKeyValueStore);

          var stream = hydratedSubject.cast<int?>();
          expect(stream, emitsInOrder(<int?>[1, 2]));

          hydratedSubject.add(1);
          hydratedSubject.add(2);
        }
      });

      test('take', () {
        {
          var hydratedSubject = HydratedSubject('key',
              seedValue: 1, keyValueStore: mockKeyValueStore);

          var stream = hydratedSubject.take(2);
          expect(stream, emitsInOrder(<int?>[1, 2]));

          hydratedSubject.add(2);
          hydratedSubject.add(3);
        }

        {
          var hydratedSubject =
              HydratedSubject<int?>('key', keyValueStore: mockKeyValueStore);

          var stream = hydratedSubject.take(2);
          expect(stream, emitsInOrder(<int?>[1, 2]));

          hydratedSubject.add(1);
          hydratedSubject.add(2);
          hydratedSubject.add(3);
        }
      });

      test('takeWhile', () {
        {
          var hydratedSubject = HydratedSubject('key',
              seedValue: 1, keyValueStore: mockKeyValueStore);

          var stream = hydratedSubject.takeWhile((element) => element <= 2);
          expect(stream, emitsInOrder(<int?>[1, 2]));

          hydratedSubject.add(2);
          hydratedSubject.add(3);
        }

        {
          var hydratedSubject =
              HydratedSubject<int?>('key', keyValueStore: mockKeyValueStore);

          var stream = hydratedSubject.takeWhile((element) => element! <= 2);
          expect(stream, emitsInOrder(<int?>[1, 2]));

          hydratedSubject.add(1);
          hydratedSubject.add(2);
          hydratedSubject.add(3);
        }
      });

      test('skip', () {
        {
          var hydratedSubject = HydratedSubject('key',
              seedValue: 1, keyValueStore: mockKeyValueStore);

          var stream = hydratedSubject.skip(2);
          expect(stream, emitsInOrder(<int?>[3, 4]));

          hydratedSubject.add(2);
          hydratedSubject.add(3);
          hydratedSubject.add(4);
        }

        {
          var hydratedSubject =
              HydratedSubject<int?>('key', keyValueStore: mockKeyValueStore);

          var stream = hydratedSubject.skip(2);
          expect(stream, emitsInOrder(<int?>[3, 4]));

          hydratedSubject.add(1);
          hydratedSubject.add(2);
          hydratedSubject.add(3);
          hydratedSubject.add(4);
        }
      });

      test('skipWhile', () {
        {
          var hydratedSubject = HydratedSubject('key',
              seedValue: 1, keyValueStore: mockKeyValueStore);

          var stream = hydratedSubject.skipWhile((element) => element < 3);
          expect(stream, emitsInOrder(<int?>[3, 4]));

          hydratedSubject.add(2);
          hydratedSubject.add(3);
          hydratedSubject.add(4);
        }

        {
          var hydratedSubject =
              HydratedSubject<int?>('key', keyValueStore: mockKeyValueStore);

          var stream = hydratedSubject.skipWhile((element) => element! < 3);
          expect(stream, emitsInOrder(<int?>[3, 4]));

          hydratedSubject.add(1);
          hydratedSubject.add(2);
          hydratedSubject.add(3);
          hydratedSubject.add(4);
        }
      });

      test('distinct', () {
        {
          var hydratedSubject = HydratedSubject('key',
              seedValue: 1, keyValueStore: mockKeyValueStore);

          var stream = hydratedSubject.distinct();
          expect(stream, emitsInOrder(<int?>[1, 2]));

          hydratedSubject.add(1);
          hydratedSubject.add(2);
          hydratedSubject.add(2);
        }

        {
          var hydratedSubject =
              HydratedSubject<int?>('key', keyValueStore: mockKeyValueStore);

          var stream = hydratedSubject.distinct();
          expect(stream, emitsInOrder(<int?>[1, 2]));

          hydratedSubject.add(1);
          hydratedSubject.add(1);
          hydratedSubject.add(2);
          hydratedSubject.add(2);
        }
      });

      test('timeout', () {
        {
          var hydratedSubject = HydratedSubject('key',
              seedValue: 1, keyValueStore: mockKeyValueStore);

          var stream = hydratedSubject
              .interval(const Duration(milliseconds: 100))
              .timeout(
                const Duration(milliseconds: 70),
                onTimeout: expectAsync1(
                  (EventSink<int?> sink) {},
                  count: 4,
                ),
              );

          expect(stream, emitsInOrder(<int?>[1, 2, 3, 4]));

          hydratedSubject.add(2);
          hydratedSubject.add(3);
          hydratedSubject.add(4);
        }

        {
          var hydratedSubject =
              HydratedSubject<int?>('key', keyValueStore: mockKeyValueStore);

          var stream = hydratedSubject
              .interval(const Duration(milliseconds: 100))
              .timeout(
                const Duration(milliseconds: 70),
                onTimeout: expectAsync1(
                  (EventSink<int?> sink) {},
                  count: 4,
                ),
              );

          expect(stream, emitsInOrder(<int?>[1, 2, 3, 4]));

          hydratedSubject.add(1);
          hydratedSubject.add(2);
          hydratedSubject.add(3);
          hydratedSubject.add(4);
        }
      });
    });
  });
}
