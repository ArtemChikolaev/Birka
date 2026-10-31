import 'dart:async';

/// What [combine] makes of the latest values of [first] and [second], again
/// after each new value, once both have given one.
Stream<R> combineLatest<A, B, R>(
  Stream<A> first,
  Stream<B> second,
  R Function(A, B) combine,
) {
  late final StreamController<R> controller;
  late final StreamSubscription<A> firstSubscription;
  late final StreamSubscription<B> secondSubscription;
  late A latestFirst;
  late B latestSecond;
  var hasFirst = false;
  var hasSecond = false;

  void update() {
    if (!hasFirst || !hasSecond) return;
    try {
      controller.add(combine(latestFirst, latestSecond));
    } on Object catch (error, stackTrace) {
      controller.addError(error, stackTrace);
    }
  }

  controller = StreamController<R>(
    onListen: () {
      firstSubscription = first.listen((value) {
        latestFirst = value;
        hasFirst = true;
        update();
      }, onError: controller.addError);
      secondSubscription = second.listen((value) {
        latestSecond = value;
        hasSecond = true;
        update();
      }, onError: controller.addError);
    },
    onCancel: () =>
        Future.wait([firstSubscription.cancel(), secondSubscription.cancel()]),
  );
  return controller.stream;
}
