import 'package:debts_common/debts_common.dart';
import 'package:flutter/services.dart';

/// The people of the debts on the phone (ADR 0030), through the channel that
/// the app answers on iOS and Android: the window of the contacts, an SMS and
/// the window of sharing.
final class ChannelPeoplePhone implements PeoplePhone {
  /// Creates the port on [channel], the one of the app by default.
  ChannelPeoplePhone([MethodChannel? channel])
    : _channel = channel ?? const MethodChannel(name);

  /// The name of the channel that the app answers.
  static const name = 'birka/people';

  final MethodChannel _channel;

  @override
  Future<PickedContact?> pickContact() async {
    final picked = await _channel.invokeMapMethod<String, Object?>(
      'pickContact',
    );
    if (picked == null) return null;
    final numbers = picked['numbers'];
    return PickedContact(
      name: _text(picked['name']),
      givenName: _text(picked['givenName']),
      numbers: [
        if (numbers is List<Object?>)
          for (final number in numbers)
            if (number is Map<Object?, Object?>)
              ContactNumber(
                label: _text(number['label']),
                number: _text(number['number']),
              ),
      ],
    );
  }

  @override
  Future<void> sendSms(String number, String text) =>
      _channel.invokeMethod<void>('sendSms', {'number': number, 'text': text});

  @override
  Future<void> share(String text) =>
      _channel.invokeMethod<void>('share', {'text': text});

  static String _text(Object? value) => value is String ? value : '';
}
