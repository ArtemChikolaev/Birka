/// The strings of Birka in every language and the formatting of amounts for
/// people (ADR 0010).
///
/// A host picks the language with `LocaleSettings`, and everything else reads
/// the strings of that language through `t`.
library;

export 'src/account_line.dart';
export 'src/format_money.dart';
export 'src/generated/strings.g.dart';
