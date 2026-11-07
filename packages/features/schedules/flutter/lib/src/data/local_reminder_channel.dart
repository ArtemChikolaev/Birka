import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:l10n/l10n.dart';
import 'package:schedules_common/schedules_common.dart';
import 'package:timezone/data/latest_all.dart' as zones;
import 'package:timezone/timezone.dart' as tz;

/// The notifications of the phone, through `flutter_local_notifications`
/// (ADR 0025): the phone keeps the reminders and shows each on time, with
/// Birka closed, until the app is deleted.
final class LocalReminderChannel implements ReminderChannel {
  /// Creates the channel on [plugin], the one of the app by default.
  LocalReminderChannel([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  final _opened = StreamController<ReminderTap>.broadcast();
  Future<void>? _ready;
  ReminderTap? _launched;
  bool _refused = false;

  /// The channel of Android that the reminders come in.
  static const _channel = 'payments';

  Future<void> _start() => _ready ??= _setUp();

  Future<void> _setUp() async {
    zones.initializeTimeZones();
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } on Exception {
      // An unknown zone keeps UTC: reminders come hours off rather than not.
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_notification'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null) _opened.add(ReminderTap.parse(payload));
      },
    );
    final launch = await _plugin.getNotificationAppLaunchDetails();
    final payload = launch?.notificationResponse?.payload;
    if ((launch?.didNotificationLaunchApp ?? false) && payload != null) {
      _launched = ReminderTap.parse(payload);
    }
  }

  @override
  Future<ReminderAccess> access() async {
    await _start();
    final enabled = switch (defaultTargetPlatform) {
      TargetPlatform.iOS =>
        (await _plugin
                .resolvePlatformSpecificImplementation<
                  IOSFlutterLocalNotificationsPlugin
                >()
                ?.checkPermissions())
            ?.isEnabled,
      TargetPlatform.android =>
        await _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.areNotificationsEnabled(),
      _ => null,
    };
    if (enabled ?? false) return ReminderAccess.granted;
    // The phone does not tell a question never asked from a refusal.
    return _refused ? ReminderAccess.denied : ReminderAccess.unknown;
  }

  @override
  Future<ReminderAccess> requestAccess() async {
    await _start();
    final granted = switch (defaultTargetPlatform) {
      TargetPlatform.iOS =>
        await _plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, sound: true),
      TargetPlatform.android =>
        await _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.requestNotificationsPermission(),
      _ => null,
    };
    _refused = !(granted ?? false);
    return _refused ? ReminderAccess.denied : ReminderAccess.granted;
  }

  @override
  Future<void> show(List<ReminderNote> notes) async {
    await _start();
    // The reminders that came stay in the notification centre.
    await _plugin.cancelAllPendingNotifications();
    final now = tz.TZDateTime.now(tz.local);
    var id = 0;
    for (final note in notes) {
      final at = tz.TZDateTime(
        tz.local,
        note.day.year,
        note.day.month,
        note.day.day,
        note.minutes ~/ 60,
        note.minutes % 60,
      );
      if (!at.isAfter(now)) continue;
      await _plugin.zonedSchedule(
        id: ++id,
        scheduledDate: at,
        title: note.title,
        body: note.body,
        payload: note.tap.payload,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channel,
            t.schedules.remindChannel,
            channelDescription: t.schedules.remindChannelNote,
            importance: Importance.high,
            priority: Priority.high,
            styleInformation: BigTextStyleInformation(note.body),
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        // Without exact alarms Android may show it some minutes later.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  @override
  Stream<ReminderTap> get opened => Stream.multi((controller) {
    unawaited(
      _start().then((_) {
        final launched = _launched;
        _launched = null;
        if (launched != null) controller.add(launched);
      }),
    );
    final subscription = _opened.stream.listen(controller.add);
    controller.onCancel = subscription.cancel;
  });
}
