/// The screens of the transactions feature in Jaspr (ADR 0006).
///
/// They read their cubits from the context and take their links and callbacks
/// from the outside, so the host owns the addresses.
library;

export 'src/presentation/pages/operation_page.dart';
export 'src/presentation/pages/operations_page.dart';
export 'src/presentation/pages/quick_add_page.dart';
