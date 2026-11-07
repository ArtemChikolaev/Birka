import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:notifications_common/src/domain/notifications_repository.dart';

/// How many notices are new, for the bell of the overview (ADR 0026). It
/// stays at nought while the ledger cannot say.
final class NotificationsSummaryCubit extends Cubit<int> {
  /// Creates the count on [repository].
  NotificationsSummaryCubit(NotificationsRepository repository) : super(0) {
    _subscription = repository.watchNew().listen(
      (count) {
        if (!isClosed) emit(count);
      },
      onError: (Object _) {},
    );
  }

  late final StreamSubscription<int> _subscription;

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
