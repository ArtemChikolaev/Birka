import 'package:birka_web/app/data_island.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:transactions_common/transactions_common.dart';
import 'package:transactions_jaspr/transactions_jaspr.dart';

/// The card of an operation and the forms on it, for an island that shows them
/// behind its fragment.
mixin OperationViews<T extends StatefulComponent> on DataIslandState<T> {
  static const _edit = 'edit-';
  static const _repeat = 'repeat-';

  /// The address of the page, such as `operations/`.
  String get address;

  /// The operation that [view] is about: `<id>`, `edit-<id>` or
  /// `repeat-<id>`.
  String operationOf(String view) {
    for (final start in const [_edit, _repeat]) {
      if (view.startsWith(start)) return view.substring(start.length);
    }
    return view;
  }

  /// The card of an operation, `<id>`, or the form on it, `edit-<id>` and
  /// `repeat-<id>`. The card closes to [parent], and the fragments of the views
  /// start with it. Beside a list the card [closes] with a cross.
  Component operationView(
    String view, {
    String parent = '',
    bool closes = false,
  }) {
    final start = parent.isEmpty ? '' : '$parent/';
    if (view.startsWith(_edit)) {
      final id = view.substring(_edit.length);
      return quickAdd(QuickAddSource.edit(id), () => closeForm('$start$id'));
    }
    if (view.startsWith(_repeat)) {
      final id = view.substring(_repeat.length);
      return quickAdd(QuickAddSource.repeat(id), () => closeForm('$start$id'));
    }
    return BlocProvider<OperationCubit>(
      key: ValueKey(fragment),
      create: (_) => getIt(param1: view),
      child: OperationPage(
        onClose: () => closeForm(parent),
        editHref: '$address#$start$_edit$view',
        repeatHref: '$address#$start$_repeat$view',
        closes: closes,
      ),
    );
  }

  /// The form of an operation: a new one, or one made from [source].
  Component quickAdd(QuickAddSource? source, VoidCallback onClose) {
    return BlocProvider<QuickAddCubit>(
      key: ValueKey(fragment),
      create: (_) => getIt(param1: source),
      child: QuickAddPage(
        onClose: onClose,
        addAccountHref: 'accounts/#new',
        addCategoriesHref: 'categories/',
      ),
    );
  }
}
