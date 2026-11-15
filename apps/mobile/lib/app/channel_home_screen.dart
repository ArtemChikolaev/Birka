import 'dart:async';

import 'package:flutter/services.dart';
import 'package:home_screen/home_screen.dart';

/// The home screen of the phone over the channel `birka/widgets`, which the
/// app answers on iOS and Android (ADR 0031). The platform keeps the action
/// that launched Birka until the app asks for it, and sends the later ones
/// as they come. A platform without the channel, such as macOS in
/// development, leaves everything as it is.
final class ChannelHomeScreen implements HomeScreen {
  /// Creates the port on [channel], the one of the app by default.
  ChannelHomeScreen([MethodChannel? channel])
    : _channel = channel ?? const MethodChannel(name) {
    _channel.setMethodCallHandler(_handle);
  }

  /// The name of the channel that the app answers.
  static const name = 'birka/widgets';

  final MethodChannel _channel;
  final _actions = StreamController<HomeAction>.broadcast();
  final _pinned = StreamController<void>.broadcast();

  Future<Object?> _handle(MethodCall call) async {
    switch (call.method) {
      case 'open':
        if (HomeAction.named(call.arguments as String?) case final action?) {
          _actions.add(action);
        }
      case 'pinned':
        _pinned.add(null);
    }
    return null;
  }

  @override
  Future<void> show(WidgetSnapshot snapshot) =>
      _call<void>('show', snapshot.encode());

  @override
  Future<bool> canPin() async => await _call<bool>('canPin') ?? false;

  @override
  Future<bool> pin() async => await _call<bool>('pin') ?? false;

  @override
  Stream<HomeAction> get actions => Stream.multi((controller) {
    final subscription = _actions.stream.listen(controller.add);
    controller.onCancel = () => unawaited(subscription.cancel());
    // The action that launched Birka waits until someone listens.
    unawaited(
      _call<String>('takeAction').then((name) {
        final action = HomeAction.named(name);
        if (action != null && !controller.isClosed) controller.add(action);
      }),
    );
  });

  @override
  Stream<void> get pinned => _pinned.stream;

  Future<T?> _call<T>(String method, [Object? arguments]) async {
    try {
      return await _channel.invokeMethod<T>(method, arguments);
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }
}
