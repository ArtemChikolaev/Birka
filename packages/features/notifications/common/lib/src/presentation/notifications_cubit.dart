import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:ledger/ledger.dart';
import 'package:meta/meta.dart';
import 'package:notifications_common/src/domain/notifications_repository.dart';
import 'package:notifications_common/src/presentation/notice_labels.dart';

/// Whether the notices have come.
enum NotificationsStatus {
  /// They are on their way.
  loading,

  /// They are here.
  ready,

  /// The ledger could not give them.
  failed,
}

/// The read notices of one day of the history, the latest first.
@immutable
final class NoticeDay {
  /// Creates the day [day] with its [notices].
  const NoticeDay(this.day, this.notices);

  /// The day they came on, on the calendar of this device.
  final CivilDate day;

  /// What came that day.
  final List<Notice> notices;

  @override
  bool operator ==(Object other) =>
      other is NoticeDay &&
      other.day == day &&
      _sameList(other.notices, notices);

  @override
  int get hashCode => Object.hash(day, Object.hashAll(notices));
}

/// The feed of the notices of this device (ADR 0026): the new ones on top,
/// the history below by days, and the source the person narrowed it to.
@immutable
final class NotificationsState {
  /// Creates the state of [today].
  const NotificationsState({
    required this.today,
    this.status = NotificationsStatus.loading,
    this.notices = const [],
    this.source,
  });

  /// Whether the notices have come.
  final NotificationsStatus status;

  /// Every notice, the latest first.
  final List<Notice> notices;

  /// The source the feed is narrowed to, or `null` for every one.
  final NoticeSource? source;

  /// Today on the calendar of this device.
  final CivilDate today;

  /// The sources to narrow the feed to, in the order of their chips, while
  /// the notices come from two or more.
  List<NoticeSource> get sources {
    final present = {for (final notice in notices) notice.source};
    if (present.length < 2) return const [];
    return [
      for (final source in NoticeSource.values)
        if (present.contains(source)) source,
    ];
  }

  /// How many new notices [source] has, or every source without it.
  int newOf(NoticeSource? source) => notices
      .where((it) => it.isNew && (source == null || it.source == source))
      .length;

  bool _shows(Notice notice) => source == null || notice.source == source;

  /// The new notices the feed shows, the latest first.
  List<Notice> get fresh => [
    for (final notice in notices)
      if (notice.isNew && _shows(notice)) notice,
  ];

  /// The read notices the feed shows, by the day they came, the latest first.
  List<NoticeDay> get days {
    final days = <NoticeDay>[];
    for (final notice in notices) {
      if (notice.isNew || !_shows(notice)) continue;
      final day = CivilDate.of(notice.at.toLocal());
      if (days.isNotEmpty && days.last.day == day) {
        days.last.notices.add(notice);
      } else {
        days.add(NoticeDay(day, [notice]));
      }
    }
    return days;
  }

  /// Whether nothing has come in the 90 days the device keeps.
  bool get isEmpty => status == NotificationsStatus.ready && notices.isEmpty;

  /// Where a tap on [notice] leads today.
  ({NoticePlace place, String? id})? placeOf(Notice notice) =>
      noticePlace(notice, today: today);

  /// The same state with the given fields changed; [source] takes a function
  /// so that it can become `null`.
  NotificationsState copyWith({
    NotificationsStatus? status,
    List<Notice>? notices,
    NoticeSource? Function()? source,
    CivilDate? today,
  }) => NotificationsState(
    status: status ?? this.status,
    notices: notices ?? this.notices,
    source: source == null ? this.source : source(),
    today: today ?? this.today,
  );

  @override
  bool operator ==(Object other) =>
      other is NotificationsState &&
      other.status == status &&
      other.source == source &&
      other.today == today &&
      _sameList(other.notices, notices);

  @override
  int get hashCode =>
      Object.hash(status, source, today, Object.hashAll(notices));
}

bool _sameList<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Shows the notices of this device and marks them read (ADR 0026).
final class NotificationsCubit extends Cubit<NotificationsState> {
  /// Creates the feed on [_repository].
  NotificationsCubit(this._repository)
    : super(NotificationsState(today: CivilDate.of(_repository.now()))) {
    _subscription = _repository.watchNotices().listen(
      (notices) {
        if (isClosed) return;
        final next = state.copyWith(
          status: NotificationsStatus.ready,
          notices: notices,
        );
        // A source with no notices left takes its chip away.
        emit(
          next.sources.contains(next.source)
              ? next
              : next.copyWith(source: () => null),
        );
      },
      onError: (Object _) {
        if (!isClosed) emit(state.copyWith(status: NotificationsStatus.failed));
      },
    );
  }

  final NotificationsRepository _repository;
  late final StreamSubscription<List<Notice>> _subscription;

  /// Narrows the feed to [source], or shows every source with `null`.
  void pick(NoticeSource? source) => emit(state.copyWith(source: () => source));

  /// Marks every new notice read: they go into the history.
  Future<void> readAll() => _repository.read();

  /// Marks [notice] read and says where a tap on it leads.
  Future<({NoticePlace place, String? id})?> open(Notice notice) async {
    if (notice.isNew) await _repository.read([notice.id]);
    return state.placeOf(notice);
  }

  /// Takes in a new day, as after a night in the background.
  void calendarChecked() {
    final today = CivilDate.of(_repository.now());
    if (today != state.today && !isClosed) emit(state.copyWith(today: today));
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
