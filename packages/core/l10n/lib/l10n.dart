/// The strings of Birka in every language and the formatting of amounts for
/// people (ADR 0010).
///
/// A host picks the language with `LocaleSettings`, and everything else reads
/// the strings of that language through `t`.
library;

export 'src/account_line.dart';
export 'src/chart_period_labels.dart';
export 'src/day_labels.dart';
export 'src/format_money.dart';
export 'src/generated/strings.g.dart';
export 'src/help_questions.dart';
export 'src/search_key.dart';
export 'src/typed_amount.dart';
