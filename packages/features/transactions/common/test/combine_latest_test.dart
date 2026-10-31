import 'dart:async';

import 'package:test/test.dart';
import 'package:transactions_common/src/data/combine_latest.dart';

void main() {
  late StreamController<int> first;
  late StreamController<String> second;

  setUp(() {
    first = StreamController<int>();
    second = StreamController<String>();
  });

  Stream<String> combined() =>
      combineLatest(first.stream, second.stream, (a, b) => '$a$b');

  test('waits for both, then goes on with each new value', () async {
    final seen = <String>[];
    final subscription = combined().listen(seen.add);
    addTearDown(subscription.cancel);

    first.add(1);
    await pumpEventQueue();
    expect(seen, isEmpty);

    second.add('a');
    await pumpEventQueue();
    expect(seen, ['1a']);

    first.add(2);
    await pumpEventQueue();
    second.add('b');
    await pumpEventQueue();
    expect(seen, ['1a', '2a', '2b']);
  });

  test('a null counts as a value', () async {
    final nullable = StreamController<int?>();
    final seen = <String>[];
    final subscription = combineLatest(
      nullable.stream,
      second.stream,
      (a, b) => '$a$b',
    ).listen(seen.add);
    addTearDown(subscription.cancel);

    nullable.add(null);
    second.add('a');
    await pumpEventQueue();

    expect(seen, ['nulla']);
  });

  test('passes an error on', () async {
    final errors = <Object>[];
    final subscription = combined().listen((_) {}, onError: errors.add);
    addTearDown(subscription.cancel);

    second.addError('disk');
    await pumpEventQueue();

    expect(errors, ['disk']);
  });

  test('turns a failure of the combination into an error', () async {
    final errors = <Object>[];
    final subscription = combineLatest<int, String, String>(
      first.stream,
      second.stream,
      (_, _) => throw StateError('broken'),
    ).listen((_) {}, onError: errors.add);
    addTearDown(subscription.cancel);

    first.add(1);
    second.add('a');
    await pumpEventQueue();

    expect(errors.single, isA<StateError>());
  });

  test('lets both go when nobody listens any more', () async {
    await expectLater(
      combineLatest(
        Stream.value(1),
        Stream.value('a'),
        (a, b) => '$a$b',
      ).first,
      completion('1a'),
    );

    final subscription = combined().listen((_) {});
    expect(first.hasListener, isTrue);
    expect(second.hasListener, isTrue);

    await subscription.cancel();

    expect(first.hasListener, isFalse);
    expect(second.hasListener, isFalse);
  });
}
