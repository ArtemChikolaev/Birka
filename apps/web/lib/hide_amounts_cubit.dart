import 'package:bloc/bloc.dart';

/// Whether the amount of the preview on the first page is hidden.
class HideAmountsCubit extends Cubit<bool> {
  /// Creates the cubit with the amounts shown.
  HideAmountsCubit() : super(false);

  /// Hides the amounts, or shows them again.
  void toggle() => emit(!state);
}
