import 'package:bloc/bloc.dart';

/// Whether the amounts on the screen are hidden.
///
/// It lives in the host until the settings feature takes it over (ADR 0006).
class HideAmountsCubit extends Cubit<bool> {
  /// Creates the cubit with the amounts shown.
  HideAmountsCubit() : super(false);

  /// Hides the amounts, or shows them again.
  void toggle() => emit(!state);
}
